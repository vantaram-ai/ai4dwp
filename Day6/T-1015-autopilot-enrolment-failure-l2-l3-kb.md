# T-1015 - L2/L3 KB: Autopilot Enrolment Failure Due to Legacy MDM Conflict

## Background
Windows Autopilot is used to onboard Windows endpoints into managed state so Intune can apply required profiles, security controls, and applications. If enrolment fails at this stage, the device cannot complete managed onboarding and the user cannot be handed over as service-ready.

## Symptom
Engineer observes Autopilot enrolment failure with no profile progress (`ProfilesApplied: 0 of 4`) and an enrolment error state. User reports that device setup does not complete during company sign-in/setup and remains blocked.

## Root Cause
Specific technical cause: a pre-existing legacy manual MDM enrolment record (from 2023-11-04) conflicts with the new Autopilot enrolment transaction.

Evidence that confirms root cause:
- `EnrollmentState : Failed`
- `ErrorCode : 0x80180014`
- `ErrorDescription : The device is already enrolled in MDM.`
- `MDMEnrolled : Yes (previous enrolment from 2023-11-04)`
- `EnrolmentSource : Legacy manual MDM enrolment`
- Supporting impact signal: `ProfilesApplied : 0 of 4`, `LastError : 0x80070005 (Access denied)`
- Non-causal checks healthy: `AzureADJoined : Yes`, licensing present, network reachable/no proxy

## Detection
Confirm this exact issue before remediation.

### 1) Collect and validate diagnostic evidence
- Source: MDM diagnostic export from endpoint.
- What to look for:
  - `ErrorCode = 0x80180014`
  - `ErrorDescription = The device is already enrolled in MDM.`
  - `MDMEnrolled = Yes` with legacy/manual enrolment source
  - `ProfilesApplied = 0 of 4`

### 2) Validate tenant-side duplicate/stale enrolment state
- Portal path: Microsoft Intune admin center -> Devices -> All devices
- What to look for:
  - Existing or duplicate managed device record(s) for same serial/device identity
  - Older legacy enrolment footprint aligned with prior manual enrolment

### 3) Event IDs and log locations requirement
- Event IDs: none were captured in the verified RCA dataset for this incident.
- Log location used for authoritative confirmation in this case: MDM diagnostic export fields listed above plus Intune device record state.
- Use the error tuple (`0x80180014` + "already enrolled in MDM") as the primary signature for this known error.

## Resolution
Execute in order.

### Step 1 - Identify stale managed record(s)
- Path: Intune admin center -> Devices -> All devices
- Action: Search by serial and device name; enumerate all matching managed records.
- Expected result: stale/legacy record(s) identified and separated from intended current identity.

### Step 2 - Remove stale Intune record(s)
- Path: Intune admin center -> Devices -> All devices -> [device] -> Overview
- Action: Retire stale legacy record where applicable, then delete stale/duplicate record(s).
- Expected result: tenant-side conflicting enrolment record removed.

### Step 3 - Validate Autopilot identity and assignment
- Path: Intune admin center -> Devices -> Windows -> Windows enrollment -> Devices
- Action: Confirm hardware hash record exists and correct Autopilot profile assignment is present.
- Expected result: device is ready for clean Autopilot re-enrolment.

### Step 4 - Remove legacy local MDM connection on endpoint
- Path: Endpoint -> Settings -> Accounts -> Access work or school
- Action: Disconnect legacy work/school MDM connection; reboot endpoint.
- Expected result: local conflicting enrolment state cleared.

### Step 5 - Re-run Autopilot from clean state
- Action: Start Autopilot enrolment flow again and complete setup.
- Expected result: enrolment proceeds without `0x80180014`; profile/application processing starts.

## Verification
Fix is successful only if all checks pass:
- Intune device record appears as active fresh enrolment (no stale conflict record blocking path).
- Autopilot enrolment completes without `0x80180014`.
- Device is no longer stuck at `ProfilesApplied: 0 of 4`; processing advances.
- Device is managed and available for normal post-enrolment policy/compliance flow.

## Rollback
If remediation causes worse state (for example, unintended removal of active record or enrolment still blocked):

1. Stop further delete/retire actions until identity mapping is revalidated.
2. Reconfirm correct target identity in Intune using serial number and device name, then restore expected assignment state for Autopilot profile.
3. If endpoint was disconnected but cannot re-enrol immediately, keep device in controlled support state and re-run from clean onboarding path only after identity/profile reassignment is confirmed.
4. Escalate to Intune platform owner with captured evidence set:
   - export fields (`0x80180014`, message text, MDMEnrolled state)
   - record IDs removed
   - current Autopilot assignment state

## Preventive
Implement mandatory pre-flight enrolment hygiene before any Autopilot assignment:
- Check Intune for existing managed records by serial/device name.
- Retire/delete stale legacy manual enrolment records before re-onboarding.
- Add scheduled duplicate/stale record monitoring and cleanup workflow.
- Enforce as a required runbook gate in service desk and engineer procedures.

## Related
- Day6/T-1015-autopilot-enrolment-failure-detailed-rca.md
- Day6/T-1015-autopilot-enrolment-failure-legacy-mdm-conflict-rca.md
- Day6/T-1015-known-error-autopilot-legacy-mdm-conflict.md
- Day6/T-1015-autopilot-enrolment-failure-l1-self-service.md
- Day6/T-1015-autopilot-enrolment-failure-closure-note.md
