# T-1007

## Summary
OneDrive has been stuck on "processing changes" since migration, and files are missing locally.

## Impact
Known affected users/devices: 1 user/device confirmed; wider impact across other migrated users: to-verify. Business urgency: medium to high, because missing local files and stalled sync may block access to working documents and create concern about data availability.

## Known Facts
- Ticket reference: T-1007
- OneDrive is stuck showing "processing changes."
- The issue has been present since a migration.
- Files are reported as missing locally.
- Whether files are missing only on the device or also in the cloud is to-verify.
- Whether OneDrive is signed in and otherwise connected is to-verify.
- Whether the issue affects all folders or selected folders is to-verify.
- Whether the user recently changed sync settings, Files On-Demand behavior, or folder redirection is to-verify.

## Missing Information to Gather
- User identity, device name, and business impact through approved records.
- Whether the missing files are visible in OneDrive on the web.
- Whether the user can open the expected files from the cloud but not locally.
- Whether the issue affects all synced content or only some folders.
- Whether OneDrive shows any additional message besides "processing changes."
- Whether the user recently signed out, rebuilt the device, or changed profile settings after migration.
- Available disk space on the device.
- Whether Files On-Demand is enabled: to-verify.
- Whether another migrated user is seeing the same behavior: to-verify.
- Whether Known Folder Move or similar profile migration steps were part of the migration: to-verify.

## Likely Category
File Sync / OneDrive / Post-Migration Profile Data

## First Diagnostic Step
Confirm whether the data exists in the cloud by checking if the reported missing files are visible in OneDrive on the web and whether the sync problem is local to the device; this quickly distinguishes a local sync client issue from an actual data availability problem.
