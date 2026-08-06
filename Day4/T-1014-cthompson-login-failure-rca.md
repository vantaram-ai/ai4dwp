# Root Cause Analysis (RCA)

Incident: User Login Failure - FINBRIDGE\cthompson  
Incident Date: 2024-03-15  
RCA Date: 2026-08-06  
Analyst: DWP Engineering

## 1. Executive Summary
At approximately 08:40, user FINBRIDGE\cthompson was unable to log in. Security log evidence showed repeated wrong-password authentication failures followed by account lockout. The resolution workflow was applied, and the incident was confirmed resolved at 09:09 with a successful interactive logon and no further issues reported.

## 2. Business Impact
- Impacted user: 1 (FINBRIDGE\cthompson only).
- Symptom: login failure.
- Duration: approximately 08:40 to 09:09.

## 3. Scope and Change Context
- Who: single user (FINBRIDGE\cthompson).
- Since: approximately 08:40.
- Change context: no environment change reported.

## 4. Supporting Evidence

### 4.1 Failure Evidence (Incident Window)
Source: Security Event Log, DESKTOP-FB022, 08:44-09:12

- 08:44:01 - Event 4776 Audit Failure: domain credential validation failed for FINBRIDGE\cthompson, error 0xC000006A (wrong password).
- 08:44:03 - Event 4625 Audit Failure: unknown user name or bad password, logon type 2, source DESKTOP-FB022.
- 08:44:28 - Event 4625 Audit Failure: unknown user name or bad password, logon type 2, source DESKTOP-FB022.
- 08:44:55 - Event 4625 Audit Failure: unknown user name or bad password, logon type 2, source DESKTOP-FB022.
- 08:44:56 - Event 4740 Audit Failure: account FINBRIDGE\cthompson locked out, caller computer DESKTOP-FB022.
- 08:45:10 - Event 4625 Audit Failure: failure reason account locked out, logon type 7 (unlock attempt), source DESKTOP-FB022.
- 08:45:44 - Event 4771 Audit Failure: Kerberos pre-auth failed for FINBRIDGE\cthompson, failure code 0x18 (wrong password), source IP 10.10.8.112.
- 08:46:01 - Event 4771 Audit Failure: Kerberos pre-auth failed, failure code 0x18, source IP 10.10.8.112.
- 08:46:33 - Event 4771 Audit Failure: Kerberos pre-auth failed, failure code 0x18, source IP 10.10.8.112.

### 4.2 Recovery Evidence
- 09:08:14 - Event 4722 Audit Success: user account FINBRIDGE\cthompson enabled by FINBRIDGE\helpdesk-admin.
- 09:09:01 - Event 4624 Audit Success: account FINBRIDGE\cthompson successfully logged on, logon type 2 (interactive), source DESKTOP-FB022.
- User verification: user able to log in to host and no issues reported after recovery.

## 5. Timeline (Local Time)
- ~08:40 - User reports inability to log in.
- 08:44:01 - First recorded wrong-password credential validation failure (Event 4776).
- 08:44:03 to 08:44:55 - Multiple interactive bad-password failures (Event 4625).
- 08:44:56 - Account lockout recorded (Event 4740).
- 08:45:10 - Locked-out sign-in attempt recorded (Event 4625, logon type 7).
- 08:45:44 to 08:46:33 - Continued Kerberos pre-auth wrong-password failures from 10.10.8.112 (Event 4771).
- 09:08:14 - Account enabled by helpdesk-admin (Event 4722).
- 09:09:01 - Successful interactive logon recorded (Event 4624).
- 09:09 - Incident marked resolved; user confirmed working.

## 6. Root Cause Statement
Verified root cause: repeated incorrect credential attempts for FINBRIDGE\cthompson caused account lockout, preventing successful sign-in until administrative account recovery actions were applied.

## 7. Contributing Factors
- Multiple wrong-password attempts were generated in a short period from DESKTOP-FB022.
- Additional wrong-password Kerberos pre-auth attempts continued from source IP 10.10.8.112 after lockout.

## 8. Resolution Implemented
- Account recovery actions were executed by helpdesk (evidenced by Event 4722).
- Authentication was validated by successful interactive logon (Event 4624 at 09:09:01).
- Post-recovery user verification confirmed normal login behavior.

## 9. 5-Whys Analysis
1. Why could cthompson not log in?  
Because authentication attempts were being rejected.

2. Why were authentication attempts rejected?  
Because credential validation failed with wrong-password errors.

3. Why did wrong-password failures lead to full access loss?  
Because repeated failures triggered account lockout.

4. Why did failures continue after lockout?  
Because additional authentication attempts with wrong credentials were still being generated from known sources.

5. Why did the issue clear after intervention?  
Because administrative account recovery was performed and successful interactive sign-in was re-established.

Systemic cause from 5-Whys: user identity access was interrupted by wrong-password retry behavior leading to lockout, requiring administrative recovery.

## 10. Preventive Actions
- Identify and remediate the source of repeated bad credential attempts on DESKTOP-FB022 and source IP 10.10.8.112.
- Ensure outdated saved credentials for FINBRIDGE\cthompson are removed from affected endpoints and applications.
- Add or tune monitoring for early warning on clustered Event 4776/4625/4771 failures before Event 4740 lockout occurs.
- Reinforce service desk playbook to triage lockout incidents by quickly correlating Event 4776, 4625, 4740, and 4624 timestamps.

## 11. Closure Confirmation
- Resolution time: 09:09.
- Technical confirmation: Event 4624 success at 09:09:01 for FINBRIDGE\cthompson.
- User confirmation: login to host verified and no further issue reported.
