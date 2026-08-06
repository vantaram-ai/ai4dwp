# Service Desk Triage Summary

## Summary (one line)
New Windows 11 laptop is reported as very slow since this morning, with Outlook not opening and spinning, while other apps are reportedly mostly OK (to confirm).

## Impact (who/how many/business urgency)
- Affected user count: 1 user reported.
- Scope: Single endpoint (new Windows 11 machine from last week).
- Business urgency: to confirm.

## Known facts
- User reports the laptop is "really slow" since this morning.
- Outlook "cant open" and "just spins."
- User reports other apps are "ok i think" (to confirm).
- Device is a new Windows 11 machine issued last week.

## Missing information to gather
- User identity, team, and contact details (to confirm).
- Exact start time and whether issue is constant or intermittent (to confirm).
- Whether Outlook eventually opens after waiting, and any error message/code (to confirm).
- Whether Outlook issue affects only this user profile or all profiles on the device (to confirm).
- Whether web Outlook (OWA) works (to confirm).
- Device connectivity status (network/VPN) and current location (office/home) (to confirm).
- Current CPU, memory, disk usage and top consuming process when Outlook is spinning (to confirm).
- Recent changes today: updates, new software, policy pushes, restarts (to confirm).
- Free disk space and device health state (to confirm).
- Whether other Office apps are normal on this device (to confirm).

## Likely category
- Endpoint performance degradation with application-specific failure (Outlook hang) on Windows 11.

## Suggest first diagnostic step
- On the affected device, capture Task Manager performance and process view while reproducing the Outlook spin (CPU, memory, disk, and Outlook process behavior), then launch Outlook in safe mode to confirm whether the hang is add-in/profile related (to confirm).
