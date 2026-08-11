# T-1015 Known Error - Autopilot Enrolment Failure (Legacy MDM Conflict)

Symptom     : During Autopilot onboarding, enrolment fails and the device does not progress into policy/application processing. The captured state shows EnrollmentState as Failed and ProfilesApplied as 0 of 4.

Cause       : Verified root cause is a conflicting pre-existing legacy manual MDM enrolment record dated 2023-11-04. The export explicitly reports ErrorCode 0x80180014 with message "The device is already enrolled in MDM."

Scope       : This affects devices entering Autopilot where a prior legacy manual MDM enrolment state/record is still present. In the verified incident, one endpoint was analysed and its onboarding user was impacted by blocked provisioning.

Workaround  : Remove the stale legacy enrolment record in Intune and disconnect the legacy work/school MDM connection on the endpoint, then re-run Autopilot from a clean state. This was the immediate service-restoration path defined in the RCA.

Permanent fix: Implement a mandatory pre-Autopilot enrolment hygiene gate to detect and remove legacy/stale MDM records before profile assignment. Add scheduled monitoring and cleanup for duplicate/stale device records to prevent recurrence.

How to spot it: Look for the combination of ErrorCode 0x80180014 and ErrorDescription "The device is already enrolled in MDM," with MDMEnrolled shown as Yes from a legacy enrolment source and ProfilesApplied at 0 of 4. Supporting signal may include LastError 0x80070005 (Access denied); no event IDs or module names were provided in the verified export.