# Invoke-EventLogArchiveCleanupSafe.ps1

## Purpose
Safe Windows Event Log archive and cleanup script for DWP endpoint engineers (PowerShell 5.1).

Features included:
- Dry run mode with record deletion counts
- Configurable age threshold (default: 3 days)
- Per-operation try/catch error handling
- Timestamped action logging
- End-of-run summary
- Rollback manifest and rollback mode
- Idempotent daily archive behavior

## Script Location
- Day3/Invoke-EventLogArchiveCleanupSafe.ps1

## Safety and Selection Logic
The script only clears a log when all of these are true:
1. The log is enabled and has records.
2. The newest event in that log is older than `-OlderThanDays`.
3. The log was successfully archived first.
4. No archive file for the same log and today's date already exists.

If today's archive exists, the script skips that log to remain idempotent.

## Parameters
- `-OlderThanDays <int>`
  - Minimum age threshold in days for a log to be eligible.
  - Default: `3`
- `-DryRun`
  - Cleanup dry run.
  - No changes are made.
  - Prints and logs the record count that would be deleted.
- `-LogNames <string[]>`
  - Optional list of specific log names to evaluate.
  - Example: `System`, `Application`, `Security`
- `-RollbackManifestPath <string>`
  - Enables rollback mode by using a manifest created by a prior cleanup run.
- `-RollbackDryRun`
  - Rollback dry run.
  - Prints which files would be restored to a restore folder.

## Usage Examples
### 1) Dry run with defaults (3 days)
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Day3\Invoke-EventLogArchiveCleanupSafe.ps1 -DryRun
```

### 2) Cleanup logs older than 7 days
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Day3\Invoke-EventLogArchiveCleanupSafe.ps1 -OlderThanDays 7
```

### 3) Cleanup specific logs only
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Day3\Invoke-EventLogArchiveCleanupSafe.ps1 -OlderThanDays 5 -LogNames System,Application
```

### 4) Rollback dry run
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Day3\Invoke-EventLogArchiveCleanupSafe.ps1 -RollbackManifestPath .\Day3\rollback\eventlog_manifest_YYYYMMDD_HHMMSS.csv -RollbackDryRun
```

### 5) Rollback execution
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Day3\Invoke-EventLogArchiveCleanupSafe.ps1 -RollbackManifestPath .\Day3\rollback\eventlog_manifest_YYYYMMDD_HHMMSS.csv
```

## Output Locations
- Logs:
  - `Day3/logs/eventlog_cleanup_YYYYMMDD_HHMMSS.log`
- Archives:
  - `Day3/eventlog-archive/<LogNameSafe>_YYYYMMDD.evtx`
- Rollback artifacts:
  - `Day3/rollback/eventlog_manifest_YYYYMMDD_HHMMSS.csv`
  - `Day3/rollback/<LogNameSafe>_YYYYMMDD_HHMMSS.evtx` (pre-clear backup)
- Rollback restore output:
  - `Day3/rollback/eventlog_restore_YYYYMMDD_HHMMSS/`

## Rollback Behavior Note
Windows Event Log channels do not provide a safe built-in mechanism to re-import events directly back into live channels.

Rollback mode therefore restores exported evidence files (archive + pre-clear backup) into a restore folder so engineers can:
- Retain deleted-event evidence
- Review logs in Event Viewer
- Use retained files for incident analysis or compliance

## Operational Notes
- Run from an elevated PowerShell session for full log/channel access.
- `Security` log operations typically require administrative permissions.
- In dry run, record counts are calculated and logged; no archive or clear operations are executed.
