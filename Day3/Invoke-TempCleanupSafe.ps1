<#
.SYNOPSIS
Safely cleans temp files on a Windows endpoint with dry run, logging, summary, and rollback support.

.DESCRIPTION
Cleanup mode:
- Finds temp files older than a configurable number of days.
- Skips locked files.
- Uses try/catch per file so one failure does not stop the run.
- Moves files to a quarantine folder (safe delete pattern) to support rollback.
- Writes a timestamped log and rollback manifest.

Rollback mode:
- Restores files moved in a previous cleanup run from a manifest CSV.

Designed for Windows PowerShell 5.1.
#>

[CmdletBinding(DefaultParameterSetName = 'Cleanup')]
param(
    # Cleanup mode: number of days old a file must be to qualify.
    [Parameter(ParameterSetName = 'Cleanup')]
    [ValidateRange(0, 3650)]
    [int]$OlderThanDays = 0,

    # Cleanup mode: when set, lists files that would be deleted/moved but makes no changes.
    [Parameter(ParameterSetName = 'Cleanup')]
    [switch]$DryRun,

    # Cleanup mode: optional additional temp paths to scan.
    [Parameter(ParameterSetName = 'Cleanup')]
    [string[]]$AdditionalPaths = @(),

    # Rollback mode: path to a manifest CSV created by a cleanup run.
    [Parameter(ParameterSetName = 'Rollback', Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$RollbackManifestPath,

    # Rollback mode: when set, lists files that would be restored but makes no changes.
    [Parameter(ParameterSetName = 'Rollback')]
    [switch]$RollbackDryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Section 1: Initialize paths and run metadata.
# This section sets up timestamped log and rollback output locations under the script folder.
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$logDir = Join-Path $scriptRoot 'logs'
$rollbackDir = Join-Path $scriptRoot 'rollback'
$quarantineRoot = Join-Path $rollbackDir ("quarantine_{0}" -f $timestamp)
$manifestPath = Join-Path $rollbackDir ("manifest_{0}.csv" -f $timestamp)
$logPath = Join-Path $logDir ("temp_cleanup_{0}.log" -f $timestamp)

if (-not (Test-Path -LiteralPath $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
}
if (-not (Test-Path -LiteralPath $rollbackDir)) {
    New-Item -Path $rollbackDir -ItemType Directory -Force | Out-Null
}

# Section 2: Logging helper.
# This section writes every action to both console and timestamped log file.
function Write-Log {
    param(
        [string]$Level,
        [string]$Message
    )

    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Write-Output $line
    Add-Content -LiteralPath $logPath -Value $line
}

# Section 3: Locked-file detection helper.
# This section checks whether a file is currently locked by attempting a non-sharing read open.
function Test-FileLocked {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::None)
        $stream.Close()
        return $false
    }
    catch [System.IO.IOException] {
        return $true
    }
    catch {
        return $false
    }
}

# Section 4: Cleanup mode implementation.
# This section scans temp locations, filters by age, skips locked files, quarantines candidates, and logs each action.
if ($PSCmdlet.ParameterSetName -eq 'Cleanup') {
    Write-Log -Level 'INFO' -Message 'Starting cleanup mode.'

    $defaultTargets = @($env:TEMP, "$env:WINDIR\Temp")
    $targetPaths = @($defaultTargets + $AdditionalPaths | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
    $cutoff = (Get-Date).AddDays(-$OlderThanDays)

    $stats = [ordered]@{
        Mode = 'Cleanup'
        Targets = 0
        ScannedFiles = 0
        EligibleFiles = 0
        MovedToQuarantine = 0
        DryRunListed = 0
        SkippedLocked = 0
        SkippedNotFound = 0
        SkippedErrors = 0
    }

    $manifestRows = New-Object System.Collections.Generic.List[object]

    if (-not $DryRun) {
        if (-not (Test-Path -LiteralPath $quarantineRoot)) {
            New-Item -Path $quarantineRoot -ItemType Directory -Force | Out-Null
        }
    }

    foreach ($target in $targetPaths) {
        $stats.Targets++
        Write-Log -Level 'INFO' -Message ("Scanning target: {0}" -f $target)

        if (-not (Test-Path -LiteralPath $target)) {
            Write-Log -Level 'WARN' -Message ("Target not found, skipping: {0}" -f $target)
            continue
        }

        try {
            $files = Get-ChildItem -LiteralPath $target -File -Recurse -Force -ErrorAction Stop
        }
        catch {
            Write-Log -Level 'ERROR' -Message ("Failed to enumerate target: {0}. Error: {1}" -f $target, $_.Exception.Message)
            $stats.SkippedErrors++
            continue
        }

        foreach ($file in $files) {
            $stats.ScannedFiles++

            if ($file.LastWriteTime -gt $cutoff) {
                continue
            }

            $stats.EligibleFiles++

            try {
                if (Test-FileLocked -Path $file.FullName) {
                    $stats.SkippedLocked++
                    Write-Log -Level 'WARN' -Message ("Locked file skipped: {0}" -f $file.FullName)
                    continue
                }

                if ($DryRun) {
                    $stats.DryRunListed++
                    Write-Output $file.FullName
                    Write-Log -Level 'INFO' -Message ("DRYRUN would delete: {0}" -f $file.FullName)
                    continue
                }

                $safeName = $file.FullName -replace '[:\\/ ]', '_'
                $destination = Join-Path $quarantineRoot $safeName
                if (Test-Path -LiteralPath $destination) {
                    $destination = Join-Path $quarantineRoot ("{0}_{1}" -f $safeName, [Guid]::NewGuid().ToString('N'))
                }

                Move-Item -LiteralPath $file.FullName -Destination $destination -Force -ErrorAction Stop
                $stats.MovedToQuarantine++

                $manifestRows.Add([pscustomobject]@{
                    OriginalPath = $file.FullName
                    QuarantinePath = $destination
                    LastWriteTime = $file.LastWriteTime
                    LengthBytes = $file.Length
                    Action = 'Moved'
                    ActionTime = (Get-Date)
                }) | Out-Null

                Write-Log -Level 'INFO' -Message ("Deleted (quarantined): {0} -> {1}" -f $file.FullName, $destination)
            }
            catch {
                if (-not (Test-Path -LiteralPath $file.FullName)) {
                    $stats.SkippedNotFound++
                    Write-Log -Level 'WARN' -Message ("File no longer exists, skipped: {0}" -f $file.FullName)
                }
                else {
                    $stats.SkippedErrors++
                    Write-Log -Level 'ERROR' -Message ("Failed file action: {0}. Error: {1}" -f $file.FullName, $_.Exception.Message)
                }
            }
        }
    }

    if (-not $DryRun) {
        $manifestRows | Export-Csv -LiteralPath $manifestPath -NoTypeInformation -Encoding UTF8
        Write-Log -Level 'INFO' -Message ("Rollback manifest created: {0}" -f $manifestPath)
        Write-Log -Level 'INFO' -Message ("Quarantine path: {0}" -f $quarantineRoot)
    }

    # Section 5: Cleanup summary output.
    # This section prints an end-of-run summary so engineers can verify what happened.
    Write-Output ''
    Write-Output '=== Cleanup Summary ==='
    $stats.GetEnumerator() | ForEach-Object { Write-Output ("{0}: {1}" -f $_.Key, $_.Value) }
    Write-Output ("LogFile: {0}" -f $logPath)
    if (-not $DryRun) {
        Write-Output ("ManifestFile: {0}" -f $manifestPath)
    }

    return
}

# Section 6: Rollback mode implementation.
# This section restores previously quarantined files using a manifest file from a cleanup run.
if ($PSCmdlet.ParameterSetName -eq 'Rollback') {
    Write-Log -Level 'INFO' -Message 'Starting rollback mode.'
    Write-Log -Level 'INFO' -Message ("Manifest path: {0}" -f $RollbackManifestPath)

    if (-not (Test-Path -LiteralPath $RollbackManifestPath)) {
        throw "Rollback manifest not found: $RollbackManifestPath"
    }

    $rows = Import-Csv -LiteralPath $RollbackManifestPath
    $stats = [ordered]@{
        Mode = 'Rollback'
        RowsRead = 0
        Restored = 0
        DryRunListed = 0
        SkippedMissingQuarantineFile = 0
        SkippedDestinationExists = 0
        SkippedErrors = 0
    }

    foreach ($row in $rows) {
        $stats.RowsRead++

        $originalPath = [string]$row.OriginalPath
        $quarantinePath = [string]$row.QuarantinePath

        try {
            if (-not (Test-Path -LiteralPath $quarantinePath)) {
                $stats.SkippedMissingQuarantineFile++
                Write-Log -Level 'WARN' -Message ("Quarantine file missing, skipping: {0}" -f $quarantinePath)
                continue
            }

            if (Test-Path -LiteralPath $originalPath) {
                $stats.SkippedDestinationExists++
                Write-Log -Level 'WARN' -Message ("Destination exists, skipping restore: {0}" -f $originalPath)
                continue
            }

            if ($RollbackDryRun) {
                $stats.DryRunListed++
                Write-Output ("Would restore: {0} <- {1}" -f $originalPath, $quarantinePath)
                Write-Log -Level 'INFO' -Message ("DRYRUN would restore: {0} <- {1}" -f $originalPath, $quarantinePath)
                continue
            }

            $parentDir = Split-Path -Parent $originalPath
            if (-not (Test-Path -LiteralPath $parentDir)) {
                New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
            }

            Move-Item -LiteralPath $quarantinePath -Destination $originalPath -Force -ErrorAction Stop
            $stats.Restored++
            Write-Log -Level 'INFO' -Message ("Restored: {0} <- {1}" -f $originalPath, $quarantinePath)
        }
        catch {
            $stats.SkippedErrors++
            Write-Log -Level 'ERROR' -Message ("Rollback failed for {0}. Error: {1}" -f $originalPath, $_.Exception.Message)
        }
    }

    # Section 7: Rollback summary output.
    # This section prints a rollback summary so engineers can confirm restore outcomes.
    Write-Output ''
    Write-Output '=== Rollback Summary ==='
    $stats.GetEnumerator() | ForEach-Object { Write-Output ("{0}: {1}" -f $_.Key, $_.Value) }
    Write-Output ("LogFile: {0}" -f $logPath)

    return
}
