# Floor 6 Incident Runbook

## Purpose
Restore Floor 6 service safely while treating the Friday document management app rollout as the leading cause to test first (to confirm).

## Scope
Use this runbook when Floor 6 users report login slowness/failures, missing desktop shortcuts, or related issues after the Friday rollout.

## Preconditions
- Change owner or incident lead has approved containment actions.
- The Floor 6 ring group ID and the app name are known (to confirm exact values).
- Evidence collection has started or is in progress.

## Procedure

1. Confirm the impacted cohort.
   - Action: Verify affected users are on Floor 6 and capture device name, user name, first-seen time, and symptom.
   - Expected result: You can state which devices are in scope and whether the issue is isolated to the Floor 6 deployment cohort.

2. Confirm deployment overlap.
   - Action: Check whether the affected device is assigned the Friday document management app and whether the app is installed, pending, failed, or recently updated.
   - Expected result: You can confirm or rule out direct overlap between the incident and the app deployment.

3. Compare one affected and one unaffected device.
   - Action: Compare app version, Intune assignment state, shortcut presence, and sign-in behaviour between the two devices.
   - Expected result: Affected devices show a common deployment or profile pattern that is not present on the unaffected device (to confirm).

4. Contain the rollout if the deployment overlap is present.
   - Action: Pause the app assignment for the Floor 6 ring or remove the Floor 6 ring group from the app assignment.
   - Example command:

```powershell
Connect-MgGraph -Scopes "DeviceManagementApps.ReadWrite.All","Group.ReadWrite.All"

$appName = "Document Management App"   # to confirm exact name
$ringGroupId = "<Floor6-Ring-GroupId>" # to confirm

$app = Get-MgDeviceAppManagementMobileApp -Filter "displayName eq '$appName'" | Select-Object -First 1
$assignment = Get-MgDeviceAppManagementMobileAppAssignment -MobileAppId $app.Id |
    Where-Object { $_.Target.'@odata.type' -eq '#microsoft.graph.groupAssignmentTarget' -and $_.Target.GroupId -eq $ringGroupId }

Remove-MgDeviceAppManagementMobileAppAssignment -MobileAppId $app.Id -MobileAppAssignmentId $assignment.Id
```

   - Expected result: The app is no longer targeted to the Floor 6 ring, and no new installs or updates are sent to that cohort.

5. Verify user impact after containment.
   - Action: Re-check sign-in speed, shortcut visibility, and app launch behaviour on one affected device after the assignment change propagates.
   - Expected result: Login delay reduces, shortcut state stabilises, or symptoms stop worsening (to confirm exact timing).

6. Preserve the Copilot/security track separately.
   - Action: Capture the reported Copilot matter exposure details, timestamps, and user identity for Security/Compliance review.
   - Expected result: The information-governance concern remains tracked separately from the rollout fix and is not dismissed as a UI glitch.

## Verification
- The rollout is considered a likely contributor if symptoms improve after the app is paused or removed from the Floor 6 ring.
- The rollout is not confirmed as the cause if affected and unaffected devices have the same deployment state and no improvement follows containment (to confirm).
- Record the final comparison for:
  - app install state
  - deployment assignment state
  - sign-in behaviour
  - shortcut/profile behaviour
  - Copilot allegation status

## Rollback
Use rollback if the containment action causes an unintended effect or if the deployment must be restored after the incident is resolved.

1. Reapply the app assignment to the Floor 6 ring group.
   - Expected result: The app becomes targeted to the ring again.

2. Restore the previous assignment scope and settings.
   - Expected result: The app deployment matches the pre-containment state (to confirm exact prior configuration).

3. Confirm user impact before full re-enable.
   - Expected result: A controlled test user or pilot device can install and sign in without reproducing the incident.

4. If rollback is incomplete or worsens the issue, stop and escalate to the incident lead.
   - Expected result: No further changes are made until the deployment state is revalidated.

## Notes for the service desk
- Do not close this as "AI weirdness".
- Do not promise a restoration time you cannot control.
- Do not change permissions or purge logs before evidence is captured.
