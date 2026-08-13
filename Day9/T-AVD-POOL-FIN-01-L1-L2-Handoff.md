# L1/L2 Handoff - Azure Virtual Desktop (POOL-FIN-01)

Date: 2026-08-13
Service owner context: DWP Windows 11 workplace migration

## Purpose

This handoff provides frontline and escalation teams with:
- Known-good baseline for the AVD environment
- Fast triage checks
- Standard fixes for common failures
- Clear L1 to L2 escalation boundaries

## Environment Baseline (Known Good)

Subscription:
- 265adc95-4fa6-4207-a717-b2cdcd750171

Resource group:
- dwp-lab-rg

Region:
- centralus

Host pool:
- Name: POOL-FIN-01
- Type: Pooled
- Load balancing: BreadthFirst
- Max sessions per host: 5

Application group:
- Name: POOL-FIN-01-DAG
- Type: Desktop

Workspace:
- Name: FinBridge-Workspace

Published desktop:
- SessionDesktop

Session host VM:
- Name: vm-fin-01
- Image: Windows 11 Enterprise multi-session AVD optimized
- Size: Standard_B2ms
- Security: Trusted Launch, Secure Boot enabled, vTPM enabled
- Identity: Entra-enabled sign-in extension installed (AADLoginForWindows)

Access role requirements for end users:
- Desktop Virtualization User on app group scope
- Virtual Machine User Login on VM scope (only needed for direct VM RDP)

## L1 - First Response Playbook

### 1) Confirm user scope and symptom

Collect:
- User UPN
- Time of failure (UTC if possible)
- Whether failure is in feed discovery, launch, or post-launch black screen
- Screenshot/error text from client

### 2) Confirm user can see the workspace and desktop

Expected:
- Workspace visible: FinBridge-Workspace
- Desktop visible: SessionDesktop

If desktop not visible:
- Verify user has Desktop Virtualization User role on POOL-FIN-01-DAG
- If missing, escalate to L2 for RBAC correction

### 3) Quick backend health check

Run:

```powershell
$sub='265adc95-4fa6-4207-a717-b2cdcd750171'
$url="https://management.azure.com/subscriptions/$sub/resourceGroups/dwp-lab-rg/providers/Microsoft.DesktopVirtualization/hostPools/POOL-FIN-01/sessionHosts?api-version=2024-04-03"
az rest --method get --url $url --query "value[].{name:name,status:properties.status,sessions:properties.sessions,lastHeartBeat:properties.lastHeartBeat}" -o table
```

Expected:
- vm-fin-01 status is Available

If status is Unavailable or heartbeats are stale:
- Escalate to L2 with timestamp and output

### 4) During user launch, verify session landing

Run this monitor script:
- Day9/Monitor-AVD-Session-Landing.ps1

Example:

```powershell
.\Day9\Monitor-AVD-Session-Landing.ps1
```

Success indicators:
- SESSION_COUNT greater than 0
- SESSION_LANDED_UTC_DETECTED present
- SESSION_USER matches affected user UPN

## L1 - Standard Resolution Actions

Allowed actions:
- Ask user to sign out and back in to AVD client
- Ask user to refresh/re-subscribe workspace feed
- Retry launch after 2-3 minutes if host just recovered from transient issue
- Recollect exact error string and timestamp if issue persists

Do not do at L1:
- Reinstall AVD agents
- Modify host pool settings
- Modify VM extensions
- Change RBAC assignments without approved process

## L1 to L2 Escalation Criteria

Escalate immediately if any of the following:
- Session host status not Available
- Session count stays 0 while user is actively launching
- User has correct assignment but feed/desktop still missing
- Repeated launch failure across multiple users
- Suspected agent/bootloader/heartbeat issues
- VM sign-in extension failures (AADLoginForWindows)

Escalation package must include:
- User UPN
- UTC time window
- Client error text/screenshot
- Output of session host health query
- Output of Monitor-AVD-Session-Landing.ps1

## L2 - Deep Diagnostic Workflow

### 1) Validate AVD object chain

- Host pool exists and configured:
  - BreadthFirst, maxSessionLimit 5
- App group linked to host pool
- Workspace contains app group reference

### 2) Validate user entitlements

Check user assignments:
- Desktop Virtualization User on app group scope
- Virtual Machine User Login on VM scope (if direct VM access scenario)

### 3) Validate VM and AVD agent state

Check VM:
- Provisioning succeeded
- Trusted Launch settings still intact

Check extensions/services:
- AADLoginForWindows extension provisioning state succeeded
- RdAgent service running
- RDAgentBootLoader service running

### 4) If session host not registering/available

Known fix path used successfully in this environment:
- Regenerate registration token
- Reinstall AVD agent and bootloader from official fwlinks
- Ensure PowerShell download commands use UseBasicParsing in VM Run Command context
- Re-check sessionHosts endpoint until status returns Available

Official installer fwlinks:
- https://go.microsoft.com/fwlink/?linkid=2310011
- https://go.microsoft.com/fwlink/?linkid=2311028

### 5) Re-verify published desktop object

Query desktops under app group and confirm SessionDesktop exists.

## L2 - Recovery Validation Checklist

Recovery is complete only when all are true:
- Session host status: Available
- User can see FinBridge-Workspace and SessionDesktop
- User launch succeeds
- Backend monitor confirms session landing with UTC timestamp

## Operations Notes

- Keep registration token lifetime short and regenerate as needed.
- For production hardening, remove public RDP exposure and prefer private/Bastion access.
- Preserve UTC timestamps in tickets for correlation with Azure activity and AVD diagnostics.

## Related Day9 Artifacts

- Day9/AVD-Provisioning-Runbook-POOL-FIN-01.md
- Day9/Provision-AVD-POOL-FIN-01.ps1
- Day9/Monitor-AVD-Session-Landing.ps1
