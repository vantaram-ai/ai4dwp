# T-1004

## Summary
Company app fails to install from Company Portal with error 0x87D1041C.

## Impact
Known affected users: 1 user/device confirmed; wider impact across additional users, devices, or the app deployment itself: to-verify. Business urgency: medium to high, depending on whether the app is required for the user's core role or time-sensitive work.

## Known Facts
- Ticket reference: T-1004
- A company app is failing to install from Company Portal.
- The reported error code is 0x87D1041C.
- The install path involved is Company Portal rather than a manual installer.
- The affected app name and version are to-verify.
- Whether the issue affects one device or multiple devices is to-verify.
- Whether the device is otherwise healthy and compliant is to-verify.
- Whether the user has successfully installed other Company Portal apps is to-verify.

## Missing Information to Gather
- User identity, location, and contact details through approved service desk records.
- Device name and ownership details.
- Exact app name, publisher, and whether it is required or optional.
- Whether the problem affects one user, multiple users, or all users targeted for the app.
- Whether the app ever installed previously on this device.
- Whether other Company Portal apps install successfully on the same device.
- Whether the device is enrolled, recently built, or recently rebuilt.
- Whether the device shows as compliant and actively syncing: to-verify.
- Exact wording shown in Company Portal alongside the error code.
- Whether a restart, sync, or retry has already been attempted.

## Likely Category
Endpoint Management / Intune / Company Portal Application Deployment

## First Diagnostic Step
Confirm whether the failure is isolated to the device or affects the app deployment more broadly by checking if other Company Portal apps install on the same device and whether another targeted user or device can install the same app; this quickly separates a local device or enrollment problem from an app packaging, assignment, or deployment issue.
