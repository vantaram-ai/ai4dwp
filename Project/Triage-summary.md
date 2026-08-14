# Triage summary

## Summary (one line)
Floor 6 (Legal) is experiencing broad Monday-morning user disruption after a recent Win11/Intune migration and a Friday app rollout, with one reported potential data-access incident; scope and root cause are to confirm.

## Impact (who/how many/business urgency)
- Who: FinBridge Floor 6 Legal team (stated as 45 people).
- How many: "At least a dozen" users reportedly unable to log in or facing severe login slowness; additional users reporting other issues (exact counts to confirm).
- Business urgency: High and time-critical (work disruption in Legal and partner-facing update requested by lunch); one allegation of possible unauthorized matter visibility raises potential confidentiality/compliance risk (to confirm).

## known facts
- Time context provided: Monday morning; Slack message at 09:14 from IT Ops lead.
- Location/team: Floor 6, Legal, 45 people.
- Environment change context: Recently migrated to Windows 11 and enrolled in Intune.
- Reported symptoms:
  - At least a dozen users cannot log in or login is very slow.
  - One paralegal reports Copilot surfaced a client matter they believe they never had access to.
  - Another user reports desktop shortcuts vanished.
- Recent change: New document management app was rolled out to Floor 6 on Friday afternoon.
- Current evidence state: No logs provided; no pre-built export exists.

## Missing information to gather
- Scope and timeline:
  - Exact affected user count by symptom type (login failure, slow login, Copilot/data visibility concern, missing shortcuts).
  - First-seen times and whether symptoms started simultaneously or in sequence.
  - Whether issue is confined to Floor 6 or present in other floors/departments (to confirm).
- Authentication/session detail:
  - Exact login failure messages/codes and whether failures occur at sign-in, post-sign-in profile load, or app launch.
  - Affected identity provider path (AAD/SSO/conditional access behavior) and any lockout patterns.
- Endpoint/profile state:
  - Device names, Win11 build versions, Intune compliance/configuration status for affected vs unaffected users.
  - Evidence of profile corruption, temporary profiles, or shell policy/application impacting shortcuts.
- Change correlation:
  - Friday rollout details: package version, assignment scope, install success/failure rates, detection rules, and deployment timeline.
  - Any concurrent policy, security, identity, or network changes made late Friday/weekend.
- Data access allegation (high sensitivity):
  - Exact prompt, output snippet, timestamp, user account, and matter identifier from the reported Copilot incident.
  - Underlying document permissions/ACL history for that matter and whether access was transient, cached, misclassified, or accurately authorized (to confirm).
- User/business impact context:
  - Critical legal deadlines/hearings today and prioritized impacted users.

## likely category
- Primary: Major incident candidate affecting endpoint access/performance post-migration (Windows 11 + Intune) with possible change-induced regression after Friday deployment.
- Parallel high-priority track: Potential information-governance/security exposure via Copilot or underlying document permission model (to confirm).
- Working hypothesis: Potentially multi-cause incident rather than a single fault (to confirm).

## Suggest first diagnostic step
- Start with a 30-minute evidence baseline and triage split:
  - Build a rapid affected-user matrix (user, device, symptom, start time, severity).
  - In parallel, pull first-pass telemetry for sign-in events, Intune/device compliance, deployment status of the new document app, and endpoint profile load errors for affected vs unaffected users.
  - Immediately isolate and investigate the Copilot/data-access allegation as a separate priority stream (capture reproducibility and validate document ACL truth source before broad conclusions).
- Reason for this first step: it confirms scope, distinguishes single-cause vs multi-cause failure, and supports a defensible non-technical partner update by lunch without guessing.