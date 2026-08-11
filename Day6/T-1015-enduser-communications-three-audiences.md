# T-1015 End-User Communications (Three Audiences)

## Audience 1 - Non-technical executive

Your access and data are safe. One device could not complete setup because it was already registered from an older 2023 enrolment, which blocked the new setup. We removed the old registration in Intune and on the device, then completed setup successfully. Licensing and network were healthy throughout. We are preventing recurrence by checking for old registrations before setup and running regular duplicate-record cleanup. You do not need to do anything.

## Audience 2 - Affected end-user team (10 people, non-technical)

Your access and data are safe. One device setup failed because it was still linked to an old 2023 company-management record, so the new setup could not continue. We removed the old record in Intune and on the device, then completed setup successfully; licensing and network were healthy. If you see the same issue, stop at the error and contact the Service Desk so we can clear the old record before retrying setup. Contact: DWP Service Desk / Endpoint Support.

## Audience 3 - Engineer-to-engineer internal note

User/data safety confirmed; no licensing or network fault observed (`IntuneP1License: Yes`, `AutopilotLicense: Yes`, `Network: all endpoints reachable, no proxy`).

Root cause:
- Existing legacy manual MDM enrolment (dated 2023-11-04) conflicted with Autopilot enrolment.
- Failure signature: `EnrollmentState: Failed`, `ErrorCode: 0x80180014`, `ErrorDescription: The device is already enrolled in MDM.`
- Secondary signal: `ProfilesApplied: 0 of 4`, `LastError: 0x80070005 (Access denied)` after conflict state.

Exact action taken:
1. In Intune admin center, identified stale/legacy managed-device record(s) for the endpoint.
2. Removed stale record path (retire/delete as appropriate) to clear tenant-side conflict.
3. On endpoint, removed legacy work/school MDM connection.
4. Re-ran Autopilot from clean state.

Config/process detail:
- Autopilot cannot complete over conflicting pre-existing MDM enrolment state.
- Legacy-to-Autopilot transition now requires explicit pre-flight enrolment hygiene.

Verification step:
- Confirmed successful post-cleanup enrolment without `0x80180014`.
- Confirmed pipeline moved past blocked state (`ProfilesApplied` no longer stuck at `0 of 4`) and onboarding completed.

Preventive action needed:
- Mandatory pre-Autopilot check for existing managed-device records by serial/device name.
- If legacy/manual record exists: retire/delete stale record before Autopilot assignment.
- Run scheduled duplicate/stale record monitoring and cleanup to prevent recurrence.
