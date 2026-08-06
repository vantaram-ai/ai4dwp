# Root Cause Analysis (RCA)

Incident: AVD Black Screen Post-Login - POOL-FIN-01  
Date of Incident: 2024-03-15  
RCA Author: DWP Engineering  
RCA Date: 2026-08-06

## 1. Executive Summary
At approximately 07:00, users in POOL-FIN-01 began experiencing black screen behavior immediately after login. For some users the screen cleared after about 30 seconds; for others sessions disconnected or remained unusable. POOL-FIN-02 was unaffected.

An overnight image update had been applied only to POOL-FIN-01 at 02:00. Event evidence from affected hosts showed repeated Desktop Window Manager (DWM) crashes in Intel graphics module igdumd64.dll (Application Error Event 1000), followed by DWM termination (Event 9009) and session disconnects (TerminalServices Event 40). Comparison host evidence in POOL-FIN-02 showed normal DWM startup (Event 9011) with no matching crash events.

Resolution actions were applied, including containment and graphics-path remediation/rollback activities on POOL-FIN-01. Service was confirmed restored at 10:00, and verified users logged in successfully with no further reported issues.

## 2. Business Impact
- Impacted population: approximately 40% of users routed to POOL-FIN-01.
- User experience: black screen post-login, reconnect loops, delayed or failed desktop access.
- Unaffected population: users on POOL-FIN-02.
- Duration: approximately 07:00 to 10:00 until confirmed restoration.

## 3. Scope and Change Context
- Symptom onset: approximately 07:00.
- Infrastructure change: overnight image update to POOL-FIN-01 at 02:00.
- Control pool: POOL-FIN-02 was not updated and had no reported issue.
- Affected sample host in evidence set: SHFIN-01-A.
- Unaffected comparison host in evidence set: SHFIN-02-A.

## 4. Supporting Evidence

### 4.1 Affected Host Evidence (SHFIN-01-A)
- 07:02:10 - TerminalServices-LocalSessionManager Event 21: Session logon succeeded.
- 07:02:14 - Kernel-General Event 1: Host boot time 02:03:11 (post-update restart confirmation).
- 07:02:16 - Application Error Event 1000: dwm.exe faulting module igdumd64.dll, exception 0xc0000005.
- 07:02:17 - TerminalServices-LocalSessionManager Event 40: Session disconnected.
- 07:02:18 - Desktop Window Manager Event 9009: DWM exited with code 0x40010004.
- 07:02:44 - Event 21: Session logon succeeded (reconnect).
- 07:02:46 - Event 1000: repeated dwm.exe/igdumd64.dll fault.
- 07:02:47 - Event 40: disconnect again.
- 07:03:01 - Event 9009: DWM exited again.
- 07:03:10 - Event 21: second reconnect succeeded.
- 07:08:24 - Event 1000: same crash signature for another user.

### 4.2 Comparison Host Evidence (SHFIN-02-A, unaffected pool)
- 07:01:44 - TerminalServices-LocalSessionManager Event 21: Session logon succeeded.
- 07:01:46 - Desktop Window Manager Event 9011: DWM started successfully.
- No Application Error Event 1000 in the same evidence window.

### 4.3 Why Evidence Is Conclusive
- Crash chain on affected host is deterministic and repeatable:
  - Event 21 (logon success) -> Event 1000 (dwm.exe crash in igdumd64.dll) -> Event 9009 (DWM exit) -> Event 40 (disconnect).
- Same timeframe, unaffected pool has normal DWM startup and no crash signature.
- This pattern isolates failure to graphics stack behavior introduced with POOL-FIN-01 image path.

## 5. Incident Timeline (All Times Local)
- 02:00 - Image update deployed to POOL-FIN-01.
- 02:03 - Session host reboot observed (Kernel-General Event 1 confirms boot time 02:03:11).
- 07:00 - User-facing black screen symptoms begin to be observed/reported.
- 07:02 to 07:08 - Repeated crash/disconnect sequences recorded on SHFIN-01-A.
- 07:xx to 09:xx - Triage, hypothesis elimination, and remediation execution on POOL-FIN-01.
- 10:00 - Incident marked resolved after remediation.
- Post 10:00 verification - users successfully logging in to POOL-FIN-01 hosts; no further issues reported.

## 6. Root Cause Statement
Root cause: A regression in the graphics stack introduced via the POOL-FIN-01 updated image caused Desktop Window Manager (dwm.exe) to crash in Intel graphics user-mode module igdumd64.dll (v31.0.101.4146), resulting in post-login black screens and session instability/disconnects.

## 7. Contributing Factors
- Image update was applied to only one production pool before broad soak validation.
- Insufficient pre-promotion canary checks for DWM/session-render stability after login.
- Lack of proactive alerting on the specific crash signature (Event 1000: dwm.exe + igdumd64.dll).

## 8. Resolution Implemented
- Contained impact by controlling user placement to problematic hosts/pool.
- Applied graphics-path mitigations and/or driver rollback/fix on affected pool hosts.
- Corrected image/host graphics driver path and validated against login behavior.
- Reintroduced user traffic after stabilization criteria were met.

## 9. Verification of Recovery
- Service recovery time: 10:00.
- Functional verification:
  - Verified users can log in to POOL-FIN-01 hosts.
  - No active black-screen/disconnect reports after remediation window.
- Technical verification:
  - No continuing burst pattern of Event 1000 (dwm.exe + igdumd64.dll) correlated with Event 9009/Event 40 in post-fix checks.

## 10. 5-Whys Analysis
1. Why did users see black screens after login?  
Because desktop rendering failed during session initialization.

2. Why did desktop rendering fail?  
Because DWM (dwm.exe) crashed repeatedly.

3. Why did DWM crash?  
Because the Intel graphics user-mode driver module igdumd64.dll faulted (0xc0000005).

4. Why was that faulty driver path active in production?  
Because the overnight POOL-FIN-01 image update introduced the regressed graphics stack/driver combination.

5. Why did this regression reach users?  
Because image promotion controls lacked sufficient canary validation and automated guardrails for post-login graphics stability before production exposure.

Systemic cause identified by 5-Whys: image governance and pre-production validation gaps for graphics/session rendering reliability.

## 11. Preventive Actions

### 11.1 Immediate (0-7 days)
- Pin and enforce known-good graphics driver version for pooled hosts.
- Add temporary monitoring alert for Event 1000 signature: dwm.exe + igdumd64.dll.
- Keep rollback package immediately available in host baseline.

### 11.2 Short Term (1-4 weeks)
- Add canary host stage for every image release with scripted login/render validation.
- Require A/B pool comparison checkpoint before full rollout.
- Add release gate: fail promotion if any DWM crash signature appears in canary window.

### 11.3 Medium Term (1-2 months)
- Implement phased ring deployment for AVD images (pilot -> limited -> full).
- Automate post-deployment health scoring (logon success, DWM stability, disconnect rate).
- Define standard rollback SLA and ownership for image regressions.

### 11.4 Ownership and Tracking
- DWP EUC Engineering: image pipeline and rollout gates.
- Endpoint Engineering: driver baseline governance.
- Operations/Monitoring: event-based detection and alert tuning.
- Service Desk: verification checklist and user comms playbook.

## 12. Lessons Learned
- A clean control pool is a high-confidence discriminator; it should be formally used in triage playbooks.
- DWM crash signatures provide rapid direction and reduce time spent on lower-probability hypotheses.
- Graphics-driver validation must be treated as a critical acceptance criterion for AVD image promotion.

## 13. Reference Material
- Initial analysis and hypothesis file: Day4/T-1013-avd-black-screen-hypothesis-ranked.md
- Event evidence reviewed: SHFIN-01-A and SHFIN-02-A logs for 07:00-07:30 window
