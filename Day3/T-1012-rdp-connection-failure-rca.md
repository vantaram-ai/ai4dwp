# T-1012 - RDP Connection Failure RCA

## Incident Summary

- Incident type: Remote Desktop Protocol (RDP) connection failure followed by account lockout and later successful sign-in
- User account: `FINBRIDGE\bwalker`
- Client IP: `10.10.5.44`
- Review window: 2024-03-15 14:01:02 to 14:22:09
- Analysis date: 2026-08-05
- User impact: User could not establish a successful RDP session until after the account was no longer locked and valid credentials were used.

## Source Event List (Provided)

1. 14:01:02 - System - `TermDD` - Event ID `56` - Error  
   The Terminal Server security layer detected an error in the protocol stream and disconnected the client. Client IP: `10.10.5.44`
2. 14:01:02 - System - `RemoteDesktopServices-RdpCoreTS` - Event ID `140` - Warning  
   A connection from `10.10.5.44` failed because the user name or password is not correct.
3. 14:01:04 - Security - Event ID `4625` - Audit Failure  
   Account: `FINBRIDGE\bwalker` - Failure reason: `Unknown username or bad password` - Logon type: `10 (RemoteInteractive)` - Source IP: `10.10.5.44`
4. 14:03:18 - Security - Event ID `4625` - Audit Failure  
   Account: `FINBRIDGE\bwalker` - Failure reason: `Unknown username or bad password` - Logon type: `10 (RemoteInteractive)` - Source IP: `10.10.5.44`
5. 14:05:33 - Security - Event ID `4625` - Audit Failure  
   Account: `FINBRIDGE\bwalker` - Failure reason: `Unknown username or bad password` - Logon type: `10 (RemoteInteractive)` - Source IP: `10.10.5.44`
6. 14:05:34 - Security - Event ID `4740` - Audit Failure  
   Account: `FINBRIDGE\bwalker` - Caller computer: `10.10.5.44` - Description: A user account was locked out
7. 14:22:07 - System - `RemoteDesktopServices-RdpCoreTS` - Event ID `131` - Info  
   Server accepted a new TCP connection from client `10.10.5.44:52341`.
8. 14:22:09 - Security - Event ID `4624` - Audit Success  
   Account: `FINBRIDGE\bwalker` - Logon type: `10 (RemoteInteractive)` - Source IP: `10.10.5.44`

## What Each Event ID Records

### Event ID 56 (Source: TermDD)
This event records that the RDP transport/security layer detected a problem in the protocol stream and terminated the session attempt.

What it typically captures:
- Failure at the Terminal Services driver/security layer
- Client endpoint involved
- That the connection was disconnected before a usable session was established

What it means here:
- The server saw an RDP security/protocol problem from client `10.10.5.44` during connection setup.
- In this event chain, it is best treated as a disconnect symptom occurring during failed authentication or session negotiation, not as proof of a server-side application crash.

### Event ID 140 (Source: RemoteDesktopServices-RdpCoreTS)
This event records that an incoming RDP connection failed because the submitted credentials were not accepted.

What it typically captures:
- Client IP address
- Reason the RDP connection was denied
- Failure during the RDP sign-in path, often before full session creation

What it means here:
- The RDP stack explicitly states the connection from `10.10.5.44` failed due to incorrect username or password.

### Event ID 4625 (Source: Security)
This event records a failed logon attempt.

What it typically captures:
- Account name used
- Failure reason
- Logon type
- Source IP or workstation

What it means here:
- `FINBRIDGE\bwalker` attempted Remote Desktop sign-in and authentication failed.
- Logon type `10` confirms these were RemoteInteractive logons, which is the expected type for RDP.
- Repeated `4625` events show multiple bad-credential attempts from the same source IP.

### Event ID 4740 (Source: Security)
This event records that an account was locked out after the lockout threshold was reached.

What it typically captures:
- Account that was locked
- Calling computer or source that triggered the lockout
- Confirmation that account status changed to locked

What it means here:
- `FINBRIDGE\bwalker` was locked out immediately after the third bad-password RDP attempt.
- The triggering source was `10.10.5.44`.

### Event ID 131 (Source: RemoteDesktopServices-RdpCoreTS)
This event records that the RDP server accepted a new inbound TCP connection from a client.

What it typically captures:
- Source client IP and source port
- Successful acceptance of the network connection at the TCP layer

What it means here:
- Network connectivity to the RDP service was working at 14:22:07.
- This does not by itself prove login success, but it confirms the server was reachable and accepted the connection.

### Event ID 4624 (Source: Security)
This event records a successful logon.

What it typically captures:
- Account name
- Logon type
- Source IP/workstation
- Creation of a valid authenticated session

What it means here:
- `FINBRIDGE\bwalker` successfully authenticated via RDP.
- Logon type `10` confirms a successful Remote Desktop sign-in from `10.10.5.44`.

## Reconstructed Sequence of Events in Plain English

1. At 14:01:02, client `10.10.5.44` attempted to start an RDP session.
2. During that attempt, the RDP stack recorded a protocol/security-layer disconnect (`TermDD` 56).
3. At the same time, the RDP core service logged the real operational reason for the failed session: the username or password submitted by the client was not correct (`RdpCoreTS` 140).
4. Two seconds later, Security event `4625` confirmed that `FINBRIDGE\bwalker` failed a RemoteInteractive logon from `10.10.5.44` because of bad credentials.
5. The same account retried again at 14:03:18 and failed for the same reason.
6. A third RDP sign-in attempt failed at 14:05:33, again due to bad credentials.
7. One second later, at 14:05:34, the account lockout threshold was reached and Windows locked `FINBRIDGE\bwalker` (`4740`).
8. At 14:22:07, the same client established a fresh TCP connection to the RDP service, showing the server was reachable and listening.
9. At 14:22:09, Security event `4624` confirmed that `FINBRIDGE\bwalker` successfully completed an RDP logon from `10.10.5.44`.
10. The timeline shows an initial series of failed RDP authentications leading to account lockout, followed later by a successful connection once valid access conditions were restored.

## Most Likely Cause

### Most Likely Cause of the RDP Failure
The most likely cause of the RDP connection failure was repeated submission of invalid credentials for `FINBRIDGE\bwalker` from client `10.10.5.44`, which then triggered an account lockout.

Why this is the strongest conclusion:
- `RdpCoreTS` Event `140` explicitly states the username or password was incorrect.
- Three `4625` failures show repeated bad-credential attempts using logon type `10`.
- `4740` confirms those failures escalated into account lockout.
- Later `131` plus `4624` proves the server and network path were functional once the authentication issue was resolved.

### About the “Application Crash” Wording
There is no direct evidence of an application crash in the provided events.

What the logs support instead:
- Authentication failure during RDP connection setup
- Session disconnect at the protocol/security layer as a side effect of the failed sign-in path
- Policy-driven account lockout after repeated bad passwords

Most likely interpretation:
- This was an authentication and account-state incident, not an application crash incident.

## 5 Whys Analysis

### Problem Statement
`FINBRIDGE\bwalker` could not complete an RDP sign-in from `10.10.5.44` during the initial connection attempts.

1. Why did the RDP session fail?
- Because the server rejected the RDP sign-in attempts during authentication.

2. Why were the sign-in attempts rejected?
- Because the username/password presented for `FINBRIDGE\bwalker` were not valid, as shown by `RdpCoreTS` Event `140` and Security Event `4625`.

3. Why did the issue become persistent instead of being a single failed attempt?
- Because the same source retried multiple times with bad credentials.

4. Why did repeated retries make the situation worse?
- Because the repeated bad-password attempts reached the lockout threshold and generated Security Event `4740`, placing the account into a locked state.

5. Why was the user eventually able to connect later?
- Because the account was no longer blocked and a subsequent RDP attempt used conditions that allowed successful authentication, evidenced by Event `4624` after the new TCP connection in Event `131`.

### Root Cause (Most Probable)
Repeated invalid RDP credentials from `10.10.5.44` caused authentication failures and triggered account lockout for `FINBRIDGE\bwalker`.

### Contributing Factors
- RDP/NLA session setup terminated immediately when authentication failed.
- The source retried enough times to trigger lockout policy.
- The early `TermDD` protocol-stream error could make the incident appear like a transport issue even though the identity events point to credentials as the actual cause.

## Evidence Matrix

- Event `56` at 14:01:02: RDP security/protocol layer disconnected the client during setup.
- Event `140` at 14:01:02: RDP service states credentials were incorrect.
- Event `4625` at 14:01:04: First failed RDP authentication for `FINBRIDGE\bwalker`.
- Event `4625` at 14:03:18: Second failed RDP authentication from same source.
- Event `4625` at 14:05:33: Third failed RDP authentication from same source.
- Event `4740` at 14:05:34: Account lockout triggered by the same client.
- Event `131` at 14:22:07: Server accepted a new TCP connection, showing reachability.
- Event `4624` at 14:22:09: Successful RDP authentication confirms service restoration.

## Analyst Conclusion

The incident sequence is internally consistent and points to an authentication-driven RDP failure. The initial connection from `10.10.5.44` did not fail because the RDP service crashed. It failed because invalid credentials were submitted repeatedly for `FINBRIDGE\bwalker`, which led to account lockout. The later successful `4624` logon shows the RDP service itself was available and functional once correct access conditions were restored.

## Recommended Follow-up Actions

1. Confirm with the user whether the wrong password was entered manually or whether a saved/stale credential on the RDP client was retrying automatically.
2. Check Windows Credential Manager or saved `.rdp` profile settings on client `10.10.5.44` for outdated credentials.
3. Review domain lockout policy thresholds to ensure they match operational tolerance.
4. Correlate with domain controller security logs if a stricter audit trail is needed for the exact unlock/reset path before the successful 14:22 logon.
5. If this pattern repeats, alert on sequences of `4625` plus `4740` from the same RDP client IP.