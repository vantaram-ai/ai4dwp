# Finbridge Startup Performance Drop: Likely Cause Analysis

Date: 2026-08-12
Scope: Finance-Win11 startup performance drop beginning 2026-08-04

## Ranked Most Likely Causes

### 1. New startup script added by the security baseline is delaying sign-in completion
Why it fits the evidence:
- The degradation starts exactly on 2026-08-04, the same date the new security baseline was deployed at 02:00.
- The change log explicitly says a startup script for compliance logging was added, which directly aligns to slower startup timing.
- The affected group is Finance-Win11 only, and the unaffected IT-Win11 comparison group had no config change and stayed stable, which strongly supports a change local to the Finance deployment.
- The shift is immediate and sustained, which matches a script introduced broadly to the whole device group.

Fastest check to confirm or eliminate it:
- On one affected device, temporarily disable or bypass the new startup script assignment and compare next startup time against a similarly affected device that still has the script.

### 2. Additional Defender scan policy introduced by the new baseline is increasing startup overhead
Why it fits the evidence:
- The change log shows an additional Defender scan policy was deployed at the same time as the performance drop.
- Security scan changes can affect startup duration across all devices in a targeted group, which matches the broad and consistent increase in median startup time.
- The unaffected IT-Win11 group did not receive the config change and did not show the same startup slowdown, which strongly points back to the Finance-only baseline changes.
- The score drop remains depressed for multiple days, which is consistent with a persistent policy effect rather than a one-off event.

Fastest check to confirm or eliminate it:
- Compare Defender policy and scan activity on one affected Finance device before and after sign-in, then temporarily remove the added scan policy from a small pilot subset and measure the next startup.

### 3. Combined effect of both baseline components causing cumulative startup delay
Why it fits the evidence:
- Both documented changes were deployed together at 02:00 on 2026-08-04, and the startup slowdown begins immediately afterward.
- The drop is large and sustained, which may fit a cumulative effect better than either change alone if both now run near startup.
- The unaffected comparison group is a clean control because it had no config change at all and stayed flat, which supports the deployment package itself as the differentiator.
- With only one affected group and two simultaneous baseline changes, the package as a whole remains a strong candidate until each component is isolated.

Fastest check to confirm or eliminate it:
- Roll back the full 2026-08-04 baseline from a small controlled subset of Finance-Win11 devices and compare their next startup results with devices that keep the full baseline, then reintroduce each component separately if needed.

## Summary
The strongest evidence points to the 2026-08-04 Finance-only security baseline deployment, with the startup script as the most likely single cause, the added Defender scan policy second, and the combined package effect third until isolated testing proves otherwise.
