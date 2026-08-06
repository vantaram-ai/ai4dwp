# Invoke-TempCleanupSafe.ps1

## Purpose
Safe temp-file cleanup for Windows endpoints (PowerShell 5.1) with:
- Dry run mode
- Per-file error handling
- Locked-file skip behavior
- Timestamped logging
- End-of-run summary
- Rollback support via manifest
- Idempotent behavior

## Script Location
- `Day3/Invoke-TempCleanupSafe.ps1`

## What It Cleans
By default, the script scans:
- `%TEMP%` (current user temp)
- `%WINDIR%\Temp`

You can add paths with `-AdditionalPaths`.

## Safety Model
The script uses a safe-delete pattern:
- Instead of hard deleting files, it moves eligible files to a timestamped quarantine folder under `Day3/rollback`.
- A manifest CSV is created so files can be restored later.

This enables rollback and keeps operations safer on managed endpoints.

## Parameters
- `-OlderThanDays <int>`
  - Only target files older than this many days.
  - Default: `0`
- `-DryRun`
  - Cleanup mode dry run.
  - Prints files that would be deleted (quarantined) without making changes.
- `-AdditionalPaths <string[]>`
  - Optional extra paths to scan.
- `-RollbackManifestPath <string>`
  - Enables rollback mode using a manifest created during cleanup.
- `-RollbackDryRun`
  - Rollback mode dry run.
  - Prints files that would be restored without making changes.

## Usage Examples
### 1) Dry run (no changes)
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Day3\Invoke-TempCleanupSafe.ps1 -DryRun
```

### 2) Cleanup files older than 7 days
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Day3\Invoke-TempCleanupSafe.ps1 -OlderThanDays 7
```

### 3) Cleanup with additional path
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Day3\Invoke-TempCleanupSafe.ps1 -OlderThanDays 3 -AdditionalPaths "C:\Temp"
```

### 4) Rollback from manifest
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Day3\Invoke-TempCleanupSafe.ps1 -RollbackManifestPath .\Day3\rollback\manifest_YYYYMMDD_HHMMSS.csv
```

### 5) Rollback dry run
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Day3\Invoke-TempCleanupSafe.ps1 -RollbackManifestPath .\Day3\rollback\manifest_YYYYMMDD_HHMMSS.csv -RollbackDryRun
```

## Logging and Output
Each run writes a timestamped log to:
- `Day3/logs/temp_cleanup_YYYYMMDD_HHMMSS.log`

Cleanup runs (non-dry-run) also create:
- `Day3/rollback/manifest_YYYYMMDD_HHMMSS.csv`
- `Day3/rollback/quarantine_YYYYMMDD_HHMMSS/`

## Locked Files and Errors
- Locked files are detected and skipped.
- Errors are handled per file with try/catch.
- The script continues running and logs failures.

## Idempotency Notes
- Re-running cleanup does not re-process files already moved out of temp locations.
- Rollback skips files if destination already exists.
- Missing files are logged and skipped instead of failing the whole run.
