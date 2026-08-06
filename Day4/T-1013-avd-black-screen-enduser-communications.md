# AVD Incident Communications - Three Audiences

Date: 2026-08-06  
Incident: AVD black screen post-login (POOL-FIN)

## Audience 1 - Non-technical executive

Your access and data are safe. Around 07:00, about 40% of users in POOL-FIN-01 saw a black screen after sign-in (sometimes clearing in about 30 seconds), while POOL-FIN-02 was unaffected. The issue followed a 02:00 overnight update applied only to POOL-FIN-01. We isolated affected systems, shifted sign-ins to POOL-FIN-02, fixed the display component on POOL-FIN-01, and fully restored service by 10:00 with successful logins verified. No action is needed unless the issue returns.

## Audience 2 - Affected end-user team

Around 07:00, after a 02:00 overnight update to POOL-FIN-01 only, about 40% of POOL-FIN-01 users saw a black screen after sign-in (sometimes clearing in about 30 seconds) while POOL-FIN-02 users were unaffected; we isolated affected systems, shifted sign-ins to POOL-FIN-02, fixed the display component in POOL-FIN-01, and fully restored service by 10:00 with successful logins verified.
If you see this again, sign out and sign back in once, then contact the Service Desk.

## Audience 3 - Engineer-to-engineer internal note

Incident facts:
- Onset about 07:00.
- Blast radius about 40% of users on POOL-FIN-01.
- POOL-FIN-02 unaffected.
- Preceding change: 02:00 overnight image update to POOL-FIN-01 only.
- Symptom: post-logon black screen, some clearing around 30s, others persisting/disconnecting.
- Recovery confirmed at 10:00; users verified logging into POOL-FIN-01 with no further reported issues.

Root cause:
- Graphics stack regression introduced by updated POOL-FIN-01 image.
- Evidence chain on affected host SHFIN-01-A:
  - Event 21 logon success at 07:02:10, 07:02:44, 07:03:10.
  - Event 1000 at 07:02:16, 07:02:46, 07:08:24: dwm.exe faulting in igdumd64.dll, exception 0xc0000005.
  - Event 9009 at 07:02:18 and 07:03:01: DWM exited (0x40010004).
  - Event 40 at 07:02:17 and 07:02:47: session disconnect.
- Comparison host SHFIN-02-A (unaffected pool): Event 9011 at 07:01:46 DWM started successfully; no Event 1000 in window.

Exact action taken:
- Containment: drained/controlled placement on POOL-FIN-01; shifted user sign-ins to POOL-FIN-02.
- Mitigation/remediation on POOL-FIN-01: applied GPU-path mitigation (including disabling hardware encode path temporarily), corrected graphics driver path via rollback/fix, and updated image/host baseline accordingly.
- Reopened traffic after host validation.

Config detail captured:
- Faulting app: dwm.exe version 10.0.22621.2861.
- Faulting module: igdumd64.dll version 31.0.101.4146.
- Exception: 0xc0000005.

Verification step:
- Operational: by 10:00, verified users could log in to POOL-FIN-01.
- Technical: no continuing correlated burst of Event 1000 (dwm.exe + igdumd64.dll) with Event 9009/Event 40 post-fix checks.

Preventive actions required:
- Add image canary stage with scripted post-logon render stability checks.
- Enforce A/B pool comparison gate before full promotion.
- Add alerting for Event 1000 signature (dwm.exe + igdumd64.dll) and correlated disconnect pattern.
- Keep known-good graphics driver pin/rollback package in baseline and use phased ring deployment for image rollout.
