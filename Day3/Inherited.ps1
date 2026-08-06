<#
.SYNOPSIS
    System Health Snapshot

.DESCRIPTION
    Produces a quick read-only health report for the local machine.
    Reports: computer name and total RAM, free disk space on C:, the top 5
    processes by memory usage, recent System event-log errors, and a count
    of user profiles that have not been used in over 90 days.
    No changes are made to the system.

.AUTHOR
    Unknown (inherited script — refactored for readability 2026-08-05)

.HOW TO RUN
    Open PowerShell as the current user (no elevation required for basic use;
    reading all user profiles may require Administrator rights).

        .\Inherited.ps1

.NOTES
    Requires PowerShell 5.1 or later.
#>

# Retrieve hardware and OS details for this computer (name, total RAM, domain, etc.)
$computerSystem = Get-CimInstance Win32_ComputerSystem

# Get the amount of free space (in bytes) currently available on the C: drive
$diskFreeBytes = Get-PSDrive C | Select-Object -ExpandProperty Free

# Collect all running processes, sort by Working Set memory (highest first), keep top 5
$topMemoryProcesses = Get-Process | Sort-Object WS -Descending | Select-Object -First 5

# Read the last 10 System event-log entries and keep only errors (Level 2)
$systemErrors = Get-WinEvent -LogName System -MaxEvents 10 | Where-Object { $_.Level -eq 2 }

# Find local user profiles that are not system accounts and have not been used in 90+ days
$staleUserProfiles = Get-CimInstance Win32_UserProfile | Where-Object {
    -not $_.Special -and $_.LastUseTime -lt (Get-Date).AddDays(-90)
}

# Print the computer's hostname and total physical RAM (in bytes)
Write-Host $computerSystem.Name $computerSystem.TotalPhysicalMemory

# Convert free disk space from bytes to GB (2 decimal places) and print it
Write-Host ([math]::Round($diskFreeBytes / 1GB, 2)) 'GB free'

# Print the name and Working Set memory (in bytes) for each of the top 5 processes
$topMemoryProcesses | ForEach-Object { Write-Host $_.Name $_.WS }

# Print the timestamp and message for each System error event found earlier
$systemErrors | ForEach-Object { Write-Host $_.TimeCreated $_.Message }

# If any stale profiles were found, print how many there are
if ($staleUserProfiles.Count -gt 0) { Write-Host 'Stale profiles:' $staleUserProfiles.Count }