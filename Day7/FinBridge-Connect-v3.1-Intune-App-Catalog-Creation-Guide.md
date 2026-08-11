# FinBridge Connect v3.1 - Intune App Catalog Creation Guide (Pre-Rollout)

## Purpose and scope
This guide explains how to add FinBridge Connect v3.1 to the Intune app catalog before phased deployment. It is written for DWP engineers with no prior Intune app deployment experience.

Deployment context for this worked example:
- Application: FinBridge Connect v3.1 (.intunewin)
- Target fleet: 10,000 Windows 11 endpoints
- Overall deadline: 3 weeks
- Priority cohort: Finance team (500 users) by end of week 1
- Constraint: about 5% of devices have older hardware (4 GB RAM)
- Rollback path exists: FinBridge Connect v3.0 remains in Intune catalog
- Detection method: registry version check

## 1) Where to add an app in Intune

1. Open Microsoft Intune admin center.
2. Go to Apps -> Windows.
3. Select Add.
4. In Select app type, choose the correct app type:
   - For this worked example (.intunewin): Windows app (Win32)
   - For Microsoft Store packages: Microsoft Store app (new)
   - For a URL shortcut: Web link

UI label variability warning:
- Menu names can differ by tenant version and admin-center updates.
- If you do not see exact labels above, verify live in your tenant by looking for the Windows app add flow and app-type selector, then continue with the matching option.

## 2) Required fields for a Windows LOB app (.intunewin)

2.1 Upload and basic app information

1. In the Win32 app wizard, upload the .intunewin package for FinBridge Connect v3.1.
2. Complete App information:
   - Name: FinBridge Connect v3.1
   - Description: Finance desktop connectivity client (silent enterprise install)
   - Publisher: FinBridge
   - Version: 3.1
3. Add optional metadata (recommended): category, logo/icon, help URL, privacy URL, owner, notes.

Expected result:
- App metadata is complete and clearly identifies version 3.1 as distinct from 3.0.

UI label variability warning:
- Some tenants show this page as App information, others as Properties or Information.

2.2 Program configuration

1. Set Install command:
   - FinBridgeConnect_Setup.exe /silent
2. Set Uninstall command:
   - FinBridgeConnect_Setup.exe /uninstall /silent
3. Set Install behavior/context:
   - Use System context for device-wide deployment unless vendor guidance requires per-user context.
4. Keep default restart behavior unless vendor install docs require a different restart handling policy.

Expected result:
- Intune has deterministic install and uninstall instructions that can run unattended.

UI label variability warning:
- Install behavior may appear as Install context, Behavior, or Run this script using the logged-on credentials (for related flows). Verify the setting maps to device/system context.

2.3 Requirements

1. OS architecture:
   - Select architectures supported by the package (typically 64-bit for Win11 fleet).
2. Minimum OS version:
   - Set minimum supported Windows 11 build per your engineering standard.
3. For known low-spec devices (4 GB RAM):
   - Record this as a deployment risk note and keep them in pilot observation cohorts before broad assignment.

Expected result:
- Intune will target only compatible devices and reduce avoidable failed installs.

UI label variability warning:
- Architecture and OS version controls may be grouped under Requirements or Device requirements depending on UI version.

2.4 Detection rules (registry key method for this app)

1. Add a manual detection rule.
2. Rule type: Registry.
3. Hive/path: HKLM\SOFTWARE\FinBridge\Connect
4. Value name: Version
5. Detection method: String comparison equals
6. Expected value: 3.1
7. Confirm 64-bit registry handling option as appropriate for the app architecture.

Expected result:
- Intune marks the app Installed only when registry value matches 3.1.

Alternative supported detection methods (for other apps):
- MSI product code
- File or folder path/version

UI label variability warning:
- Registry rule controls can appear as Detection rules, App detection, or Detection method pages.

2.5 Return codes

1. Review default return codes first.
2. Confirm which codes are treated as:
   - Success
   - Soft reboot required
   - Hard reboot required
   - Retry
   - Failure
3. If vendor documentation defines non-standard success codes, add them explicitly.

Expected result:
- Intune interprets installer exits correctly and avoids false failures.

UI label variability warning:
- Return code section may appear as Return codes, Exit codes, or Program return handling.

## 3) Assignment basics

1. Understand assignment types:
   - Required: auto-installs for targeted users/devices.
   - Available: user can install from Company Portal.
   - Uninstall: removes app from targeted users/devices.
2. Do not assign new app builds directly to the full 10,000-device fleet first.
3. Use phased targeting:
   - Pilot ring first (small test group).
   - Priority ring next (Finance 500 users by end of week 1).
   - Broad rings after pilot success.
4. Keep v3.0 available as rollback baseline while v3.1 is stabilizing.

Why pilot first:
- Validates packaging, detection, and return-code handling safely.
- Limits business impact if low-spec (4 GB RAM) devices struggle.
- Confirms uninstall/rollback behavior before broad deployment.

UI label variability warning:
- Assignment sections may be shown as Assignments, Required/Available for enrolled devices, or Group assignments.

## 4) Verification steps

4.1 Confirm app exists correctly in catalog

1. Open Apps -> Windows.
2. Find FinBridge Connect v3.1.
3. Confirm key properties:
   - App type is Win32
   - Version shows 3.1
   - Install/uninstall commands are correct
   - Detection rule points to HKLM\SOFTWARE\FinBridge\Connect\Version = 3.1

Expected result:
- Catalog object matches intended deployment configuration.

4.2 Check install status on an assigned test device

1. Open the app entry and view Device install status (or equivalent status blade).
2. Filter for pilot group devices.
3. Open one test device record and inspect status detail.
4. Cross-check on endpoint that app is present and usable.

Expected result:
- Assigned pilot device reports Installed once detection rule matches.

UI label variability warning:
- Status views may appear as Device install status, User install status, Monitor, or Installation status.

4.3 Interpret key status values

- Installed:
  - App installed and detection rule matched expected version 3.1.
- Failed:
  - Install attempted but failed, or detection rule did not validate installation state.
- Not applicable:
  - Device does not meet assignment/requirement criteria (for example architecture or OS mismatch).

Operational note:
- Investigate Failed first in pilot, then verify whether Not applicable is expected by design.

## 5) Completion checklist (before phased rollout starts)

1. Win32 app created and visible in catalog.
2. App information complete and versioned as 3.1.
3. Program commands configured exactly as validated.
4. Requirements aligned to supported Win11 endpoints.
5. Registry detection rule configured to Version = 3.1.
6. Return codes validated against installer behavior.
7. Pilot assignment configured (not full fleet).
8. Monitoring view confirms early pilot installs and no systemic failures.
9. Rollback readiness confirmed with v3.0 still available.

If any checklist item is incomplete, stop and correct configuration before moving to rollout phases.