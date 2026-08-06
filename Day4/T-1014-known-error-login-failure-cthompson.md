# Known Error Record - T-1014 Login Failure (FINBRIDGE\cthompson)

Symptom: The user could not log in. During the incident window, sign-in attempts failed and then the account became locked out.

Cause: Repeated incorrect credential attempts for FINBRIDGE\cthompson caused account lockout. This prevented successful sign-in until administrative account recovery was completed.

Scope: This incident affected one user only: FINBRIDGE\cthompson. Related failed-attempt sources recorded were DESKTOP-FB022 and source IP 10.10.8.112.

Workaround: Perform account recovery and then validate login from the user endpoint. In this incident, account enablement (Event 4722 at 09:08:14) followed by successful interactive logon (Event 4624 at 09:09:01) restored service.

Permanent fix: Remediate the repeated bad-credential sources on DESKTOP-FB022 and 10.10.8.112, and remove outdated saved credentials for FINBRIDGE\cthompson on affected endpoints and applications. Keep early monitoring and triage for clustered auth failures to prevent lockout recurrence.

How to spot it: Look for this sequence: Event 4776 with error 0xC000006A (wrong password), repeated Event 4625 failures (unknown user name or bad password), Event 4740 account lockout, and Event 4771 with failure code 0x18 (wrong password). Recovery is confirmed by Event 4624 successful interactive logon.
