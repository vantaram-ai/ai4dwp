# AVD Incident Analysis - Black Screen Post-Login (POOL-FIN)

Date: 2026-08-06  
Analyst: DWP Engineering

## Scope Facts Used
- Symptom: Black screen post-login; clears after ~30s for some users, persists for others.
- Who: ~40% of users on POOL-FIN-01 impacted; POOL-FIN-02 completely unaffected.
- Since: ~07:00 this morning.
- Change: Overnight image update to POOL-FIN-01 at 02:00; POOL-FIN-02 not updated.

## Explicit Timing/Control Weighting
The strongest discriminator is the A/B control:
- POOL-FIN-01 changed and is impacted.
- POOL-FIN-02 did not change and is not impacted.

This makes image-linked causes materially more likely than generic platform/network causes.

## Most Consistent Cause With the POOL-FIN-02 Clue
Most consistent single cause: an image-introduced regression in the POOL-FIN-01 logon path (shell/profile initialization sequence).

Reason: it cleanly explains both boundaries at once (changed pool affected, unchanged pool unaffected) and also matches mixed outcomes (30s clear for some, persistent for others).

## Re-Ranked Hypotheses (Most Probable First)

1) Image-specific logon shell/startup regression in POOL-FIN-01
- Why this fits scope facts:
  - Direct temporal linkage to 02:00 image update.
  - Clean pool isolation: only updated pool affected.
  - Mixed symptom behavior aligns with startup race/timeout variability.
- Single fastest check:
  - Compare time-to-interactive-desktop for the same test pattern on one FIN-01 host vs one FIN-02 host; if delay/black screen is FIN-01-only, this is strongly supported.

2) FSLogix profile attach delay/failure caused by new image components/config
- Why this fits scope facts:
  - Also tightly image-bound and pool-specific.
  - Explains 30s recoveries (slow attach) and persistent black screen (attach failure).
- Single fastest check:
  - Compare FSLogix attach success/latency at sign-in for affected FIN-01 users vs FIN-02 users.

3) Display/GPU driver regression introduced in FIN-01 image
- Why this fits scope facts:
  - Pool-isolated after image update is consistent.
  - Black screen then recovery can occur with driver reset/retry.
- Single fastest check:
  - Compare graphics driver versions and display reset events between affected FIN-01 hosts and FIN-02 hosts.

4) Logon policy/script processing regression due to image baseline changes
- Why this fits scope facts:
  - Still compatible with image-only impact.
  - ~30s pattern may match policy/script timeout windows.
- Single fastest check:
  - Capture sign-in phase timing and verify whether shell appears only after script/policy completion or timeout on FIN-01.

5) Faulty subset within FIN-01 host rollout (mixed quality/version slice)
- Why this fits scope facts:
  - ~40% affected can map to specific bad hosts.
  - Remains consistent with update-only pool impact.
- Single fastest check:
  - Correlate incidents by session host; strong clustering on specific FIN-01 hosts/image instances supports this.

## Positioning
This is a ranked differential, not a final root-cause claim. No single cause is committed yet.

---

## Incident Update - Event Evidence Assessment (2026-08-06)

### Evidence Window Reviewed
- Affected host: SHFIN-01-A, Application + System logs, 07:00-07:30
- Comparison host: SHFIN-02-A (POOL-FIN-02 unaffected), same window

### Per-Hypothesis Judgement Using Event Evidence

1) Image-specific logon shell/startup regression in POOL-FIN-01  
Judgement: Contradicts
- Determining events:
  - 07:02:16, Application Error Event 1000: dwm.exe faulting module igdumd64.dll (0xc0000005)
  - 07:02:18, Desktop Window Manager Event 9009: DWM exited with code 0x40010004
  - 07:02:17, TerminalServices-LocalSessionManager Event 40: session disconnected
- Rationale:
  - Failure chain is explicit DWM/graphics crash behavior, not a generic shell-start delay signature.

2) FSLogix profile attach delay/failure caused by new image components/config  
Judgement: Contradicts
- Determining events:
  - 07:02:10, 07:02:44, 07:03:10, TerminalServices-LocalSessionManager Event 21: session logon succeeded
  - 07:02:16 and 07:02:46, Application Error Event 1000: immediate dwm.exe/igdumd64.dll crash sequence
- Rationale:
  - Successful logon followed by repeated graphics-process fault is not the expected primary FSLogix attach-failure pattern in this evidence slice.

3) Display/GPU driver regression introduced in FIN-01 image  
Judgement: Supports
- Determining events:
  - 07:02:16, 07:02:46, 07:08:24, Application Error Event 1000: dwm.exe faulting module igdumd64.dll v31.0.101.4146
  - 07:02:18 and 07:03:01, Desktop Window Manager Event 9009: DWM exited with error
  - 07:01:46 on SHFIN-02-A, Desktop Window Manager Event 9011: DWM started successfully; no Application Error Event 1000 in window
- Rationale:
  - Repeated DWM crashes in the Intel graphics user-mode driver on affected host, absent on unaffected pool host, directly matches black-screen/disconnect behavior.

4) Logon policy/script processing regression due to image baseline changes  
Judgement: Contradicts
- Determining events:
  - 07:02:10, Event 21 succeeded, then 07:02:16 Event 1000 and 07:02:17 Event 40
  - Pattern repeats at 07:02:44 to 07:02:47 with same crash-disconnect chain
- Rationale:
  - Immediate crash-led disconnect pattern is inconsistent with policy/script timeout gating.

5) Faulty subset within FIN-01 host rollout (mixed quality/version slice)  
Judgement: Neutral
- Determining events:
  - 07:02:14, Kernel-General Event 1 confirms post-update reboot at 02:03:11
  - SHFIN-01-A shows repeated crash chain; SHFIN-02-A remains clean in the same window
- Rationale:
  - Confirms this host is faulty after update, but does not alone prove whether all FIN-01 hosts or only a subset are affected.

## Surviving Hypothesis After Elimination
Display/GPU driver regression introduced by the POOL-FIN-01 image update, specifically DWM crashing in Intel graphics module igdumd64.dll during user session initialization.

## Detailed Resolution Steps

1) Immediate containment
- Put POOL-FIN-01 session hosts into drain mode to stop new user placements.
- Route user capacity to POOL-FIN-02 where available.
- Move impacted active users to healthy hosts.

2) Confirm scope across FIN-01 hosts
- Query all FIN-01 hosts for Event 1000 (dwm.exe + igdumd64.dll), Event 9009, and near-time Event 40 after Event 21.
- Build host-level incident counts (first seen, last seen, count) to determine all-host vs subset-host spread.

3) Fast mitigation to restore usability
- Temporarily disable GPU acceleration path for remote sessions on FIN-01.
- Temporarily disable hardware AVC encoding for RDP sessions.
- Reboot one pilot host and validate sign-in behavior before broad rollout.

4) Driver rollback/fix
- Identify installed Intel graphics package/version on impacted FIN-01 hosts.
- Roll back to known-good driver baseline aligned with pre-update behavior.
- If rollback unavailable, deploy vendor-approved stable driver and prevent automatic replacement during incident.
- Reboot remediated hosts and retest.

5) Golden image correction
- Remove problematic graphics driver from FIN-01 master image.
- Install validated driver baseline and republish image.
- Reimage/redeploy FIN-01 hosts in controlled waves.

6) Validation gates before returning pool to normal
- No new Event 1000 signatures for dwm.exe/igdumd64.dll during observation window.
- No recurring Event 9009 plus Event 40 chain after Event 21 logon.
- User black-screen reports return to normal baseline.

7) Controlled reopen
- Remove drain mode in phased batches as each host clears validation.
- Reintroduce any temporary GPU-related policy changes incrementally with monitoring.

8) Post-incident hardening
- Add canary validation in image pipeline for DWM stability after login.
- Add alerting for Event 1000 signature bursts and correlated session disconnect patterns.
- Require pool A/B comparison in image promotion approvals.
