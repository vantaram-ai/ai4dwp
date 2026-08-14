# Immediate Fix

## Incident update for partners
Floor 6 Legal is experiencing a likely change-related incident after Friday’s new document management app rollout. The current leading hypothesis is that the deployment is causing logon slowness, missing desktop shortcuts, and possibly surfacing content in a way that needs security review (to confirm).

We have not confirmed root cause yet, so we are treating this as a service-impacting incident and a potential information-governance issue. We are checking the deployment footprint, sign-in evidence, and permission trail first, and we will provide the next update as soon as those checks are complete rather than giving a time we do not control.

## Safer service-desk runbook
1. Confirm scope: capture affected user name, device name, exact symptom, first seen time, and whether the user can sign in at all.
2. Check deployment state: confirm whether the device is in the Floor 6 ring group and whether the Friday app is installed, pending, failed, or recently updated (to confirm exact app name).
3. Compare peers: check one affected and one unaffected Floor 6 device for install version, Intune assignment, and shortcut/profile symptoms.
4. Preserve evidence: do not remove logs, reinstall apps, or change permissions until the sign-in and deployment timeline are captured.
5. Escalate the Copilot matter separately: treat any reported unauthorized matter visibility as a potential security/compliance issue until ACLs and audit trail are verified.
6. If rollback is approved: remove the Floor 6 ring assignment from the app deployment or pause the assignment for the affected cohort before broader changes.

## Immediate fix guidance
- Most likely short-term corrective action: pause or remove the Friday app rollout from the Floor 6 ring while evidence is collected.
- Do not close the issue as "AI weirdness."
- Do not promise a restore time until the deployment and sign-in checks confirm the next action.
