# Windows 11 Intune Compliance Policy – Security Baseline Translation
**Authored by:** DWP Engineer  
**Date:** 2026-08-10  
**Scope:** Windows 11 managed devices enrolled in Microsoft Intune  
**Grace Period:** 7 days applied to all settings  

---

## How to Apply the Grace Period

In the Intune portal, when creating or editing the compliance policy:

> **Microsoft Intune admin center** → Devices → Compliance → Policies → [Your Policy] → **Properties** → Compliance settings → *Actions for noncompliance*

Set **"Mark device noncompliant"** action to **7 days** after noncompliance is detected. Apply this to every action in the list.

---

## Requirement 1 – BitLocker Must Be Enabled on the OS Drive

| Field | Detail |
|---|---|
| **Settings Name** | `Require BitLocker` |
| **Value** | `Require` |
| **UI Path** | Devices → Compliance → Policies → Create policy (Windows 10 and later) → **System Security** → *Require BitLocker* |

**Effect:** Intune queries the Health Attestation Service (HAS) to confirm BitLocker is protecting the OS volume. Devices without BitLocker encryption on the C: drive are marked non-compliant.

**False-Positive Risk:**
- BitLocker provisioning is still in progress (e.g. initial encryption run on a newly enrolled device).
- TPM chip not provisioned or in a reduced-functionality state after a firmware update.
- Virtual machines (AVD session host OS disks) where BitLocker may not apply in the same way as physical endpoints.
- HAS reporting lag — the Health Attestation Service can take up to 24 hours to reflect a newly enabled state.

**Recommendation:** Ensure the 7-day grace period is in place to absorb HAS reporting lag and in-progress encryption. Exclude AVD session host VMs using a separate compliance policy or dynamic device group scoped to physical hardware.

---

## Requirement 2 – Secure Boot Must Be Enabled

| Field | Detail |
|---|---|
| **Settings Name** | `Require Secure Boot to be enabled on the device` |
| **Value** | `Require` |
| **UI Path** | Devices → Compliance → Policies → Create policy (Windows 10 and later) → **Device Health** → *Require Secure Boot to be enabled on the device* |

**Effect:** Intune checks via the Health Attestation Service that the device booted with Secure Boot active. This prevents bootkit and rootkit malware from loading before the OS starts.

**False-Positive Risk:**
- Older hardware (pre-2017) that does not support Secure Boot in firmware.
- Devices dual-booting Linux or running custom boot loaders where Secure Boot was deliberately disabled.
- BIOS/UEFI firmware updates that reset Secure Boot to disabled.
- HAS reporting lag (same as BitLocker above).

**Recommendation:** Audit device hardware inventory before enforcing. Create a hardware-scoped exclusion group for any legacy estate that is being actively refreshed, and set a refresh deadline so the exclusion is time-bounded.

> ⚠️ **UI Change Flag:** The "Device Health" section in Intune has been reorganised in recent portal updates. If you do not see *Device Health* as a top-level section, look under **Compliance settings → Device Health** or use the search bar within the policy settings blade. Verify the current path in the Intune admin center at the time of authoring.

---

## Requirement 3 – Minimum OS Build (N-1: 22621.2861)

| Field | Detail |
|---|---|
| **Settings Name** | `Minimum OS version` |
| **Value** | `10.0.22621.2861` |
| **UI Path** | Devices → Compliance → Policies → Create policy (Windows 10 and later) → **Device Properties** → *Minimum OS version* |

**Effect:** Devices running an OS build older than 10.0.22621.2861 are flagged as non-compliant. This enforces the N-1 policy — devices must be no more than one cumulative update behind the current known-good build (22621.3155).

**False-Positive Risk:**
- Windows Update scan has not yet run after a device comes back from offline/standby.
- Devices in a Windows Update for Business deferral ring that have not yet received the update.
- Update Compliance reporting lag between Windows Update and Intune inventory sync.
- Devices with Windows Update blocked by a firewall or proxy during onboarding.

**Recommendation:** Align the 7-day grace period with your Windows Update for Business deferral window. If your deferral ring is set to 5 days, the combined 7-day grace should absorb propagation. Review the minimum build value at each Patch Tuesday cycle and update the policy accordingly. Consider pinning this review to your change management calendar.

> ⚠️ **UI Change Flag:** Build numbers must be entered in the full `Major.Minor.Build.Revision` format (e.g. `10.0.22621.2861`). The Intune portal validates the format — entering just `22621.2861` will be rejected. Confirm the field label is still *Minimum OS version* and not split into separate Major/Minor fields, as Microsoft has adjusted this UI in some preview builds of the admin center.

---

## Requirement 4 – Windows Defender Real-Time Protection Must Be On

| Field | Detail |
|---|---|
| **Settings Name** | `Require real-time protection` |
| **Value** | `Require` |
| **UI Path** | Devices → Compliance → Policies → Create policy (Windows 10 and later) → **System Security** → *Require real-time protection* |

**Effect:** Confirms that Microsoft Defender Antivirus real-time protection (on-access scanning) is active. Devices where it has been disabled — by a user, script, Group Policy conflict, or third-party AV — are marked non-compliant.

**False-Positive Risk:**
- Third-party antivirus (e.g. Sophos, CrowdStrike Falcon) registered with Windows Security Center causes Defender to auto-disable its own real-time protection; Intune may read this as Defender being off even though the device is protected.
- Defender update failure causing the service to enter a degraded state temporarily.
- Tamper Protection preventing a re-enable attempt, surfacing as a persistent non-compliance.

**Recommendation:** If a third-party AV is deployed, this setting will generate systemic false positives. In that scenario, either: (a) rely on the third-party AV's own compliance connector (e.g. CrowdStrike + Intune connector), or (b) exclude the affected device group from this specific setting and enforce real-time protection via the third-party AV policy instead. Do not suppress the alert without a documented compensating control.

---

## Requirement 5 – Firewall Must Be Enabled for All Profiles

| Field | Detail |
|---|---|
| **Settings Name** | `Microsoft Defender Firewall` |
| **Value** | `Require` |
| **UI Path** | Devices → Compliance → Policies → Create policy (Windows 10 and later) → **System Security** → *Microsoft Defender Firewall* |

**Effect:** Checks that Windows Firewall is enabled across all three network profiles (Domain, Private, Public). A device with the firewall disabled on any profile is marked non-compliant.

**False-Positive Risk:**
- Third-party host-based firewalls (e.g. Cisco Secure Endpoint, Symantec) may disable Windows Firewall; Intune reads the Windows Firewall state only, not third-party firewall state.
- Legacy LOB applications that require Windows Firewall to be disabled to function (a security debt item that should be tracked).
- GPO conflict where an on-premises Group Policy disables the firewall on domain-joined devices, overriding Intune MDM policy.

**Recommendation:** Audit GPO vs MDM policy conflict using `gpresult /h` output and MDM Diagnostics. If a third-party firewall is the intended control, document it as a compensating control and exclude affected devices from this check with a scoped exception group. Resolve GPO conflicts by migrating to Intune firewall policy (Endpoint Security → Firewall).

> ⚠️ **UI Change Flag:** In newer versions of the Intune admin center, firewall compliance settings may appear under **Endpoint Security → Firewall** rather than the compliance policy blade. The compliance policy check remains in *System Security*, but the enforcement policy should be managed in the Endpoint Security section. Verify that you are configuring the *compliance check* (read-only state assertion) and not the *configuration profile* (active enforcement) — both are required.

---

## Requirement 6 – A PIN or Password Must Be Configured

| Field | Detail |
|---|---|
| **Settings Name** | `Require a password to unlock mobile devices` |
| **Value** | `Require` |
| **UI Path** | Devices → Compliance → Policies → Create policy (Windows 10 and later) → **System Security** → *Require a password to unlock mobile devices* |

**Supporting Settings to Configure Alongside:**

| Settings Name | Recommended Value |
|---|---|
| `Simple passwords` | `Block` |
| `Minimum password length` | `8` (DWP baseline minimum) |
| `Required password type` | `Alphanumeric` |
| `Password expiration (days)` | `0` (align with NCSC guidance — no forced expiry) |
| `Number of previous passwords to prevent reuse` | `5` |

**Effect:** Requires that the device has a lock screen PIN or password configured. Without this, physical access to the device is unprotected.

**False-Positive Risk:**
- Shared/kiosk devices where no user-specific PIN is configured by design.
- Windows Hello for Business enrolled devices where the legacy password compliance check does not correctly detect Windows Hello PIN as satisfying the requirement (depends on Intune build version).
- Devices enrolled in Autopilot self-deploying mode where the PIN prompt has not yet completed.

**Recommendation:** For Windows Hello for Business environments, verify that Intune correctly surfaces the Windows Hello PIN as satisfying this compliance check in your tenant's current version. Test with a pilot group before broad enforcement. Create a dedicated compliance policy for shared/kiosk devices with appropriately scoped settings.

> ⚠️ **UI Change Flag:** The label *"Require a password to unlock mobile devices"* is a legacy label carried over from mobile device management and applies to Windows 10/11 desktops as well, despite the wording. Microsoft has been updating terminology in recent admin center releases — the label may appear as *"Require a password"* or similar. Confirm the exact label in your tenant before documenting it in internal runbooks.

---

## Requirement 7 – Device Must Not Be Jailbroken or Rooted

| Field | Detail |
|---|---|
| **Settings Name** | `Require the device to be at or under the machine risk score` |
| **Value** | `Low` |
| **UI Path** | Devices → Compliance → Policies → Create policy (Windows 10 and later) → **Microsoft Defender for Endpoint** → *Require the device to be at or under the machine risk score* |

**Effect:** For Windows 11, there is no direct "jailbreak" concept as on mobile platforms. The closest equivalent is using Microsoft Defender for Endpoint (MDE) risk score integration. Setting the maximum tolerated risk to *Low* ensures that devices with indicators of compromise — including tampered boot chain, rootkits, or privilege escalation artefacts — are flagged as non-compliant.

**Supplementary Setting (Device Health Attestation):**

| Settings Name | Value |
|---|---|
| `Require code integrity` | `Require` |
| `UI Path` | Device Health → *Require code integrity* |

Code Integrity (CI) enforcement detects unsigned or tampered kernel drivers, which is the Windows 11 equivalent of detecting rooting attempts.

**False-Positive Risk:**
- MDE onboarding is incomplete — devices not fully onboarded to MDE will have no risk score and may default to a non-compliant state depending on tenant configuration.
- MDE sensor health issues (high CPU, service crash) temporarily reporting an inaccurate risk score.
- Security researchers or IT engineers running penetration testing tools on their own devices triggering a Medium/High risk score.
- Devices with unsigned legacy drivers (common in older hardware or specialist peripherals).

**Recommendation:** Ensure MDE onboarding is completed before compliance enforcement is activated. Use the *"Mark device noncompliant if no risk score is received"* setting with caution — set it only after confirming full MDE coverage across the estate. Create an exception process for security/pen-test team devices with documented approval.

> ⚠️ **UI Change Flag:** This setting requires the **Defender for Endpoint connector** to be active in your Intune tenant (*Tenant administration → Connectors and tokens → Microsoft Defender for Endpoint*). Without the connector, the setting will not function. The connector configuration path has moved in recent admin center updates — verify the current location when configuring. This integration is also sometimes listed as requiring a **Defender for Endpoint P1/P2 licence** per device; confirm licensing coverage before enforcement.

---

## Summary Table

| # | Requirement | Intune Setting Name | Value | Grace Period |
|---|---|---|---|---|
| 1 | BitLocker on OS drive | `Require BitLocker` | Require | 7 days |
| 2 | Secure Boot enabled | `Require Secure Boot to be enabled on the device` | Require | 7 days |
| 3 | Minimum OS build (N-1) | `Minimum OS version` | `10.0.22621.2861` | 7 days |
| 4 | Defender real-time protection | `Require real-time protection` | Require | 7 days |
| 5 | Firewall all profiles | `Microsoft Defender Firewall` | Require | 7 days |
| 6 | PIN or password | `Require a password to unlock mobile devices` | Require | 7 days |
| 7 | Not jailbroken/rooted | `Require the device to be at or under the machine risk score` | Low | 7 days |

---

## UI Change Flags Summary

The following settings carry a higher risk of the Intune admin center UI path having changed since training data. Verify each before publishing the policy:

| Setting | Risk | What to Check |
|---|---|---|
| Secure Boot (Req 2) | Medium | *Device Health* section may be reorganised; use search within policy blade |
| Minimum OS version (Req 3) | Low–Medium | Confirm full `10.0.X.X` format is still required |
| Firewall (Req 5) | Medium | Distinguish compliance check blade from Endpoint Security enforcement blade |
| Password label (Req 6) | Low | Label wording may have been updated from "mobile devices" |
| MDE risk score (Req 7) | High | Connector path has moved; licensing requirement must be confirmed; MDE onboarding prerequisite |

---

## Post-Assignment Validation Steps (Device Just Synced)

Use this workflow immediately after assigning the policy and forcing a device sync.

### 1) Where to check compliance for this specific policy

**Path A (from the policy):**

1. Microsoft Intune admin center → Devices → Compliance → Policies.
2. Open the Windows 10 and later policy you assigned.
3. Select **Device status**.
4. Search for the device name and open it to view per-setting results.

**Path B (from the device):**

1. Microsoft Intune admin center → Devices → All devices.
2. Open the target device.
3. Select **Device compliance**.
4. Open the specific policy to see the state and failing setting details.

### 2) What each status means for Conditional Access impact

- **Compliant:** Device satisfies the policy (or all non-compliance is remediated). Conditional Access policies that require a compliant device are satisfied.
- **Not compliant:** Device has one or more failed required settings beyond grace period (or immediate fail actions). Conditional Access policies requiring compliant device will block access (or enforce stronger control depending on policy design).
- **In grace period:** Device has a detected failure but is still inside the configured remediation window (7 days in this baseline). Conditional Access usually treats this as temporarily allowed until grace expires; after expiry it transitions to Not compliant if unresolved.

> Validation note: Conditional Access effect should be verified in your tenant's sign-in logs because CA decision also depends on user, app, location, and grant controls.

### 3) BitLocker shows Not compliant but BitLocker is enabled (common false positives)

#### Cause A: Health Attestation Service (HAS) reporting lag

- **Why it happens:** BitLocker was enabled recently, but HAS/Intune has not yet ingested the updated encrypted state.
- **Fastest check:** On the endpoint, run `manage-bde -status C:` and confirm **Conversion Status = Fully Encrypted** and **Protection Status = Protection On**. If correct locally but Intune still shows fail, this is likely telemetry lag.

#### Cause B: Encryption is still in progress

- **Why it happens:** Device started encryption after enrollment or policy application; Intune evaluates before completion.
- **Fastest check:** On the endpoint, run `manage-bde -status C:` and check **Percentage Encrypted**. If below 100%, wait for completion and resync.

#### Cause C: TPM/Measured Boot attestation issue after firmware or TPM state change

- **Why it happens:** BitLocker is active, but attestation signal is stale or degraded due to TPM readiness/firmware transitions.
- **Fastest check:** On the endpoint, run `Get-Tpm` and verify `TpmPresent=True`, `TpmReady=True`, and no lockout/ownership errors. Then trigger a sync and re-evaluate policy state.

### First 24-hour validation checklist after rollout

1. In policy **Device status**, confirm expected distribution of Compliant/In grace period/Not compliant and no sudden spike in Not compliant.
2. In policy **Per-setting status**, verify `Require BitLocker` is not the dominant failure reason.
3. Sample at least 20 failing devices and run `manage-bde -status C:` to distinguish true failures from reporting lag.
4. Recheck sampled devices after 2-4 hours and again within 24 hours to confirm lag-related failures self-resolve.
5. Review Microsoft Entra sign-in logs for Conditional Access failures tied to "device not compliant" to ensure business access is not being unintentionally impacted.

---

## Related References

- [Microsoft Intune compliance policy documentation](https://learn.microsoft.com/en-us/mem/intune/protect/device-compliance-get-started)
- [Windows 11 security baseline (Microsoft)](https://learn.microsoft.com/en-us/windows/security/operating-system-security/device-management/windows-security-baselines)
- [NCSC Password Guidance](https://www.ncsc.gov.uk/collection/passwords)
- [MDE + Intune integration](https://learn.microsoft.com/en-us/mem/intune/protect/advanced-threat-protection)
