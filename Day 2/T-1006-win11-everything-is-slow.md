# T-1006

## Summary
User reports that everything is slow after upgrading to Windows 11 two days ago.

## Impact
Known affected users/devices: 1 user/device confirmed; wider impact across other upgraded devices: to-verify. Business urgency: medium, rising to high if the performance issue is preventing the user from completing core work across multiple applications.

## Known Facts
- Ticket reference: T-1006
- The user reports that everything is slow.
- The device was upgraded to Windows 11 two days ago.
- The slowness appears broad rather than limited to one named application.
- Whether the issue is constant or intermittent is to-verify.
- Whether the device is slow at startup, login, application launch, browsing, or all of these is to-verify.
- Whether CPU, memory, or disk usage is elevated is to-verify.
- Whether the issue started immediately after the Windows 11 upgrade is to-verify.

## Missing Information to Gather
- User identity, device name, and business impact through approved records.
- Whether the performance issue is constant or tied to specific tasks.
- Whether the device is slow at boot, sign-in, opening apps, browsing, Teams calls, or file access.
- Whether the issue occurs on battery, on power, or both.
- Current free disk space on the system drive.
- Approximate CPU, memory, and disk usage when the device is idle and when the user reproduces the issue.
- Whether there are pending updates, driver installs, indexing, or background sync activity.
- Whether the device uses SSD or HDD storage: to-verify.
- Whether other users with similar Windows 11 upgrades are seeing the same symptom: to-verify.
- Whether antivirus, OneDrive, or other background tools are heavily active: to-verify.

## Likely Category
Endpoint Performance / Windows 11 Post-Upgrade

## First Diagnostic Step
Open Task Manager and sort the Processes view by CPU, Memory, and Disk while the device is slow; this provides the fastest way to determine whether the issue is driven by a specific process, low available memory, heavy disk activity, or general post-upgrade background workload.
