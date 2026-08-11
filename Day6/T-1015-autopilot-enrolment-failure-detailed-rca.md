# T-1015 - Detailed RCA: Autopilot Enrolment Failure (Legacy MDM Conflict)

**Author:** DWP Analyst  
**Date:** 2026-08-11  
**Incident Type:** Windows Autopilot enrolment failure  
**Severity:** Medium (blocks device onboarding)  
**Status:** Closed - Root cause confirmed

---

## 1) Executive Summary

Autopilot enrolment failed because the endpoint already had an existing legacy manual MDM enrolment record from 2023-11-04. This pre-existing enrolment conflicted with the new Autopilot-managed MDM enrolment workflow. The failure was not caused by Azure AD join state, licensing, or network connectivity.

Primary blocking signal:
- `ErrorCode: 0x80180014`
- `ErrorDescription: The device is already enrolled in MDM.`

Secondary impact signal:
- `ProfilesApplied: 0 of 4`
- `LastError: 0x80070005 (Access denied)`

---

## 2) Scope and Impact

### Scope
- Single endpoint analysed from MDM diagnostic export.
- Autopilot enrolment stage affected.
- Intune MDM policy/application processing did not begin.

### Business Impact
- Device onboarding could not complete through Autopilot.
- User readiness delayed until enrolment conflict is removed.
- Manual intervention required by endpoint and Intune administrators.

---

## 3) Supporting Evidence (From Diagnostic Export)

### Identity and enrolment state
- `EnrollmentState : Failed`
- `MDMEnrolled : Yes (previous enrolment from 2023-11-04)`
- `EnrolmentSource : Legacy manual MDM enrolment`
- `AzureADJoined : Yes`

### Error evidence
- `ErrorCode : 0x80180014`
- `ErrorDescription : The device is already enrolled in MDM.`
- `LastError : 0x80070005 (Access denied)`

### Policy/application processing evidence
- `ProfilesApplied : 0 of 4`

### Exclusion evidence (non-causal factors)
- `IntuneP1License : Yes`
- `AutopilotLicense : Yes`
- `Network : All endpoints reachable, no proxy`

### Evidence interpretation
- `0x80180014` confirms an existing MDM enrolment conflict.
- `0x80070005` confirms access denial occurred during attempted processing.
- `0 of 4` profiles applied confirms policy pipeline did not progress.

---

## 4) Timeline of Events

Note: Exact wall-clock timestamps were not present in the provided export. Timeline is reconstructed in logical sequence using available evidence.

1. Historical state established (2023-11-04):
   - Device enrolled through a legacy manual MDM path.
2. New onboarding attempt initiated:
   - Device entered Autopilot enrolment flow.
3. Enrolment conflict detected:
   - Platform returned `0x80180014` with explicit message that device was already enrolled in MDM.
4. Policy stage blocked:
   - `ProfilesApplied` remained at `0 of 4`.
5. Additional failure surfaced:
   - `0x80070005 (Access denied)` captured as last error.
6. Triage validation:
   - Azure AD join, licensing, and network checks all healthy; conflict isolated as root cause.

---

## 5) Root Cause Statement

The device retained a pre-existing legacy manual MDM enrolment record, creating a state conflict that prevented Autopilot from establishing a new compliant MDM enrolment session. Because enrolment did not complete, downstream profile/application processing did not start.

---

## 6) 5-Whys Analysis

### Problem
Autopilot enrolment failed and no profiles were applied.

### Why 1
Why did Autopilot enrolment fail?  
Because enrolment returned `0x80180014` with message indicating the device was already enrolled in MDM.

### Why 2
Why was the device already enrolled in MDM?  
Because a legacy manual enrolment from 2023-11-04 was still present.

### Why 3
Why was the old enrolment still present at re-onboarding time?  
Because stale legacy enrolment records/state were not removed before attempting Autopilot enrolment.

### Why 4
Why were stale records not removed before Autopilot?  
Because pre-enrolment hygiene checks were not consistently enforced as a mandatory runbook gate.

### Why 5
Why was pre-enrolment hygiene not mandatory?  
Because process controls for legacy-to-Autopilot transition were incomplete (no formalized detection-and-cleanup step as a required prerequisite).

### 5-Whys conclusion
Immediate technical cause: existing legacy MDM enrolment conflict.  
Process/root-system cause: missing mandatory pre-flight cleanup control for legacy enrolments.

---

## 7) Confirmed Non-Causes

The following were explicitly validated as healthy in the export and are not root cause drivers for this incident:

- Azure AD join status (`AzureADJoined : Yes`)
- Licensing (`IntuneP1License : Yes`, `AutopilotLicense : Yes`)
- Network path (`All endpoints reachable, no proxy`)

---

## 8) Corrective Actions Completed / Required

### Immediate corrective action
1. Remove stale legacy MDM enrolment records in Intune admin center.
2. Remove legacy work/school MDM connection on the endpoint.
3. Re-run Autopilot from clean enrolment state.

### Verification target
- Device enrols successfully in Intune through Autopilot.
- Device no longer reports `0x80180014`.
- Profile/application processing progresses from `0 of 4` to active completion.

---

## 9) Preventive Actions

### Preventive Action 1 - Mandatory pre-flight enrolment hygiene check
- Before Autopilot assignment, search Intune by serial/device name for existing managed device records.
- If legacy/manual enrolment exists, retire and delete stale records before re-onboarding.
- Make this a required checklist item in service desk and field engineer runbooks.

### Preventive Action 2 - Duplicate/stale record monitoring
- Run scheduled reporting for duplicate device identities and stale check-in records.
- Trigger cleanup workflow for records matching legacy enrolment patterns.

### Preventive Action 3 - Governance control for manual enrolment paths
- Restrict or phase out legacy manual MDM enrolment for device cohorts that must use Autopilot.
- Route exceptions through documented approval with explicit cleanup ownership.

### Preventive Action 4 - Readiness gate before user handoff
- Add go/no-go validation that confirms:
  - No conflicting MDM enrolment state.
  - Autopilot profile assignment completed.
  - Initial policy processing started.

---

## 10) Validation Checklist After Remediation

1. In Intune, device appears with fresh enrolment record (no stale duplicate conflict).
2. Autopilot deployment proceeds without `0x80180014`.
3. Device status moves beyond initial enrolment and begins applying assigned profiles.
4. User can access corporate resources subject to compliant-enrolled state.

---

## 11) Lessons Learned

- Existing MDM state is a hard blocker for Autopilot when not cleaned first.
- Healthy network and licensing do not offset enrolment-state conflicts.
- Legacy-to-modern management transition requires explicit pre-check controls, not ad-hoc triage.

---

## 12) Closure

Incident closed with confirmed root cause: legacy MDM enrolment conflict.  
No evidence supports licensing, Azure AD join, or network as primary cause in this case.  
Preventive controls have been defined to reduce recurrence across other legacy-enrolled devices.
