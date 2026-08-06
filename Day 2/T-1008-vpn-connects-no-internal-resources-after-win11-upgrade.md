# T-1008

## Summary
VPN connects, but no internal resources are reachable after a Windows 11 upgrade.

## Impact
Known affected users/devices: 1 user/device confirmed; wider impact across other upgraded devices or VPN users: to-verify. Business urgency: high if the user cannot reach core internal applications, file shares, or line-of-business services needed for work.

## Known Facts
- Ticket reference: T-1008
- The VPN connection establishes successfully.
- After connection, internal resources are not reachable.
- The issue is reported after a Windows 11 upgrade.
- Whether all internal resources fail or only selected services fail is to-verify.
- Whether internet access continues normally while VPN is connected is to-verify.
- Whether the issue affects one network location or all networks is to-verify.
- Whether the problem started immediately after the Windows 11 upgrade is to-verify.

## Missing Information to Gather
- User identity, device name, and business impact through approved records.
- Which internal resources are affected: intranet, file shares, remote desktop targets, internal websites, or all of them.
- Whether the user can reach internal resources by name, by saved shortcut, or not at all.
- Whether the issue occurs on home Wi-Fi, mobile hotspot, office network, or all connection types.
- Whether other users on the same VPN service are affected.
- Whether the VPN client version or configuration changed during the Windows 11 upgrade.
- Whether internet access remains available while the VPN is connected.
- Whether the device can reach any internal resource from another endpoint or network: to-verify.
- Whether DNS-related symptoms are present, such as name resolution failures, is to-verify.
- Whether the user has restarted after the upgrade and after VPN client updates: to-verify.

## Likely Category
Remote Access / VPN / Windows 11 Post-Upgrade Connectivity

## First Diagnostic Step
Determine whether the failure is broad connectivity or name-resolution specific by asking the user to test multiple internal resources after the VPN connects and confirm whether internet access still works at the same time; this quickly narrows the issue to general VPN routing/connectivity versus access to particular internal services.
