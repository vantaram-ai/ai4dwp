# T-1001

## Summary
New Windows 11 laptop is prompting for the BitLocker recovery key on every boot.

## Impact
Single user affected; one device confirmed. Business urgency: user access and productivity are disrupted at each startup, with risk of lockout if the recovery key is unavailable.

## Known Facts
- Ticket reference: T-1001
- Device is a new Windows 11 laptop.
- BitLocker recovery is being prompted on every boot.
- Frequency appears to be every startup.
- User/device count currently confirmed: 1
- Any recent hardware, firmware, BIOS, TPM, docking, or build changes: to-verify
- Whether the user can successfully enter the recovery key and reach Windows: to-verify
- Whether this started from first use or after a change/update: to-verify

## Missing Information to Gather
- User name, location, and contact details through approved service desk records
- Asset name/serial number and support ownership
- Whether the recovery key works each time or the user is blocked
- Whether the issue occurs on cold boot, restart, and resume from sleep
- Whether BIOS/UEFI, TPM, Secure Boot, or boot order changed recently
- Whether the device has had motherboard, storage, or docking changes
- Whether any Windows updates, driver updates, or encryption policy changes were recently applied
- Whether other new laptops from the same build batch are affected
- Exact wording/photo of the BitLocker screen if available through approved channels

## Likely Category
BitLocker / Endpoint Encryption / Boot Security

## First Diagnostic Step
Confirm whether the device is repeatedly entering BitLocker recovery because the TPM or boot configuration is changing: verify in approved management records that the correct recovery key is escrowed for the device, then check with the user whether the recovery prompt began immediately from first boot or after a firmware, BIOS, docking, or hardware change.
