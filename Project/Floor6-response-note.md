# Floor 6 response note

## Most likely cause
The most likely cause is the new document management app deployed to Floor 6 on Friday afternoon. The timing, the number of users affected, and the mix of logon slowness, missing shortcuts, and Copilot concern make this the leading cause to test first (to confirm).

## Rollback / pull from ring
Use this to remove the Floor 6 ring group from the app assignment in Intune and effectively roll back the deployment for that ring.

```powershell
Connect-MgGraph -Scopes "DeviceManagementApps.ReadWrite.All","Group.ReadWrite.All"

$appName = "Document Management App"   # to confirm exact name
$ringGroupId = "<Floor6-Ring-GroupId>" # to confirm

$app = Get-MgDeviceAppManagementMobileApp -Filter "displayName eq '$appName'" | Select-Object -First 1
$assignment = Get-MgDeviceAppManagementMobileAppAssignment -MobileAppId $app.Id |
    Where-Object { $_.Target.'@odata.type' -eq '#microsoft.graph.groupAssignmentTarget' -and $_.Target.GroupId -eq $ringGroupId }

Remove-MgDeviceAppManagementMobileAppAssignment -MobileAppId $app.Id -MobileAppAssignmentId $assignment.Id
```

If you need to pull a single affected device out of the ring group instead, use:

```powershell
Remove-MgGroupMemberByRef -GroupId "<Floor6-Ring-GroupId>" -DirectoryObjectId "<DeviceObjectId>"
```

## Plain-language note to Floor 6
We believe the issue is most likely linked to the new app rollout from Friday, so we are checking that change first and pausing it where needed. We are working to restore normal sign-in and desktop behaviour as quickly as possible, and we will share the next update as soon as we have confirmed evidence rather than giving a time we cannot yet guarantee.
