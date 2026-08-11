# T-1015 - Autopilot Enrolment Failure RCA (Legacy MDM Conflict)

**Author:** DWP Analyst  
**Date:** 2026-08-11  
**Service:** Windows Autopilot / Intune MDM enrolment  
**Status:** Root cause confirmed

---

## 1) Incident Summary

Autopilot enrolment failed because the device already had an active legacy manual MDM enrolment record from 2023-11-04. The new Autopilot MDM enrolment attempt conflicted with the existing enrolment state and could not proceed.

---

## 2) Evidence Captured

- `EnrollmentState : Failed`
- `ErrorCode : 0x80180014`
- `ErrorDescription : The device is already enrolled in MDM.`
- `MDMEnrolled : Yes (previous enrolment from 2023-11-04)`
- `EnrolmentSource : Legacy manual MDM enrolment`
- `ProfilesApplied : 0 of 4`
- `LastError : 0x80070005 (Access denied)`
- `AzureADJoined : Yes`
- `IntuneP1License : Yes`
- `AutopilotLicense : Yes`
- `Network : All endpoints reachable, no proxy`

Confirmed interpretation used in this RCA:
- `0x80180014` = device already enrolled in MDM (conflict with existing enrolment)
- `0x80070005` = Access denied

---

## 3) Confirmed Root Cause

A stale, pre-existing legacy manual MDM enrolment on the device created an enrolment conflict. Autopilot cannot complete MDM enrolment while a conflicting existing enrolment state/record is present.

---

## 4) Remediation Runbook (Exact Order of Operations)

Follow this sequence exactly.

### Step 1 - Identify all existing records for the device

- **Type:** Admin center only
- **Portal:** Microsoft Intune admin center
- **Path:** Devices -> All devices
- **Action:** Search by serial number and device name. Confirm if one or more existing managed device records are present, especially older records tied to the legacy enrolment date.
- **Record:** Device name, serial number, Intune device ID, ownership, last check-in time.

### Step 2 - Remove stale Intune managed-device enrolment record(s)

- **Type:** Admin center only
- **Portal:** Microsoft Intune admin center
- **Path:** Devices -> All devices -> [Device] -> Overview
- **Action:**
  1. Select **Retire** (if device is still active under the old enrolment).
  2. After retirement action is accepted, select **Delete** for stale/duplicate legacy record(s).
- **Notes:**
  - If duplicates exist, remove the stale legacy record(s) and keep only the intended current identity.
  - Wait for portal state to refresh before moving to the next step.

### Step 3 - Validate Autopilot identity remains present and correctly assigned

- **Type:** Admin center only
- **Portal:** Microsoft Intune admin center
- **Path:** Devices -> Windows -> Windows enrollment -> Devices
- **Action:**
  1. Locate the hardware hash record for the device.
  2. Confirm the correct deployment profile is assigned.
  3. Confirm profile assignment status is successful (or complete assignment before continuing).

### Step 4 - Remove local legacy enrolment state from the endpoint

- **Type:** Device access required (physical or remote)
- **Action:**
  1. Open **Settings -> Accounts -> Access work or school**.
  2. Disconnect the old work/school account tied to legacy manual MDM enrolment.
  3. Reboot the device.
- **If the old connection cannot be removed cleanly:**
  - Perform a corporate reset path suitable for Autopilot re-onboarding (Autopilot Reset or full wipe as per support policy).

### Step 5 - Start Autopilot enrolment from a clean OOBE state

- **Type:** Device access required (physical or remote with OOBE control)
- **Action:**
  1. Bring device to OOBE (after reset/wipe if required).
  2. Connect to network.
  3. Sign in with the target user account licensed for Intune and Autopilot.
  4. Allow ESP/enrolment flow to complete without interruption.

### Step 6 - Confirm device appears as newly enrolled and managed

- **Type:** Admin center only
- **Portal:** Microsoft Intune admin center
- **Path:** Devices -> All devices
- **Action:** Verify the device reappears with a fresh enrolment timestamp and active management state.

---

## 5) Verification Checks (Success Criteria)

Autopilot remediation is successful only when all checks below are true.

### Admin Center Verification

- **Type:** Admin center only
- **Path A:** Devices -> Windows -> Windows enrollment -> Devices
  - Device is listed and profile assignment is correct.
- **Path B:** Devices -> All devices -> [Device] -> Device compliance
  - Enrolment is active and compliance evaluation begins.
- **Path C:** Devices -> All devices -> [Device] -> Managed apps / Device configuration
  - Policy/application workload begins processing (not stuck at zero due to enrolment conflict).

### Device-Side Verification

- **Type:** Device access required (physical or remote)
- **Checks:**
  - OOBE/ESP completes without MDM conflict failure.
  - Work account is connected only once (no duplicate legacy connection).
  - User can reach company resources governed by compliant-enrolled state.

### Failure-to-Success Delta to Confirm

- Before remediation: `EnrollmentState Failed`, `ProfilesApplied 0 of 4`, `0x80180014`.
- After remediation: enrolment completes, device is managed in Intune, and policy/application processing starts normally.

---

## 6) Preventive Action for Wider Estate

### Preventive Control: Legacy enrolment hygiene gate before Autopilot assignment

- **Type:** Admin center only (process and governance)
- **Control design:**
  1. Before assigning Autopilot profile, perform a mandatory pre-check in Intune for existing managed-device records by serial number.
  2. If legacy/manual MDM record exists, retire and delete stale record before Autopilot re-enrolment.
  3. Add this as a required checklist step in the service desk runbook and change template.
  4. Run a scheduled weekly report for duplicate/stale records (old last check-in + same serial) and clean proactively.

### Optional hardening

- Block or tightly control manual legacy MDM enrolment paths for Autopilot-targeted device groups.
- Add an operations KPI: number of Autopilot failures due to pre-existing MDM enrolment should trend to zero.

---

## 7) Operator Quick Checklist

1. Admin center only: find and remove stale legacy Intune device record(s).
2. Admin center only: confirm Autopilot device identity/profile assignment is correct.
3. Device access required: disconnect legacy work/school MDM account on endpoint.
4. Device access required: reboot and return to clean OOBE (reset/wipe if needed).
5. Device access required: rerun Autopilot enrolment.
6. Admin center only: verify new managed record and normal policy processing.

---

## 8) Closure Statement

Root cause confirmed as legacy MDM enrolment conflict (`0x80180014`). Licensing and network were not limiting factors. Resolution is to remove stale enrolment records (tenant and device side), then rerun Autopilot from clean state with verification in Intune admin center and endpoint ESP completion.