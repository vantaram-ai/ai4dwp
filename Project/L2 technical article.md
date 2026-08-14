# Floor 6 technical article

## Incident context
Floor 6 Legal users reported Monday-morning login slowness/failures, disappearing desktop shortcuts, and one high-risk Copilot matter exposure report after a Friday afternoon deployment of a new document management app. The leading hypothesis is that the rollout introduced a device/profile/policy interaction on the Win11 + Intune cohort, with a separate security/compliance track for the Copilot allegation.

## Current working hypothesis
The app deployment is the top-ranked cause to test first. The strongest expected failure modes are:
- logon delay caused by startup hooks, shell extensions, first-run tasks, or profile extension work
- shortcut loss caused by shell/profile redirection, per-user app data changes, or policy collision
- app/content visibility change caused by an indexing/connector/permissions interaction that must be verified independently

## What to collect on the next occurrence
Capture these fields before making changes:
- affected user name
- device name
- timestamp of first symptom
- whether sign-in succeeded, was slow, or failed
- whether desktop shortcuts disappeared after sign-in
- whether the user saw the same issue on a second login
- exact app name and version if visible
- whether the device is in the Floor 6 ring group

## Fastest technical checks
1. Confirm deployment footprint.
   - Check Intune assignment state for the device and ring group.
   - Confirm whether the document management app is installed, pending, failed, or recently updated.
   - Compare the affected device against one known-good Floor 6 device.

2. Check installer and shell signals.
   - Review Application log for MsiInstaller, Application Error, and User Profile Service events around the first-seen time.
   - Review AppXDeploymentServer/Operational for events around the same window.
   - Look for profile load warnings, shell startup delays, or app install retries.

3. Check desktop state.
   - Verify whether shortcuts exist under the user and Public desktop paths after sign-in.
   - Check whether the shell is loading a temp profile, a partial profile, or a redirected desktop path.

4. Check whether the app or deployment touches authentication timing.
   - Review sign-in duration against the same device before Friday if available.
   - Compare the affected device to an unaffected Floor 6 device on the same Win11 build.

## Evidence that supports the deployment hypothesis
- The app is present on affected devices and absent, pending, or at a different version on unaffected devices.
- The first symptom appears after the deployment window and repeats on affected devices.
- Login delay improves after the app is paused, removed from the ring, or otherwise unassigned.
- Shortcut loss resolves or stops recurring after containment.
- Logs show install, profile, or shell events that line up with the rollout.

## Evidence that weakens the deployment hypothesis
- Affected and unaffected devices have the same deployment state and version.
- The issue persists when the deployment is removed from the cohort.
- No installer, shell, or profile events line up with the rollout window.
- The same symptom appears on non-Floor 6 devices that were not in the rollout.

## Copilot matter exposure track
Treat the Copilot report as a separate security/compliance investigation until proven otherwise.

Check:
- the exact matter identifier or content surfaced
- the user account and timestamp
- the effective permissions on the underlying source
- whether the content came from the expected repository, connector, or cached index
- whether the app rollout changed indexing, connection scope, or metadata exposure

Do not assume the Copilot output is harmless. Confirm whether the surfaced matter was actually authorized for that user at that time.

## Containment and rollback guidance
If the deployment overlap is confirmed or strongly suspected:
- pause or remove the Floor 6 ring assignment from the document management app
- preserve logs before reinstalling or changing permissions
- compare one affected device after containment against one unaffected device

If rollback is needed:
- restore the prior assignment scope only after the incident lead approves
- validate one pilot device before re-enabling the full ring
- record whether sign-in latency, shortcut behavior, and app state return to normal

## Output expected for the next engineer
Provide a short handoff with:
- affected cohort
- app version and assignment state
- relevant log events
- whether containment changed the symptom
- whether the Copilot allegation was validated or ruled out

## Notes
- Do not close this as generic AI behaviour.
- Do not change permissions or purge evidence before audit review.
- Do not give an estimated restore time until the deployment correlation is tested.