# Service Desk Triage Summary

## Summary (one line)
User cannot connect to VDI today, receives a "cannot connect" message, and reports it was working on Friday.

## Impact (who/how many/business urgency)
- Who: Single reporting end user (to confirm).
- How many: 1 reported user.
- Business urgency: to confirm.

## known facts
- User reports they "cant get on the vdi thing today."
- Error shown is "cannot connect."
- User states VDI access worked on Friday.
- User is working from home on Wi-Fi.

## Missing information to gather
- Exact VDI platform/service name and login URL (to confirm).
- Exact timestamp the issue started today (to confirm).
- Full error text/code or screenshot of the "cannot connect" message (to confirm).
- Whether any other users are currently affected (to confirm).
- Whether user can access other corporate services from home connection (to confirm).
- Whether VPN is required for this VDI and current VPN status (to confirm).
- Device type/OS used to connect and whether it is DWP-managed (to confirm).
- Whether reboot of device/router and retry has been attempted (to confirm).
- Whether issue occurs on alternative network (for example mobile hotspot) (to confirm).

## likely catagory
- Remote access / VDI connectivity failure from home network (single user reported).

## Suggest first diagnostic step
- Capture the exact "cannot connect" message and verify VPN/session prerequisites, then run a basic connectivity check from the user device to the VDI login endpoint to confirm whether this is local network path, VPN, or service-side access failure (to confirm).
