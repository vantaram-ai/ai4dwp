Engineer note:
Root cause:
- Win11 upgrade removed legacy VPN client.
- Intune did not re-deploy new VPN client due to a detection-rule gap.

Exact action taken:
- Manually removed stale VPN registry entries under HKLM\SOFTWARE\<vendor>.
- Force-triggered Intune sync.
- New VPN client deployed.
- Split-tunnel config applied.

Config detail:
- Registry cleanup path: HKLM\SOFTWARE\<vendor>
- VPN mode/config applied: split-tunnel

Verification step:
- Confirmed connectivity to all internal subnets.
- No data loss.

Preventive action needed:
- Fix/close the Intune app detection-rule gap so Win11-upgraded endpoints auto-trigger re-deployment of the new VPN client.