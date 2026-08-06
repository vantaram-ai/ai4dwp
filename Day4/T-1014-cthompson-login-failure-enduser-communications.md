# T-1014 Incident Communications - Three Audiences

## Audience 1 - Non-technical executive

Your access and data are safe. One user, FINBRIDGE\cthompson, could not sign in from about 08:40 after repeated incorrect password attempts caused account lockout, with attempts seen from DESKTOP-FB022 and 10.10.8.112; no wider system change was involved. Helpdesk re-enabled the account at 09:08:14, successful sign-in was recorded at 09:09:01 from DESKTOP-FB022, and the user confirmed no further issues. No action is needed.

## Audience 2 - Affected end-user team

Around 08:40, one teammate (FINBRIDGE\cthompson) could not sign in because repeated incorrect password attempts locked the account, with attempts coming from DESKTOP-FB022 and 10.10.8.112, and no wider system change involved; helpdesk re-enabled the account at 09:08:14, a successful sign-in was recorded at 09:09:01 from DESKTOP-FB022, and the user confirmed no further issues. If you see the same problem, stop retrying and contact the Service Desk.

## Audience 3 - Engineer-to-engineer internal note

Facts held constant:
- Single-user incident only: FINBRIDGE\cthompson.
- Onset approximately 08:40.
- No environment change reported.
- Repeated incorrect credential attempts triggered account lockout.
- Failed-attempt sources observed: DESKTOP-FB022 and 10.10.8.112.
- Recovery sequence: Event 4722 at 09:08:14 (account enabled by FINBRIDGE\helpdesk-admin), then Event 4624 at 09:09:01 (interactive success from DESKTOP-FB022).
- Incident resolved at 09:09; user verified working with no further issues.

Root cause:
- Identity-side lockout due to repeated wrong-password attempts for FINBRIDGE\cthompson.

Exact action taken:
- Helpdesk performed account recovery action evidenced by Security Event 4722 (enabled account).
- Login path was then validated via Security Event 4624 interactive success at 09:09:01 from DESKTOP-FB022.

Config/detail evidence:
- Security Event 4776 at 08:44:01: error 0xC000006A (wrong password).
- Security Event 4625 at 08:44:03, 08:44:28, 08:44:55: unknown user name or bad password (logon type 2), source DESKTOP-FB022.
- Security Event 4740 at 08:44:56: account lockout, caller DESKTOP-FB022.
- Security Event 4625 at 08:45:10: account locked out (logon type 7), source DESKTOP-FB022.
- Security Event 4771 at 08:45:44, 08:46:01, 08:46:33: Kerberos pre-auth failed, code 0x18 (wrong password), source IP 10.10.8.112.

Verification step:
- Technical verification: Event 4624 success at 09:09:01.
- User verification: user confirmed successful host login and no ongoing issue.

Preventive action needed:
- Identify/remediate repeated bad-credential sources on DESKTOP-FB022 and 10.10.8.112.
- Remove outdated saved credentials for FINBRIDGE\cthompson on affected endpoints/apps.
- Monitor clustered 4776/4625/4771 failures as an early warning before 4740 lockout.
- Keep service desk triage aligned to 4776 -> 4625 -> 4740 -> 4624 sequence.
