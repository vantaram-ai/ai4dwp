<#
.SYNOPSIS
Read-only endpoint health report for DWP engineers (PowerShell 5.1).

.DESCRIPTION
Collects and displays:
- System uptime
- Free disk space
- Pending reboot indicators from registry
- Top 5 processes by memory (Working Set)
- Top 5 processes by CPU
- Last 5 System log errors

This script is strictly read-only and does not change system state.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Section 1: System uptime
# This section reads the last boot time from WMI/CIM and calculates elapsed uptime.
$os = Get-CimInstance -ClassName Win32_OperatingSystem
$lastBoot = if ($os.LastBootUpTime -is [datetime]) {
    $os.LastBootUpTime
} else {
    [Management.ManagementDateTimeConverter]::ToDateTime([string]$os.LastBootUpTime)
}
$uptime = (Get-Date) - $lastBoot

Write-Output '=== Endpoint Health Report ==='
Write-Output ("Computer Name: {0}" -f $env:COMPUTERNAME)
Write-Output ("Generated On:  {0}" -f (Get-Date))
Write-Output ''
Write-Output '--- System Uptime ---'
Write-Output ("Last Boot Time : {0}" -f $lastBoot)
Write-Output ("Uptime         : {0} days {1} hours {2} minutes" -f $uptime.Days, $uptime.Hours, $uptime.Minutes)
Write-Output ''

# Section 2: Free disk space
# This section reads local fixed disks (DriveType=3) and reports free/used space in GB.
$diskInfo = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" |
    Select-Object DeviceID,
        @{Name='SizeGB';Expression={ [math]::Round($_.Size / 1GB, 2) }},
        @{Name='FreeGB';Expression={ [math]::Round($_.FreeSpace / 1GB, 2) }},
        @{Name='UsedGB';Expression={ [math]::Round(($_.Size - $_.FreeSpace) / 1GB, 2) }}

Write-Output '--- Free Disk Space ---'
$diskInfo | Format-Table -AutoSize | Out-String | Write-Output
Write-Output ''

# Section 3: Pending reboot status
# This section checks known registry indicators that a reboot is pending.
# VERIFY: Confirm these registry paths with your DWP baseline if your image uses custom reboot signaling.
$rebootPendingCBS = Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
$rebootPendingWU = Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
$sessionManager = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -ErrorAction SilentlyContinue
$pendingRenameOps = $false
if (
    $null -ne $sessionManager -and
    $sessionManager.PSObject.Properties.Name -contains 'PendingFileRenameOperations' -and
    $null -ne $sessionManager.PendingFileRenameOperations
) {
    $pendingRenameOps = $true
}
$anyPendingReboot = $rebootPendingCBS -or $rebootPendingWU -or $pendingRenameOps

Write-Output '--- Pending Reboot Check (Registry) ---'
Write-Output ("CBS RebootPending key present                : {0}" -f $rebootPendingCBS)
Write-Output ("Windows Update RebootRequired key present    : {0}" -f $rebootPendingWU)
Write-Output ("PendingFileRenameOperations value present    : {0}" -f $pendingRenameOps)
Write-Output ("Any pending reboot indicator                 : {0}" -f $anyPendingReboot)
Write-Output ''

# Section 4: Top 5 processes by memory (Working Set)
# This section reads current process working set and lists the top 5 consumers,
# including executable full path when accessible.
$topMemory = Get-Process |
    Sort-Object -Property WorkingSet64 -Descending |
    Select-Object -First 5 ProcessName, Id,
        @{Name='WorkingSetMB';Expression={ [math]::Round($_.WorkingSet64 / 1MB, 2) }},
        @{Name='ExecutablePath';Expression={
            try {
                if ([string]::IsNullOrWhiteSpace($_.Path)) { '[Unavailable]' } else { $_.Path }
            } catch {
                '[AccessDeniedOrUnavailable]'
            }
        }}

Write-Output '--- Top 5 Processes by Memory (Working Set) ---'
$topMemory | Format-Table -AutoSize | Out-String | Write-Output
Write-Output ''

# Section 5: Top 5 processes by CPU
# This section uses cumulative CPU time (seconds) since each process started.
# VERIFY: CPU is cumulative process CPU seconds, not an instantaneous percentage sample.
# VERIFY: Some protected/system processes may not expose executable path without elevation.
$topCpu = Get-Process |
    Where-Object { $null -ne $_.CPU } |
    Sort-Object -Property CPU -Descending |
    Select-Object -First 5 ProcessName, Id,
        @{Name='CPUSeconds';Expression={ [math]::Round($_.CPU, 2) }},
        @{Name='ExecutablePath';Expression={
            try {
                if ([string]::IsNullOrWhiteSpace($_.Path)) { '[Unavailable]' } else { $_.Path }
            } catch {
                '[AccessDeniedOrUnavailable]'
            }
        }}

Write-Output '--- Top 5 Processes by CPU ---'
$topCpu | Format-Table -AutoSize | Out-String | Write-Output
Write-Output ''

# Section 6: Last 5 System log errors
# This section reads the newest 5 Error entries from the Windows System event log.
# VERIFY: Access to System log can require elevated rights depending on endpoint policy.
$lastSystemErrors = Get-EventLog -LogName System -EntryType Error -Newest 5 |
    Select-Object TimeGenerated, Source, EventID, Message

Write-Output '--- Last 5 System Log Errors ---'
$lastSystemErrors | Format-List | Out-String | Write-Output
