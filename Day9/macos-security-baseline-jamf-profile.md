# JAMF Configuration Profile — macOS Security Baseline
**Authored by:** DWP Engineer  
**Date:** 2026-08-13  
**Scope:** macOS managed devices enrolled in JAMF Pro — DWP Design Team fleet (25 devices)  
**Grace Period:** 48–72 hours recommended for all settings (see note below)

---

## Grace Period Note

JAMF Pro does not enforce a native per-setting grace period in the same way as Microsoft Intune. The compliance signal from JAMF feeds into your IdP (typically Microsoft Entra via the **JAMF + Microsoft Intune integration / JAMF Cloud Connector**). The grace period is therefore configured at the **Entra Conditional Access** level:

> **Microsoft Entra admin center** → Protection → Conditional Access → Policies → [Your Policy] → Conditions → Device platforms → macOS

Allow 48–72 hours after initial profile assignment before enforcing block-on-non-compliance in Conditional Access. This absorbs JAMF check-in delay, first-boot encryption time, and MDM profile installation lag.

> **Naming caveat (applies to all requirements below):** JAMF Pro payload names and UI labels change between versions. Do NOT treat payload names or UI paths below as exact click-paths. Verify each against your live JAMF instance before publishing — the same discipline applied in the Intune labs on Day 6. Entries most likely to have drifted are flagged with ⚠️.

---

## Requirement 1 — FileVault Disk Encryption

| Field | Detail |
|---|---|
| **Payload type** | `Disk Encryption` (FileVault) |
| **JAMF UI Path** | Computers → Configuration Profiles → New → **Disk Encryption** |
| **Value** | `FileVault` = `Enable FileVault`; `Escrow Personal Recovery Key` = `to JAMF Pro` |
| **Effect** | Full-volume encryption is enforced at rest. macOS will prompt the logged-in user to enable FileVault on next login if not already active. Without the escrow key held by JAMF, recovery from a locked device would require manual intervention. |

**False-Positive Risk:**
- Device shows non-compliant if the escrow key has not yet been sent to JAMF (common on first check-in, or after an OS reinstall — the key is only escrowed after the user logs in and FileVault activates).
- FileVault activation is deferred — by default, the Disk Encryption payload prompts the user at next login; if they have not yet logged in interactively, JAMF reports no key and therefore no compliance.
- Devices with multiple local user accounts where FileVault is enabled but additional users have not yet been granted a FileVault unlock capability.

**Recommendation:** Scope the Disk Encryption payload to a smart group that excludes machines pending first interactive login (e.g. newly enrolled devices in a staging group). Move devices into the enforced group only after first login has completed. Test the escrow path by verifying the recovery key appears under `Computers → [Device] → Security` in JAMF Pro before declaring the device compliant.

---

## Requirement 2 — Gatekeeper (Identified Developers Only)

| Field | Detail |
|---|---|
| **Payload type** | `Security & Privacy` ⚠️ |
| **JAMF UI Path** | Computers → Configuration Profiles → New → **Security & Privacy** → General tab |
| **Value** | `Allow applications downloaded from` = `App Store and identified developers` (equivalent to `spctl --master-enable` with `assessmentPolicy = 2`) |
| **Effect** | Blocks execution of unsigned or unnotarised binaries. Users cannot override the setting via System Settings → Privacy & Security without admin privileges, because the MDM profile locks the control. |

**False-Positive Risk:**
- In-house or legacy tools signed with an expired or revoked Developer ID will block and flag the device — this is a true positive (the tool is genuinely untrusted), not a false positive, but it will surface as a compliance alert.
- Design-team tooling (Adobe Creative Cloud components, Figma desktop, command-line tools installed via Homebrew) may use unsigned packages in update flows. These will not block the app itself but can trigger Gatekeeper on helper binaries.
- macOS version differences: Gatekeeper behaviour changed in macOS 14 (Sonoma) and again in 15; some validation UI was moved from System Preferences to System Settings. The JAMF payload key still applies, but the user-facing experience differs.

**Recommendation:** Before enforcement, run a JAMF inventory report (`Computers → Advanced Computer Search`) to identify any apps not signed by identified developers currently installed across the 25 Design-team devices. Agree remediation for any blocked tools — either obtain a signed version, notarise the internal build, or scope a specific Gatekeeper exception via a custom configuration profile using `com.apple.security.assessmentpolicy`.

> ⚠️ **UI Change Flag:** The Security & Privacy payload in JAMF Pro has been restructured across versions. The `General` tab may appear as a top-level section or under a sub-tab depending on your JAMF Pro version. Some JAMF versions surface Gatekeeper under a `Privacy` tab rather than `General`. Verify the exact tab in your instance.

---

## Requirement 3 — Minimum macOS Version

| Field | Detail |
|---|---|
| **Payload type** | `Restrictions` → OS Updates / or `Managed Software Updates` ⚠️ |
| **JAMF UI Path** | Computers → Configuration Profiles → New → **Restrictions** → Functionality tab (for blocking downgrades) **or** Computers → **Managed Software Updates** → OS Update Settings |
| **Value** | Current stable **minus one point release**. As of August 2026, verify Apple's current release at [apple.com/macos/release-notes](https://support.apple.com/en-gb/100100) and set the floor to the previous point release. **Do not hard-code a version number from this document — check at deployment time.** |
| **Effect** | Devices below the minimum version floor are marked non-compliant in JAMF and the signal propagates to Entra Conditional Access (if the JAMF connector is active), where they can be blocked from accessing Microsoft 365 resources. |

**False-Positive Risk:**
- Devices mid-update (update downloaded but pending restart) will report the old OS version until the restart completes and JAMF re-inventories.
- Devices returned from extended leave that missed several update cycles — they will flag immediately on check-in.
- JAMF inventory sync lag: JAMF updates the OS version field on inventory submission, which occurs on check-in (default every 15–30 minutes). A device that updated but has not yet checked in will appear non-compliant.
- Devices on Apple Silicon with low storage may fail to download the update package, silently remaining non-compliant.

**Recommendation:** Align the grace period (48–72 hours in Entra CA) with your Managed Software Updates deferral window. Review the minimum version value at each Apple security update release (approximately monthly) and update the smart group criteria accordingly. Create a JAMF smart group scoped to `Operating System Version` `is less than` `[floor version]` to give visibility of out-of-floor devices before enforcement.

> ⚠️ **UI Change Flag:** JAMF Pro introduced **Managed Software Updates** as a dedicated feature set in JAMF Pro 10.44+. If your JAMF instance pre-dates this, OS update enforcement may be handled via a `softwareupdate` command in a JAMF policy script instead. Verify which mechanism is active in your environment before relying on the Restrictions payload alone.

---

## Requirement 4 — Firewall

| Field | Detail |
|---|---|
| **Payload type** | `Security & Privacy` → Firewall ⚠️ |
| **JAMF UI Path** | Computers → Configuration Profiles → New → **Security & Privacy** → Firewall tab |
| **Value** | `Enable Firewall` = `true`; `Block all incoming connections` = `false` (Design-team devices may run local dev servers — agree with the team before enabling block-all); `Automatically allow built-in software` = `true`; `Automatically allow downloaded signed software` = `true` |
| **Effect** | The macOS application-layer firewall (`socketfilterfw`) is enforced on. Unsigned apps cannot accept incoming network connections without an explicit admin allow. This is a host-based control protecting the device on untrusted networks (e.g. remote workers on home Wi-Fi). |

**False-Positive Risk:**
- Devices with Little Snitch, LuLu, or another third-party host firewall installed: macOS may report the built-in firewall as off because the third-party tool has registered itself as the firewall provider. JAMF reads the `socketfilterfw` state, not the third-party firewall state.
- JAMF inventory can report a stale firewall state between check-ins — a device that recently re-enabled its firewall may still show as non-compliant until the next inventory submission.
- Design-team tools that act as local servers (e.g. local webpack dev servers, Storybook, Figma desktop agent) may prompt the user to allow incoming connections; if the user dismisses the prompt, those connections are silently blocked and reported to JAMF.

**Recommendation:** If a third-party host firewall is deployed on any Design-team devices, document it as a compensating control and scope those devices out of this check using a JAMF smart group. Do not suppress the alert without a documented exception. For the native firewall, verify the state locally on a sample device using `sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate` before and after profile assignment.

> ⚠️ **UI Change Flag:** In JAMF Pro, the Security & Privacy payload contains both a `General` and a `Firewall` tab. Depending on the JAMF Pro version, the Firewall sub-section may be presented as a separate expandable section. Confirm the exact layout in your instance before authoring.

---

## Requirement 5 — Login Password After Sleep/Screen Saver

| Field | Detail |
|---|---|
| **Payload type** | `Security & Privacy` and/or `Login Window` ⚠️ |
| **JAMF UI Path** | Computers → Configuration Profiles → New → **Security & Privacy** → General tab → *Require password after sleep or screen saver begins* **and** Computers → Configuration Profiles → New → **Login Window** |
| **Value** | `Require password after sleep or screen saver begins` = `true`; `Password delay` = `0` seconds (Immediately) — or agree a maximum of `5` seconds with stakeholders for usability |
| **Effect** | An unattended and unlocked session cannot be accessed without credentials after the screen sleeps or the screen saver activates. Meets NCSC clear-screen control and DWP physical security policy for remote workers. |

**Supporting settings to configure alongside:**

| Setting | Recommended Value |
|---|---|
| `Login Window` → `Show full name instead of short name` | `true` (avoids username enumeration) |
| `Security & Privacy` → `Disable automatic login` | `true` |
| Screen saver idle timeout (via `Energy Saver` payload) | `10 minutes` (agree with team) |

**False-Positive Risk:**
- Devices where the user had previously set a manual password-delay override in System Settings → Privacy & Security before MDM enrolment: the MDM profile should override this, but on first profile installation a restart may be required before the setting takes effect. JAMF may report non-compliance during the window between profile delivery and restart.
- JAMF inventory reflects the MCX/profile-applied state, not the current live system state. A profile delivered but not yet activated (pre-restart) will show the old value.

**Recommendation:** After profile assignment, test on a pilot device by manually triggering the screen saver (`Control + Shift + Power`) and confirming the lock screen prompts for a password immediately. Verify via `sudo defaults read /Library/Preferences/com.apple.screensaver loginWindowIdleTime` and `sudo defaults read /Library/Preferences/com.apple.screensaver askForPassword` that the managed values are written correctly.

> ⚠️ **UI Change Flag:** The password-after-sleep setting moved between payload types in JAMF Pro across macOS versions. In some JAMF Pro versions it appears under the `Security & Privacy` payload General tab; in others it is managed via a custom `com.apple.screensaver` payload key. Verify which payload your JAMF instance exposes this setting under, and test profile delivery before broad rollout.

---

## Requirement 6 — Automatic Security Updates

| Field | Detail |
|---|---|
| **Payload type** | `Software Update` / `Managed Software Updates` ⚠️ |
| **JAMF UI Path** | Computers → Configuration Profiles → New → **Software Update** (for legacy payload) **or** Computers → **Managed Software Updates** → Update Settings (for JAMF Pro 10.44+) |
| **Value** | `Automatically install macOS security responses and system files` = `true`; `Automatically check for updates` = `true`; `Automatically install app updates from App Store` = optional (agree with team — Design team may want control over Adobe/Figma update timing); `Automatically install system data files and security updates` = `true` |
| **Effect** | Rapid Security Responses (RSRs) and XProtect/MRT definition updates are applied without user action. This closes zero-day gaps in hours rather than waiting for a user-initiated update cycle, which is the highest-value setting in this baseline for active threat response. |

**False-Positive Risk:**
- JAMF's software update payload reporting lags behind Apple's Software Update CDN by up to one check-in cycle (15–30 minutes). A device that has received and installed an RSR but not yet submitted an inventory update will appear non-compliant.
- Devices with low disk space (less than 2 GB free) will fail to download security updates silently — the update process fails without a user-visible error, and the device remains on the older version.
- Devices running older macOS versions (below the minimum floor set in Requirement 3) may not receive RSRs, as Apple only backports to supported releases.
- Corporate proxy or firewall rules blocking `swscan.apple.com`, `swdist.apple.com`, or `mesu.apple.com` will prevent updates from downloading even when the payload is applied.

**Recommendation:** Verify that Apple Software Update CDN endpoints are whitelisted in the DWP proxy/firewall configuration. Run a JAMF smart group query for devices with `Available Software Updates` `is not` `0` to identify devices with pending updates after policy enforcement. For Design-team devices using Adobe and Figma, agree whether App Store auto-updates should be enabled or managed separately through JAMF patch management to avoid unexpected creative tool updates during active projects.

> ⚠️ **UI Change Flag:** JAMF Pro's Software Update payload keys map to Apple's `com.apple.SoftwareUpdate` MDM payload. Apple modified the keys available in this payload in macOS 12 (Monterey) and again in macOS 14 (Sonoma) as part of the Managed Software Updates framework. If your JAMF instance is below version 10.44, the Managed Software Updates UI may not be available and you will need to use the legacy Software Update payload or a JAMF Policy running `softwareupdate --install --recommended`. Verify which path your JAMF version supports.

---

## Summary Table

| # | Requirement | Payload | JAMF UI Path | ⚠️ Verify naming? |
|---|---|---|---|---|
| 1 | FileVault | Disk Encryption | Computers → Config Profiles → Disk Encryption | No — stable |
| 2 | Gatekeeper | Security & Privacy | → Security & Privacy → General | Yes |
| 3 | Min OS version | Restrictions / Managed SW Updates | → Restrictions or Managed SW Updates | Yes |
| 4 | Firewall | Security & Privacy | → Security & Privacy → Firewall | Yes |
| 5 | Password on sleep | Security & Privacy + Login Window | → Security & Privacy → General | Yes |
| 6 | Auto security updates | Software Update / Managed SW Updates | → Software Update or Managed SW Updates | Yes |

---

## UI Change Flags Summary

The following settings carry a higher risk of the JAMF Pro UI path or payload key having changed since training data. Verify each before publishing the profile:

| Setting | Risk | What to Check |
|---|---|---|
| Gatekeeper (Req 2) | Medium | Security & Privacy payload tab layout varies by JAMF version; confirm `General` vs `Privacy` tab |
| Minimum OS version (Req 3) | Medium | Managed Software Updates is only available in JAMF Pro 10.44+; confirm your version |
| Firewall (Req 4) | Medium | Confirm Firewall is a sub-tab within Security & Privacy, not a separate payload in your instance |
| Password after sleep (Req 5) | High | Setting may live in Security & Privacy payload or require a custom `com.apple.screensaver` payload key depending on JAMF version |
| Auto security updates (Req 6) | High | Apple changed the payload keys in macOS 14+; Managed Software Updates replaces legacy keys in JAMF 10.44+ |

---

## Post-Deployment Validation Steps

Use this workflow immediately after assigning the profile and forcing a JAMF check-in.

### 1) How to force a check-in and verify profile delivery

**From JAMF Pro:**

1. Computers → All Computers → search for the target device.
2. Open the device record → **Management** tab.
3. Select **Send Blank Push** to trigger an immediate MDM check-in.
4. After 2–3 minutes, return to the device record → **Configuration Profiles** tab.
5. Confirm all six profiles appear with status `Installed`.

**From the device (as admin):**

```bash
sudo profiles show -all          # lists all installed MDM profiles
sudo profiles status -type configuration   # shows MDM enrolment status
```

### 2) Where to check compliance state in JAMF Pro

**Path A (from the device record):**

1. Computers → All Computers → open target device.
2. Select the **Security** tab — confirms FileVault status and escrow key presence.
3. Select the **General** tab — confirms OS version, last check-in, and MDM enrolment state.

**Path B (using Smart Groups for fleet-wide view):**

1. Computers → Smart Computer Groups → New.
2. Add criteria: `FileVault 2 Status` `is not` `Encrypted` to surface un-encrypted devices.
3. Add criteria: `Operating System Version` `is less than` `[floor version]` for OS compliance.
4. Use this smart group as your compliance dashboard before connecting to Entra CA.

### 3) What each JAMF status means for Conditional Access impact

- **Compliant (JAMF → Entra):** JAMF has submitted a compliant signal via the JAMF Cloud Connector. Entra Conditional Access policies requiring a compliant macOS device are satisfied.
- **Non-compliant:** JAMF has submitted a non-compliant signal. Entra CA policies enforcing device compliance will block or restrict access to Microsoft 365 resources after the grace period in the CA policy expires.
- **Not registered / no signal:** Device is enrolled in JAMF but the JAMF Cloud Connector has not yet pushed a compliance record to Entra. Entra will treat the device as unmanaged. Confirm the connector is active under `Tenant administration → Connectors and tokens → Partner device management` in the Intune admin center.

> Validation note: Entra CA effect depends on the full CA policy logic (user, app, location, grant controls). Verify in Entra sign-in logs, not just JAMF compliance status.

### 4) FileVault shows non-compliant but FileVault is active (common false positives)

#### Cause A: Recovery key not yet escrowed

- **Why it happens:** FileVault was enabled (or was already enabled before enrolment), but the personal recovery key has not yet been submitted to JAMF. This happens if the Disk Encryption profile was assigned after the initial enrolment and the user has not yet logged in to trigger the escrow flow.
- **Fastest check:** On the device, run `sudo fdesetup status` — confirm `FileVault is On`. In JAMF Pro under `Computers → [Device] → Security`, confirm whether `Personal Recovery Key` shows `Escrowed` or `Not Escrowed`. If the local state is encrypted but no key is escrowed, the user must log in once while the MDM profile is active to trigger escrow.

#### Cause B: Encryption still in progress

- **Why it happens:** The Disk Encryption profile was applied, FileVault activation started, but initial encryption has not yet completed. JAMF evaluates compliance before the full-disk encryption pass finishes.
- **Fastest check:** On the device, run `sudo fdesetup status` and look for `Encryption in progress`. Also run `diskutil apfs list` and check `FileVault` → `Yes (Unlocked)` vs `Yes (Locked)`. Wait for encryption to complete (can take 1–3 hours on a full drive), then trigger a JAMF check-in.

#### Cause C: JAMF inventory not yet updated after activation

- **Why it happens:** FileVault is fully on and the key is escrowed, but JAMF has not yet run an inventory update to reflect the current state.
- **Fastest check:** Trigger a manual inventory update from the device: open JAMF Self Service → `Update Inventory`, or run `sudo jamf recon` in Terminal. Recheck the Security tab in JAMF Pro after 2–3 minutes.

### First 48-hour validation checklist after rollout

1. In JAMF Pro, open the Disk Encryption smart group and confirm it is shrinking as devices check in and escrow keys.
2. Confirm the OS version smart group (`Operating System Version is less than [floor]`) shows no unexpected devices — investigate any that appear.
3. Sample 5 devices and run `sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate` to confirm the firewall is `enabled`.
4. Sample 5 devices and run `sudo spctl --status` to confirm `assessments enabled` (Gatekeeper active).
5. Verify in Entra sign-in logs that no Design-team users are being blocked by the device compliance CA policy during the grace window.
6. Recheck the JAMF compliance dashboard at 24 hours and 48 hours to confirm lag-related failures self-resolve.

---

## Related References

- [JAMF Pro Documentation — Configuration Profiles](https://docs.jamf.com/jamf-pro/documentation/Configuration_Profiles.html)
- [Apple MDM Protocol Reference — Payload types](https://developer.apple.com/documentation/devicemanagement/implementing_device_management/mdm_protocol_reference)
- [JAMF + Microsoft Intune integration (Cloud Connector)](https://docs.jamf.com/jamf-pro/documentation/Integrating_with_Microsoft_Intune.html)
- [Apple Platform Security Guide](https://support.apple.com/guide/security/welcome/web)
- [NCSC Password Guidance](https://www.ncsc.gov.uk/collection/passwords)
- [Apple Rapid Security Responses](https://support.apple.com/en-gb/HT213638)
