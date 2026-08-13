# Legal App Crash Wave - Cross-Source Analysis and RCA

**Author:** DWP Engineer  
**Analysis Date:** 2026-08-13  
**Incident Date:** 2024-03-25  
**Severity:** High  
**Status:** Closed - Root cause identified with high confidence

---

## 1) Executive Summary

Legal (Floor 6) reported a wave of application crashes across the Legal-Win11 device group on 2024-03-25. Analysis of the Nexthink DEX export alone shows a sharp user-experience degradation beginning at 10:00, but it does not explain why the issue started. Analysis of the SCCM deployment log alone shows a technically successful software rollout, but it does not show business impact.

When correlated together, the two sources point to a single causal chain:

**SCCM deployed Legal Document Manager v2.1 to all 45 Legal devices at 09:38-09:44, and within the next hourly DEX window the fleet showed a sharp rise in crashes, a large DEX score drop, and high disk I/O. The dominant crashing process was DocManager.exe, and the observed pattern matches the vendor's known limitation for v2.1 on devices with under 8GB RAM during initial auto-save index creation.**

The most likely root cause is **a post-install application defect/known limitation in Document Manager v2.1**, specifically its new auto-save indexing process on low-memory devices, not a failed SCCM deployment.

---

## 2) Scope Facts Established From Both Sources

### Source 1 - Nexthink DEX

- Device group: `Legal-Win11`
- Total devices in scope: `45`
- Baseline health before incident:
  - `08:00` DEX score `91`, app crash rate `0.1%`, disk I/O `Normal`
  - `09:00` DEX score `90`, app crash rate `0.2%`, disk I/O `Normal`
- Degraded health during incident:
  - `10:00` DEX score `58`, app crash rate `6.2%`, disk I/O `High`
  - `11:00` DEX score `55`, app crash rate `6.8%`, disk I/O `High`
- Top crashing process between `10:00-11:00`: `DocManager.exe`
- Contribution of top crashing process: `74%` of all crashes in that window

### Source 2 - SCCM Deployment

- Deployment start time: `09:38:20`
- Package deployed: `Legal Document Manager v2.1`
- Target collection: `Legal-Win11`
- Devices targeted: `45`
- Deployment completion time: `09:44:07`
- Install completion: `45 of 45 devices`
- Install result: `Success, 0 failures`
- Previous version: `Document Manager v2.0`
- Previous version state: `stable`, deployed `6 weeks ago`

### Package and Hardware Context

- Vendor change introduced in v2.1: `new auto-save feature`
- Vendor known limitation:
  - On devices with `under 8GB RAM`, the auto-save indexing process can cause `high disk I/O` and `intermittent crashes` during the first few hours after installation while the initial index builds.
- Legal-Win11 hardware mix:
  - `60%` of devices have `8GB RAM` = `27 devices`
  - `40%` of devices have `4GB RAM` = `18 devices`
- At-risk cohort under the vendor limitation threshold: `18 of 45 devices`

---

## 3) Correlation Analysis Across the Two Sources

Neither source is sufficient on its own:

- DEX proves the user-impact pattern, but not the triggering event.
- SCCM proves the software change event, but not whether that change harmed users.

The correlation between timing, affected process, and resource behavior is strong:

| Time | Source | Observed Event | Correlation Value |
|------|--------|----------------|-------------------|
| 08:00 | DEX | DEX 91, crash rate 0.1%, disk I/O normal | Healthy pre-change baseline |
| 09:00 | DEX | DEX 90, crash rate 0.2%, disk I/O normal | Still healthy immediately before rollout |
| 09:38:20 | SCCM | Deployment of Document Manager v2.1 started to Legal-Win11 | Change event introduced |
| 09:44:07 | SCCM | Install completed successfully on 45/45 devices | Full fleet exposure established |
| 10:00 | DEX | DEX dropped to 58, crash rate rose to 6.2%, disk I/O high | First fleet-wide degradation visible within 16 minutes of install completion |
| 10:00-11:00 | DEX | DocManager.exe responsible for 74% of crashes | Failing process directly matches deployed application |
| 11:00 | DEX | DEX 55, crash rate 6.8%, disk I/O still high | Condition persisted beyond initial onset |

### Correlated Interpretation

1. The fleet was healthy before the SCCM deployment.
2. A single application version change was introduced to all 45 devices at 09:38-09:44.
3. The first DEX degradation appears in the very next hourly measurement bucket at 10:00.
4. The process dominating the crash wave is the same application that was just upgraded: `DocManager.exe`.
5. DEX also records `High` disk I/O during the same period.
6. The vendor release note explicitly predicts `high disk I/O` plus `intermittent crashes` during the first few hours after installation on devices with under 8GB RAM.
7. The Legal fleet contains `18` such devices, which is a sufficiently large cohort to generate a visible fleet-level DEX event.

This is not a loose association. The time adjacency, process identity, and symptom match all align with the vendor's documented limitation.

---

## 4) Root Cause Statement

The crash wave was caused by the rollout of **Legal Document Manager v2.1** at `09:38-09:44` on 2024-03-25. Its new auto-save indexing feature triggered high disk I/O and intermittent crashes during the initial post-install indexing period, particularly on the `18` Legal devices with `4GB RAM` that fall under the vendor's documented risk condition of `under 8GB RAM`.

The SCCM deployment itself succeeded technically. The failure mode was **post-install application instability introduced by the new version**, not package delivery failure.

---

## 5) Why This Root Cause Fits Better Than Alternatives

### Confirmed supporting factors

- **Temporal fit**: degradation begins immediately after the 09:44 completion of the rollout.
- **Process fit**: `DocManager.exe` accounts for `74%` of crashes in the affected window.
- **Resource fit**: DEX shows `High` disk I/O, which directly matches the vendor limitation.
- **Change fit**: previous version `v2.0` was stable for `6 weeks`.
- **Exposure fit**: rollout reached `45 of 45` devices with `0 failures`, so all impacted devices received the new version.
- **Hardware fit**: `18` devices meet the exact vendor risk condition of `under 8GB RAM`.

### Less likely alternatives

- **SCCM deployment failure**: not supported because install result was `Success, 0 failures`.
- **Random unrelated app instability**: weakened by the fact that the top crashing process is the newly updated application.
- **Storage subsystem issue unrelated to the app**: weakened by the vendor note that specifically links the new feature to high disk I/O and crashes.
- **General device fleet degradation unrelated to the deployment**: weakened by the clean 08:00 and 09:00 DEX baseline and the abrupt post-deployment step change.

---

## 6) 5-Whys Analysis

### Problem
Legal users experienced a wave of application crashes on 2024-03-25.

### Why 1
Why did users experience a crash wave?  
Because application crash rate in Legal-Win11 rose from `0.2%` at `09:00` to `6.2%` at `10:00` and `6.8%` at `11:00`.

### Why 2
Why did the crash rate rise so sharply?  
Because `DocManager.exe` became the dominant crashing process, contributing `74%` of crashes from `10:00-11:00`.

### Why 3
Why did DocManager.exe start crashing in that window?  
Because `Document Manager v2.1` had just been deployed to all 45 devices by `09:44:07`, immediately before the DEX degradation began.

### Why 4
Why did v2.1 destabilize endpoints after installation?  
Because the new auto-save feature performs initial indexing that can drive high disk I/O and intermittent crashes during the first few hours after install.

### Why 5
Why did this behavior materially affect the Legal fleet?  
Because `40%` of the fleet (`18 devices`) has `4GB RAM`, which falls below the vendor's `under 8GB RAM` risk threshold, and the deployment was released to the full collection without a hardware-risk holdback.

### 5-Whys conclusion
Immediate technical cause: Document Manager v2.1 auto-save indexing instability on low-memory devices.  
Process/control cause: the deployment was not ringed or filtered against the vendor's known low-memory limitation before broad release.

---

## 7) Business Impact Assessment

- Affected business unit: `Legal`
- Location scope provided: `Floor 6`
- Fleet size in scope: `45 devices`
- User experience degradation was severe enough to drive DEX score from `90` to `58` within one hour, and then to `55` by the next hour.
- The issue was broad enough to present as a fleet-level incident rather than isolated single-device failures.
- The most likely highest-risk subset was the `18` devices with `4GB RAM`, though the deployment exposure covered all `45` devices.

---

## 8) Confirmed Non-Causes

The available evidence does not support the following as primary root causes:

- SCCM package delivery failure
- Partial deployment / failed installs
- Pre-existing instability in v2.0
- A generalized Windows storage issue unrelated to the new app build

---

## 9) Corrective Actions

### Immediate actions

1. Suspend further rollout of `Legal Document Manager v2.1` to any additional collections.
2. Prioritize rollback of the `18` devices with `4GB RAM` to `Document Manager v2.0`.
3. If broad business impact continues, roll back all `45` Legal devices to `v2.0`.
4. Disable the new auto-save feature in v2.1 if the vendor supports configuration-based mitigation.
5. Recheck DEX crash rate, DEX score, and disk I/O for the next 2 to 4 hourly windows after rollback or mitigation.

### Validation targets

1. App crash rate returns toward pre-change baseline of `0.1%` to `0.2%`.
2. DEX score recovers toward baseline near `90`.
3. Disk I/O returns from `High` to `Normal`.
4. `DocManager.exe` no longer dominates crash telemetry.

---

## 10) Preventive Actions

### Preventive Action 1 - Hardware-aware deployment rings
- Exclude low-memory endpoints from first-wave deployments when release notes identify memory-sensitive behavior.
- Use phased deployment to a pilot subset before a 45-device broad release.

### Preventive Action 2 - Release note gating
- Require engineering review of vendor known limitations before production deployment approval.
- Treat documented feature-risk conditions as deployment constraints, not informational notes.

### Preventive Action 3 - DEX and software-change correlation checks
- Add post-deployment monitoring checkpoints at 30, 60, and 120 minutes using DEX crash and disk I/O data.
- Trigger automatic rollback review if crash rate or DEX score crosses defined thresholds after rollout.

### Preventive Action 4 - Collection segmentation
- Split collections by device capability tiers such as `4GB`, `8GB`, and `16GB+` RAM to support safer release targeting.

---

## 11) Final Conclusion

Cross-source analysis shows that the Legal crash wave was **change-induced** and most likely caused by the deployment of `Document Manager v2.1`, not by an SCCM installation failure. The evidence is strongest because all three key dimensions align:

- **Timing**: the issue starts immediately after deployment completion.
- **Content**: the newly deployed application's process is the dominant crash source.
- **Behavior**: the DEX symptom pattern matches the vendor's documented limitation exactly, including `high disk I/O` during the first few hours after install.

Root cause is therefore assessed as **Document Manager v2.1 auto-save indexing instability on under-8GB devices, exposed by full-fleet deployment to Legal-Win11 without hardware-based rollout controls.**