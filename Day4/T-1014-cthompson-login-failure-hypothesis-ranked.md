# User Logon Incident Analysis - cthompson Login Failure

Date: 2026-08-06  
Analyst: DWP Engineering

## Scope Facts Used
- Symptom: user cthompson not able to login.
- Who: cthompson only one user.
- Since: approximately 08:40 this morning.
- Change: Nil.

## Ranked Hypotheses (Most Probable First)

1) User account lockout or bad password state
- Why this fits scope facts:
  - Only one user is affected, which strongly matches a user-specific credential problem.
  - No environment change reduces the likelihood of platform-wide causes.
  - Sudden onset at a specific time is consistent with lockout threshold being hit.
- Single fastest check:
  - Check domain sign-in/lockout status for cthompson and confirm whether the account is currently locked.

2) Conditional Access/MFA failure specific to cthompson
- Why this fits scope facts:
  - Single-user impact aligns with per-user policy, device-compliance, or MFA challenge failure.
  - No reported infrastructure change supports a policy/token edge case over platform outage.
- Single fastest check:
  - Review the latest Entra ID sign-in result for cthompson to see the exact failure reason code (MFA, CA block, token issue).

3) Account disabled, expired, or sign-in restricted
- Why this fits scope facts:
  - A single impacted identity with no broader blast radius is typical of account lifecycle/state issues.
  - Time-bound onset can map to account expiry or an administrative change to that user only.
- Single fastest check:
  - Verify cthompson account properties (enabled state, expiry, sign-in hours/restrictions) in identity management.

4) Profile/container issue for cthompson (user-specific profile corruption or attach failure)
- Why this fits scope facts:
  - One-user-only failures can occur when only that user's profile data is damaged or cannot mount.
  - No global change means host/platform can still be healthy for other users.
- Single fastest check:
  - Attempt sign-in for cthompson to an alternate session host and check profile attach result for that login attempt.

5) Licensing or entitlement mismatch for cthompson
- Why this fits scope facts:
  - Single-user symptom with no change can result from an individual license assignment or group-membership drift.
  - This can start abruptly when assignment is removed or entitlement evaluation changes for one identity.
- Single fastest check:
  - Validate cthompson assigned license and AVD app group entitlement at incident time.

## Positioning
This is a ranked differential based only on scope facts and is not a final root-cause conclusion.

---

## Incident Update - Event Evidence Assessment (2026-08-06)

### Evidence Window Reviewed
- Source: Security Event Log, DESKTOP-FB022
- Window: 2024-03-15 08:44-09:12

### Per-Hypothesis Judgement Using Event Evidence

1) User account lockout or bad password state  
Judgement: Supports
- Determining events:
  - 08:44:01, Security Event 4776, Error Code 0xC000006A (wrong password)
  - 08:44:03, 08:44:28, 08:44:55, Security Event 4625 (unknown user name or bad password)
  - 08:44:56, Security Event 4740 (user account locked out)
- Rationale:
  - Repeated bad-password failures culminate in explicit account lockout for FINBRIDGE\cthompson.

2) Conditional Access/MFA failure specific to cthompson  
Judgement: Contradicts
- Determining events:
  - 08:44:01, Event 4776 wrong-password validation failure
  - 08:45:44, 08:46:01, 08:46:33, Event 4771 failure code 0x18 (wrong password)
- Rationale:
  - Evidence attributes failure to incorrect credentials and lockout rather than MFA/CA enforcement outcomes.

3) Account disabled, expired, or sign-in restricted  
Judgement: Contradicts
- Determining events:
  - 08:44:01, Event 4776 wrong-password code 0xC000006A
  - 08:44:56, Event 4740 account lockout after failed attempts
- Rationale:
  - Failure signature is wrong password and lockout sequence, not disabled/expired/restricted account state.

4) Profile/container issue for cthompson (user-specific profile corruption or attach failure)  
Judgement: Contradicts
- Determining events:
  - 08:44:03 onward, repeated Event 4625 bad-password failures
  - 08:45:10, Event 4625 failure reason account locked out (unlock attempt)
- Rationale:
  - Authentication fails before session/profile initialization is reached.

5) Licensing or entitlement mismatch for cthompson  
Judgement: Contradicts
- Determining events:
  - 08:44:01, Event 4776 wrong-password validation failure
  - 08:44:56, Event 4740 account lockout
- Rationale:
  - Security log pattern indicates credential failure and lockout, not entitlement evaluation failure.

## Surviving Hypothesis After Elimination
User account lockout or bad password state for FINBRIDGE\cthompson.

## Detailed Resolution Steps

1) Contain the lockout source
- Stop repeated failed authentications from DESKTOP-FB022 and investigate source IP 10.10.8.112 for stale credential retries.
- Remove or disable any stored outdated credentials for FINBRIDGE\cthompson on identified sources.

2) Recover account access
- Unlock FINBRIDGE\cthompson account.
- Reset password per policy and require password change at next successful sign-in.

3) Eradicate stale credential paths
- Clear cached/saved credentials tied to FINBRIDGE\cthompson on DESKTOP-FB022.
- Check and remediate common replay points (applications, mapped resources, scheduled tasks, mobile clients, and scripts).

4) Validate service recovery
- Perform one interactive sign-in test for cthompson with updated credentials.
- Confirm no continuing Event 4625/4771 failures for a monitoring window after unlock/reset.

5) Close with monitoring
- Close incident once no further bad-password or lockout events are generated.
- Reopen only if new failed-authentication bursts recur from a specific endpoint/source.
