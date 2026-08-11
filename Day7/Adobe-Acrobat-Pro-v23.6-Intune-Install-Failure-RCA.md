# Adobe Acrobat Pro v23.6 - Intune Install Failure RCA

**Author:** DWP Engineer  
**Date:** 2026-08-11  
**Incident Type:** Intune Win32 app deployment failure  
**Status:** RCA based on supplied install log excerpt

---

## 1) Executive Summary

Adobe Acrobat Pro v23.6 failed to install through Intune on the affected endpoint(s). The supplied evidence confirms two separate issues in the deployment flow: the installer failed twice under SYSTEM context with return code `1603`, and the detection rule checked a registry path for **Adobe Acrobat Reader** rather than the deployed product **Adobe Acrobat Pro**.

Based on the supplied data alone, the exact underlying MSI failure reason for `1603` is not proven. However, the deployment configuration is clearly not in a healthy state because the application package, product name, and detection target are inconsistent.

---

## 2) Scope and Impact

### Scope
- Affects the Intune Win32 deployment of **Adobe Acrobat Pro v23.6** packaged as `AdobeAcrobatPro.intunewin`.
- Observed in SYSTEM install context.
- At least two install attempts failed on the same retry cycle.

### Business Impact
- Application was not installed.
- Intune marked the deployment as failed and scheduled retry.
- Repeated retries would continue to consume deployment time until the package configuration or install failure is corrected.

---

## 3) Supporting Evidence

### Install workflow evidence
- `[2024-03-15 10:01:00] AgentExecutor   Starting app install: Adobe Acrobat Pro v23.6`
- `[2024-03-15 10:01:01] AppInstaller    Install context: SYSTEM`
- `[2024-03-15 10:01:02] AppInstaller    Package: AdobeAcrobatPro.intunewin`
- `[2024-03-15 10:01:03] AppInstaller    Install command: msiexec /i AcrobatPro.msi /quiet`

### Failure evidence
- `[2024-03-15 10:01:44] AppInstaller    Return code: 1603`
- `[2024-03-15 10:01:44] AppInstaller    Install failed. Return code 1603.`
- `[2024-03-15 10:01:47] AgentExecutor   App install result: Failed`
- `[2024-03-15 10:01:47] AgentExecutor   Retry scheduled: 60 minutes`
- `[2024-03-15 11:01:47] AgentExecutor   Retry attempt 1: Adobe Acrobat Pro v23.6`
- `[2024-03-15 11:02:31] AppInstaller    Return code: 1603`
- `[2024-03-15 11:02:32] AgentExecutor   Retry 1 failed. Next retry: 60 minutes`

### Detection rule evidence
- `[2024-03-15 10:01:45] DetectionRule   Running detection: registry check`
- `[2024-03-15 10:01:45] DetectionRule   Key: HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0`
- `[2024-03-15 10:01:45] DetectionRule   Value: not found`
- `[2024-03-15 10:01:46] DetectionRule   Detection result: Not detected`

### Evidence interpretation
- The package being deployed is **Adobe Acrobat Pro**, but the detection rule targets **Adobe Acrobat Reader**.
- The installer failed before detection could succeed, and detection then confirmed the targeted key was not found.
- The same failure pattern repeated on the next retry, which indicates the problem is persistent rather than transient.

---

## 4) Timeline

1. **2024-03-15 10:01:00** - Intune agent started install for Adobe Acrobat Pro v23.6.
2. **2024-03-15 10:01:01** - Install context confirmed as SYSTEM.
3. **2024-03-15 10:01:03** - Installer launched with `msiexec /i AcrobatPro.msi /quiet`.
4. **2024-03-15 10:01:44** - Installer returned `1603`; install marked failed.
5. **2024-03-15 10:01:45 to 10:01:46** - Detection rule checked `HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0`; value not found; result `Not detected`.
6. **2024-03-15 10:01:47** - App result recorded as Failed; retry scheduled for 60 minutes.
7. **2024-03-15 11:01:47** - Retry attempt 1 started.
8. **2024-03-15 11:02:31** - Retry attempt returned `1603` again.
9. **2024-03-15 11:02:32** - Retry 1 failed; next retry scheduled.

---

## 5) Root Cause Statement

The supplied evidence confirms a deployment configuration defect in the Intune app definition: the detection rule targets a registry path for **Adobe Acrobat Reader 23.0** while the deployed package is **Adobe Acrobat Pro v23.6**. In parallel, the installer itself failed twice with return code `1603` under SYSTEM context, so the deployment could not complete.

From the provided log excerpt alone, the exact internal MSI reason for `1603` cannot be proven. Therefore, the verified RCA is that the deployment was blocked by a failed install attempt and an app configuration mismatch that would also prevent reliable detection.

---

## 6) 5-Whys Analysis

### Problem
Adobe Acrobat Pro v23.6 did not install successfully from Intune.

### Why 1
Why did the app not install successfully?  
Because Intune recorded the install as failed after `msiexec /i AcrobatPro.msi /quiet` returned `1603` twice.

### Why 2
Why did Intune continue to show the app as not installed?  
Because the detection rule checked `HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0` and did not find the expected value.

### Why 3
Why was the detection rule checking a Reader registry path for a Pro deployment?  
Because the app configuration used a detection target that did not match the product being deployed.

### Why 4
Why was a mismatched detection rule allowed into the deployment?  
Because package configuration validation did not catch the mismatch between application name, installer, and detection rule before assignment.

### Why 5
Why was configuration validation not catching this before rollout?  
Because the deployment process lacked a mandatory pre-assignment quality gate to verify install command success and detection rule alignment on a test device.

### 5-Whys conclusion
Immediate cause: installer failed with `1603` and the configured detection rule did not match the application being deployed.  
Process cause: insufficient packaging QA before deployment assignment.

---

## 7) Confirmed Facts vs Unknowns

### Confirmed
- Install attempted under SYSTEM context.
- Install command used: `msiexec /i AcrobatPro.msi /quiet`.
- Return code `1603` occurred twice.
- Detection rule checked `HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0`.
- Detection result was `Not detected`.

### Not proven by supplied evidence alone
- The precise MSI internal failure reason behind `1603`.
- Whether the detection rule mismatch alone would have caused a false failure after a successful install.
- Whether additional prerequisites, file issues, or product conflicts exist on the endpoint.

---

## 8) Preventive Actions

1. Add a mandatory packaging validation checklist before assignment:
   - app name matches installer content
   - detection rule matches deployed product and version
   - install and uninstall commands are tested on a pilot device
2. Require a pre-pilot Intune review for all Win32 apps:
   - program settings
   - detection rules
   - return codes
   - install context
3. Capture verbose MSI logging during packaging validation so generic failures such as `1603` can be traced before production assignment.
4. Do not promote an app beyond pilot until one clean install and one clean detection cycle are confirmed on a test device.

---

## 9) Recommended Next Technical Checks

These are follow-up diagnostics, not part of the proven RCA:

1. Review the Intune app detection rule and correct it to the actual Adobe Acrobat Pro product/version registry location.
2. Re-run the MSI manually in a controlled test with verbose logging enabled to identify the exact reason for `1603`.
3. Confirm whether Acrobat Pro and Acrobat Reader use different registry paths in the packaged version being deployed.
4. Validate uninstall/upgrade behavior if Adobe Acrobat Pro v23.6 is intended to replace an earlier build.

---

## 10) Closure

The available evidence supports a configuration-related deployment failure: Adobe Acrobat Pro v23.6 was deployed with a mismatched Reader detection rule, and the installer failed twice with `1603`. The immediate corrective focus should be detection-rule correction plus controlled MSI-level validation before further rollout.