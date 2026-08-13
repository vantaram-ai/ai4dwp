# Ranked Hypotheses — cthompson Login Failure (Event Log Scope)

Incident context used:
- User affected: cthompson only
- Symptom: cannot log in
- Start time: about 08:40 today
- Declared change: none
- Environment signal: 3 of 4 Floor 3 Win11 machines show domain/GPO failures; comparison machine unaffected with correct DNS

## 1) Most likely: Client received decommissioned DNS from DHCP, causing domain controller lookup failure

Why this fits the scope facts:
- System logs show Netlogon 5719, GroupPolicy 1058/1030/1129, and DNS 1014 in the same startup window, all consistent with domain name resolution failure.
- Affected machine lease shows DNS 10.10.3.250 (old server), while unaffected comparison machine has DNS 10.10.0.10 (current server).
- Multi-machine Floor 3 pattern strongly indicates subnet-level DNS assignment issue, not a user password issue.
- No declared change from user side aligns with infra-side DHCP scope drift.

Fastest confirm/eliminate check:
- On cthompson machine run ipconfig /all and verify DNS Servers; if old/decommissioned DNS is present instead of 10.10.0.10, this hypothesis is confirmed.

## 2) DNS suffix/search path mismatch preventing FQDN DC resolution

Why this fits the scope facts:
- Event 5719 explicitly references FINBRIDGE-DC01.finbridge.local lookup failure.
- Even with network up, wrong DNS suffix/search list can break domain locator and produce the same Netlogon/GPO chain.
- User-specific symptom can occur if cthompson always lands on one misconfigured endpoint.

Fastest confirm/eliminate check:
- Run ipconfig /all and verify Connection-specific DNS Suffix and Primary DNS Suffix include finbridge.local; if missing/incorrect, this remains a live cause.

## 3) Stale or incorrect static DNS on the specific endpoint/NIC profile used by cthompson

Why this fits the scope facts:
- One user affected can map to one device profile with stale static DNS even when other devices recover.
- Comparison host was manually corrected pre-migration, showing endpoint-level override is a known factor in this environment.
- No user-side change is consistent with persistent local adapter config drift.

Fastest confirm/eliminate check:
- Open adapter IPv4 settings and confirm DNS is set to obtain automatically or explicitly set to 10.10.0.10; any static old DNS confirms this path.

## 4) AD secure channel failure persisted after bad boot-time DNS assignment

Why this fits the scope facts:
- Netlogon 5719 indicates secure channel setup failure at startup.
- If the machine booted with bad DNS, secure channel can remain broken for login attempts until DNS/channel recovery.
- Produces login failures without any direct user credential change.

Fastest confirm/eliminate check:
- From elevated PowerShell run Test-ComputerSecureChannel; False confirms secure-channel break and keeps this as active cause.

## 5) Time sync skew on affected endpoint causing domain auth failures (lower probability)

Why this fits the scope facts:
- Kerberos/auth failures can present as login failures with no user change.
- Can coexist with domain reachability symptoms and be missed if focus stays only on DNS.
- Lower probability because provided logs point more strongly to DNS/DC discovery failure.

Fastest confirm/eliminate check:
- Run w32tm /query /status and compare local time offset to domain time; significant skew (for example greater than 5 minutes) supports this cause, otherwise eliminate.

## Working conclusion (not final root cause)

Based on current scope and event evidence, the leading hypothesis is DHCP-delivered old DNS for Floor 3 clients causing DC discovery and policy processing failures. This is not yet a committed root cause until endpoint DNS state is directly validated on cthompson’s machine and compared against a known-good host in the same subnet.
