# FinBridge Connect v3.1 - Phased Intune Rollout Plan

**Author:** DWP Engineer  
**Date:** 2026-08-11  
**Deployment window:** 3 weeks  
**Target deadline:** 2026-09-01  
**Application:** FinBridge Connect v3.1  
**Package type:** Win32 app (.intunewin)  
**Rollback package available:** FinBridge Connect v3.0  
**Detection rule:** Registry value `HKLM\SOFTWARE\FinBridge\Connect\Version = 3.1`

## 1. Ring Structure

### Ring 1 - Pilot

- **Size:** 100 devices
- **Duration:** 3 calendar days deployment, then 2 full days monitoring before promotion decision
- **Who to include:**
  - 30 IT and support-owned test devices
  - 40 Finance users who can provide fast feedback
  - 20 older-hardware devices (4 GB RAM)
  - 10 general business users on standard Win11 hardware
- **Purpose:**
  - Validate install command, uninstall command, detection rule, and Intune reporting
  - Prove the app works on both standard hardware and the known at-risk 4 GB RAM devices
  - Confirm that rollback to v3.0 remains viable before exposing a larger business group
- **Intune assignment group type:** Microsoft Entra security group using **device-based membership**, assigned as **Required**

### Ring 2 - Early

- **Size:** 1,400 devices
- **Duration:** 4 calendar days deployment, then 3 full days monitoring before promotion decision
- **Who to include:**
  - Remaining 460 Finance users so the full 500-user Finance cohort is completed by end of week 1
  - 640 standard-hardware business users from non-finance teams
  - 300 additional older-hardware devices (4 GB RAM) to expand low-spec coverage in a controlled way
- **Purpose:**
  - Meet the Finance deadline within week 1
  - Validate deployment at business scale and confirm support demand remains manageable
  - Increase confidence that low-spec devices do not create a fleet-wide failure pattern
- **Intune assignment group type:** Microsoft Entra security group using **device-based membership**, assigned as **Required**

### Ring 3 - Broad

- **Size:** 8,500 devices
- **Duration:** Remaining deployment window through 2026-09-01
- **Who to include:**
  - All remaining standard-hardware Win11 endpoints
  - Remaining older-hardware endpoints only after Ring 2 low-spec results meet gate criteria
- **Purpose:**
  - Complete full-fleet rollout within the 3-week deadline
  - Sequence the lowest-risk devices first, then finish with the remaining low-spec population once stability is proven
- **Intune assignment group type:** Microsoft Entra security groups using **device-based membership**, assigned as **Required**, split into manageable deployment batches if needed for operational control

## 2. Advance Criteria

### Ring 1 to Ring 2

Evaluate only after the full Ring 1 population has had **2 full days** to install and report status.

- **Install success rate to advance:** at least **95% Installed** in Intune device install status within the monitoring window
- **Error rate threshold to still advance:** no more than **3% Failed** in Intune device install status
- **User-reported issue threshold to still advance:** no more than **2 tickets per 100 targeted users/devices** during the same 2-day monitoring window
- **Monitoring period:** minimum **48 hours** after the last Ring 1 device receives the assignment

How to measure:
- Use **Intune app -> Device install status** for Installed and Failed counts
- Use Service Desk tickets tagged **FinBridge Connect v3.1** for user issue rate

Note on observability:
- User ticket volume is not observable in Intune reporting. Use the Service Desk queue as the control source for that metric while keeping install/error decisions anchored to Intune reporting.

### Ring 2 to Ring 3

Evaluate only after the full Ring 2 population has had **3 full days** to install and report status.

- **Install success rate to advance:** at least **97% Installed** in Intune device install status within the monitoring window
- **Error rate threshold to still advance:** no more than **2% Failed** in Intune device install status
- **User-reported issue threshold to still advance:** no more than **1 ticket per 100 targeted users/devices** during the same 3-day monitoring window
- **Monitoring period:** minimum **72 hours** after the last Ring 2 device receives the assignment

How to measure:
- Use **Intune app -> Device install status** for Installed and Failed counts
- Use Service Desk tickets tagged **FinBridge Connect v3.1** for user issue rate

### Hold Condition (Pause Without Full Rollback)

Pause the next ring without rolling back the current ring if either of the following occurs during the monitoring window:
- **Failure rate exceeds the threshold but remains below 10%**, or
- **A concentrated issue appears in a specific cohort** such as older-hardware devices, even if fleet-wide success rate is still above target

**Specific example:**
- Ring 2 overall install success is 97.5%, but 4 GB RAM devices show **8% Failed** and generate repeated slowness tickets. In that case, hold Ring 3 for the low-spec population only, investigate requirements fit and performance, and continue broad deployment only for standard-hardware devices if separately approved.

## 3. Deployment Calendar

- **2026-08-11 to 2026-08-13:** Ring 1 deployment
- **2026-08-14 to 2026-08-15:** Ring 1 monitoring and promotion decision
- **2026-08-15 to 2026-08-18:** Ring 2 deployment, including remaining Finance users
- **2026-08-19 to 2026-08-21:** Ring 2 monitoring and promotion decision
- **2026-08-22 to 2026-09-01:** Ring 3 deployment and controlled completion

## 4. Operational Notes

- Keep FinBridge Connect v3.0 available in Intune for rollback throughout all three rings.
- Do not include the full 500-device low-spec population in Ring 2 unless Ring 1 low-spec results are within thresholds.
- If Ring 1 shows low-spec instability, move only standard-hardware Finance devices into Ring 2 first and hold the at-risk hardware subset for separate review.
- Use the existing registry detection rule consistently across all rings so Installed status means the same thing throughout the rollout.