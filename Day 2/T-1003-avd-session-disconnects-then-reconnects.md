# T-1003

## Summary
AVD session disconnects after about 10 minutes and then reconnects.

## Impact
Known affected users: 1 user/session confirmed; wider impact across additional users, hosts, or pools: to-verify. Business urgency: medium to high, because repeated disconnects interrupt active work and can affect productivity, call handling, or time-sensitive case processing depending on the user's role.

## Known Facts
- Ticket reference: T-1003
- The issue affects an AVD session.
- The session reportedly disconnects after about 10 minutes.
- The session then reconnects.
- Whether the issue affects one user, multiple users, or a full host pool is to-verify.
- Whether the disconnect timing is consistent or approximate is to-verify.
- Whether the issue occurs on all networks, all devices, or one device is to-verify.
- Any visible message shown at disconnect or reconnect is to-verify.

## Missing Information to Gather
- User identity, location, and contact details through approved service desk records.
- AVD workspace, host pool, and affected application or full desktop session.
- Exact start time, frequency, and whether the 10-minute pattern is repeatable.
- Whether the issue affects one user, a subset of users, or all users on the same host pool.
- Whether the user is on home, office, VPN, Wi-Fi, or wired network when the issue occurs.
- Whether the problem occurs from one endpoint only or from multiple endpoints.
- Exact error text, disconnect banner, or screenshot through approved channels.
- Whether the user remains signed in to other network services when the AVD session drops.
- Whether recent changes occurred to client version, network path, host pool settings, or session policies: to-verify.
- Whether session activity is idle or active at the point of disconnect.

## Likely Category
Virtual Desktop / AVD / Session Stability

## First Diagnostic Step
Determine whether this is user-specific, endpoint-specific, or host-pool-wide by checking if other users on the same AVD host pool are seeing similar 10-minute disconnects and confirming whether the affected user reproduces the issue from a different network or endpoint; this quickly separates a broader AVD service issue from a local connectivity or client problem.
