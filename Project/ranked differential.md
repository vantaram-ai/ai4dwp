# ranked differential

## 1) Faulty or mis-scoped deployment of the new document management app (primary suspect)
- Why it is likely given what we know:
  - Change correlation is strong: new app deployed Friday afternoon to this exact floor, then broad disruption appears Monday morning.
  - Symptom mix can fit a bad enterprise app rollout: slow/failed logons (startup hooks, shell extensions, policy interactions), missing shortcuts, and content-surface anomalies (to confirm).
- Specific check to confirm it is the right fix:
  - Fastest check: compare deployment/install state for affected vs unaffected users/devices on Floor 6 (success/fail/pending, version, assignment intent, install time).
  - Validate whether pausing/removing assignment for a small affected pilot subset improves login time and shortcut behavior (controlled test, to confirm change control requirements).
- Evidence that would confirm or rule out deployment as the cause:
  - Confirm deployment as cause if: incident onset aligns with post-deployment first logon cycle; affected devices show common app version/install event pattern; symptom improves after rollback/unassignment; unaffected cohort lacks the same deployment footprint.
  - Rule out deployment as primary cause if: affected and unaffected users have identical deployment status/version/timing and no symptom change after controlled rollback or install suppression.

## 2) App introduced a logon-time dependency failure (service, network path, or plugin timeout)
- Why it is likely given what we know:
  - Reports include "can't log in or it's taking forever," consistent with logon pipeline delays rather than only app-launch issues.
  - Monday peak load could expose latent dependency timeouts that were not visible Friday afternoon (to confirm).
- Specific check to confirm it is the right fix:
  - Fastest check: on a representative affected endpoint, verify whether logon delay correlates with the app/service startup phase and whether delays disappear when app components are disabled or start mode is deferred (to confirm approved method).
- Evidence that would confirm or rule out deployment as the cause:
  - Confirm deployment-linked dependency fault if: repeating delay signature maps to the new app/service lifecycle and clears when that component is disabled/rolled back.
  - Rule out if: delays persist with app component disabled and no app-related timeout/error pattern appears in endpoint or sign-in traces.

## 3) Incorrect deployment targeting or configuration profile collision (Intune assignment conflict)
- Why it is likely given what we know:
  - Floor 6 was recently migrated to Win11 and enrolled in Intune; a new app assignment could conflict with existing policies, profiles, or required dependencies on that specific group (to confirm).
  - Mixed symptoms across identity, desktop experience, and app context can come from assignment collisions.
- Specific check to confirm it is the right fix:
  - Fastest check: inspect assignment scope, filters, dependency chains, and supersedence for the Friday rollout; compare effective policy/app set for affected vs unaffected Floor 6 devices.
- Evidence that would confirm or rule out deployment as the cause:
  - Confirm if: affected devices share a distinct assignment/configuration path (or failed dependency) introduced by Friday change and corrections normalize behavior.
  - Rule out if: no meaningful assignment/configuration difference exists between affected and unaffected cohorts.

## 4) User profile/shell impact from deployment (shortcut disappearance and desktop state changes)
- Why it is likely given what we know:
  - "Desktop shortcuts vanished" suggests shell/profile changes that can occur via app packaging actions, profile redirection behavior, or policy side effects.
  - If linked, this also supports a single change affecting multiple users on the same floor.
- Specific check to confirm it is the right fix:
  - Fastest check: verify whether shortcut locations and shell profile paths changed after deployment timestamp; compare pre/post state on affected devices and a non-affected control.
- Evidence that would confirm or rule out deployment as the cause:
  - Confirm if: shortcut/path changes coincide with install actions and reverse after rollback/remediation.
  - Rule out if: missing shortcuts are due to unrelated profile corruption or storage/sync issues with no temporal linkage to deployment events.

## 5) Copilot matter exposure driven by underlying permission misconfiguration revealed during app/data integration changes
- Why it is likely given what we know:
  - One paralegal reports Copilot surfaced a matter they believe they never accessed; if the new app changed indexing/connectors/metadata or surfaced broader repositories, an existing ACL issue may now be visible (to confirm).
  - This may be parallel to, not caused by, login/shortcut issues.
- Specific check to confirm it is the right fix:
  - Fastest check: validate effective permissions (truth source ACL) for the reported matter at incident time and compare with Copilot grounding source/citation path for that output.
- Evidence that would confirm or rule out deployment as the cause:
  - Confirm deployment contribution if: new app integration/indexing path was introduced Friday and the surfaced content trace maps to that path with widened effective visibility.
  - Rule out deployment if: effective permissions already allowed access before Friday, or Copilot output cannot be tied to the new app/data path.

## 6) Unrelated Monday incident coinciding with deployment (identity/auth service degradation)
- Why it is likely given what we know:
  - At least a dozen login failures/slowness could also be caused by independent identity or conditional-access degradation, with timing coincidence (to confirm).
  - Must remain in differential to avoid anchoring bias on Friday change.
- Specific check to confirm it is the right fix:
  - Fastest check: compare sign-in failure/latency trends for Floor 6 versus other floors/tenants/services during the same window.
- Evidence that would confirm or rule out deployment as the cause:
  - Confirm not deployment-driven if: broad identity degradation is visible outside Floor 6 with no specific linkage to rollout cohort.
  - Rule out this alternative (and strengthen deployment hypothesis) if: degradation is tightly localized to the deployment cohort and not observed elsewhere.

## Practical interpretation of deployment causality (to confirm)
- Strongly supports deployment cause:
  - Temporal alignment + cohort localization + common technical signature + improvement after rollback/assignment pause.
- Weakens deployment cause:
  - No cohort difference, no technical signature match, and no change after rollback/suppression.
- Indicates multi-cause incident:
  - Login/shortcut issues track deployment, while Copilot allegation traces to separate permission-governance path.