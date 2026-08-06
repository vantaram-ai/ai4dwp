# RCA Report: User Account Lockout (jsmith)

## Incident Summary
- Incident type: User account lockout during workstation sign-in activity
- User: `jsmith`
- Host involved: `DESKTOP-FB001`
- Review window: 08:02:14 to 08:23:44 (30-minute analysis window)
- Analysis date: 2026-08-05

## Source Event List (Provided)
1. 08:02:14 - Security 4625 Audit Failure - Account: jsmith  
   Failure reason: Unknown username or bad password  
   Source: DESKTOP-FB001 - Logon type: 2 (Interactive)
2. 08:04:22 - Security 4625 Audit Failure - Account: jsmith  
   Failure reason: Unknown username or bad password  
   Source: DESKTOP-FB001 - Logon type: 2 (Interactive)
3. 08:06:01 - Security 4740 Audit Failure - Account: jsmith  
   Account locked out. Called from DESKTOP-FB001
4. 08:07:45 - Security 4625 Audit Failure - Account: jsmith  
   Failure reason: Account locked out  
   Source: DESKTOP-FB001 - Logon type: 7 (Unlock)
5. 08:22:10 - Security 4722 Audit Success - Account: jsmith  
   Account enabled. Done by: FINBRIDGE\helpdesk-admin
6. 08:23:44 - Security 4624 Audit Success - Account: jsmith  
   Successful logon. Logon type: 2 (Interactive)

## What Each Event ID Records

### Event ID 4625 (Audit Failure) - An account failed to log on
- Meaning: Windows recorded a failed authentication attempt.
- Key fields here:
  - Failure reason `Unknown username or bad password`: credentials submitted were not accepted.
  - Logon type `2 (Interactive)`: failure occurred at local console sign-in.
  - Logon type `7 (Unlock)`: failure occurred when attempting to unlock an existing session.
- Relevance: Shows repeated failed password use and later failed unlock because account was locked.

### Event ID 4740 (Audit Failure category, lockout event) - A user account was locked out
- Meaning: The account lockout threshold was reached and the account status changed to locked.
- Key field here:
  - `Called from DESKTOP-FB001`: source computer that generated the lockout-triggering authentication traffic.
- Relevance: This is the definitive lockout event and identifies the originating endpoint.

### Event ID 4722 (Audit Success) - A user account was enabled
- Meaning: An administrator enabled/re-enabled the account.
- Key field here:
  - Performed by `FINBRIDGE\helpdesk-admin`.
- Relevance: Indicates IT intervention restored account usability after lockout.

### Event ID 4624 (Audit Success) - An account was successfully logged on
- Meaning: Authentication succeeded and a valid logon session was created.
- Key field here:
  - Logon type `2 (Interactive)`: successful local console sign-in.
- Relevance: Confirms user access was restored after admin action.

## Reconstructed Sequence in Plain English
1. At 08:02, `jsmith` tried to sign in at the physical/interactive logon screen on `DESKTOP-FB001` and entered invalid credentials.
2. At 08:04, a second interactive sign-in attempt with invalid credentials was recorded from the same machine.
3. At 08:06, the bad-password attempt threshold was reached and Windows locked the account (`4740`).
4. At 08:07, another attempt occurred during workstation unlock (`logon type 7`), but it failed because the account was already locked.
5. At 08:22, helpdesk administrator `FINBRIDGE\helpdesk-admin` enabled/re-enabled the account (`4722`).
6. At 08:23, `jsmith` successfully signed in interactively (`4624`), confirming service restoration.

## Most Likely Cause of Lockout
The most likely cause is repeated bad password entry by the user (or someone at the same console) at `DESKTOP-FB001`, which exceeded the domain/local account lockout threshold.

### Evidence from events
- Two consecutive `4625` failures with reason `Unknown username or bad password` at 08:02 and 08:04.
- A lockout event `4740` at 08:06 explicitly tied to `DESKTOP-FB001`.
- Post-lockout `4625` with reason `Account locked out` at 08:07 confirms account state was locked, not merely wrong password at that point.
- Administrative recovery (`4722`) followed by successful `4624` indicates no persistent identity-system outage; issue was account state/credentials.

## Root Cause Analysis (RCA)

### Problem Statement
`jsmith` was unable to access the workstation because the account entered a locked state after repeated failed interactive sign-in attempts.

### Impact
- User productivity interruption from approximately 08:06 (lockout) to 08:23 (successful sign-in), about 17 minutes of confirmed access loss.
- Helpdesk intervention required.

### 5 Whys Analysis
1. Why was `jsmith` locked out?
- Because the account exceeded failed authentication threshold and triggered `4740` lockout.

2. Why did failed authentication threshold get exceeded?
- Because multiple sign-in attempts used credentials rejected as `Unknown username or bad password` (`4625` at 08:02 and 08:04), followed by additional attempt activity.

3. Why were invalid credentials being submitted repeatedly?
- Most likely the user entered an incorrect password repeatedly at interactive sign-in/unlock on `DESKTOP-FB001`.

4. Why did the issue persist long enough to require support intervention?
- After lockout, additional unlock attempt still occurred (`4625` with `Account locked out`), and self-recovery was not possible without administrative action.

5. Why was there no immediate self-service prevention/recovery?
- Current process likely depends on helpdesk account re-enable/unlock and does not sufficiently prevent repeated bad-password retries at the endpoint (for example, no immediate guided recovery path before threshold is reached).

### Root Cause (Most Probable)
Repeated incorrect password attempts from `DESKTOP-FB001` caused policy-based account lockout.

### Contributing Factors
- Human input error at interactive logon/unlock.
- Lockout policy threshold reached quickly.
- No immediate self-service correction before lockout state.

## Corrective and Preventive Actions (CAPA)

### Immediate corrective actions completed
- Helpdesk admin re-enabled/recovered account (`4722`) at 08:22.
- User successfully logged in at 08:23 (`4624`).

### Recommended preventive actions
1. User guidance
- Remind user to verify keyboard layout/Caps Lock before retries.
- Encourage stopping after 1-2 failures and using approved password reset workflow.

2. Endpoint checks
- Validate no stale cached credentials or saved credentials are auto-submitting on unlock.
- Review if any background process/service on `DESKTOP-FB001` is attempting old credentials.

3. Identity controls
- Confirm account lockout threshold and observation window are aligned with policy and business tolerance.
- Ensure helpdesk unlock workflow is rapid and documented.

4. Monitoring improvements
- Add alert correlation for repeated `4625` followed by `4740` from same endpoint to shorten triage time.

## Confidence and Limitations
- Confidence: High for lockout mechanism and sequence.
- Limitation: Only a narrow event subset was provided. Additional corroboration (DC logs, Kerberos/NTLM details, user interview, credential manager checks) would further distinguish user typo vs automated stale credential submissions.

## Final Determination
This was a policy-driven account lockout triggered by repeated bad-password interactive attempts originating from `DESKTOP-FB001`, followed by standard administrative recovery and successful user sign-in.