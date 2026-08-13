# Day 9 - Azure Virtual Desktop Provisioning Runbook (POOL-FIN-01)

Date: 2026-08-13
Engineer context: DWP migration lab build for Windows 11 workplace

## Scope Completed

Environment:
- Subscription: `265adc95-4fa6-4207-a717-b2cdcd750171`
- Resource group: `dwp-lab-rg`
- Region: `centralus`
- Tenant: `zippyops.in`

Delivered:
1. Pooled host pool `POOL-FIN-01` with `BreadthFirst` load balancing and `maxSessionLimit=5`
2. Desktop application group `POOL-FIN-01-DAG`
3. Workspace `FinBridge-Workspace` with app group registration
4. One Windows 11 AVD session host VM `vm-fin-01` (`Standard_B2ms`)
5. Trusted Launch enabled with Secure Boot + vTPM
6. Microsoft Entra sign-in enabled (AADLoginForWindows extension)
7. Session host successfully registered and reached `Available`
8. RBAC assigned for user `p07@zippyops.in`:
   - `Virtual Machine User Login` on VM scope
   - `Desktop Virtualization User` on desktop app group scope

## Prerequisite and RBAC Validation (Executed First)

The signed-in operator identity was verified before provisioning:
- Principal: `traininguser9@zippyops.in`
- Effective role: `Owner` at subscription and resource group scope
- Role assignment write capability: confirmed `true`

If this check fails in another environment, stop and do not skip RBAC tasks.

## Provisioning Steps Executed

### 1) Prerequisites
- Azure CLI extension ensured:
  - `desktopvirtualization`
- Resource providers registered:
  - `Microsoft.DesktopVirtualization`
  - `Microsoft.Compute`
  - `Microsoft.Network`
- Resource group existence validated (`dwp-lab-rg`).

### 2) AVD Control Plane
- Host pool created:
  - Name: `POOL-FIN-01`
  - Type: `Pooled`
  - Load balancing: `BreadthFirst`
  - Max sessions: `5`
  - Preferred app group type: `Desktop`
  - Custom RDP properties:
    - `targetisaadjoined:i:1`
    - `aadcredsspsupport:i:1`
    - `enablerdsaadauth:i:1`
- Desktop app group created: `POOL-FIN-01-DAG`
- Workspace created: `FinBridge-Workspace`
- App group registered to workspace.

### 3) Host Pool Registration Token
- Token generated via host pool `registration-info` update.
- Token retrieved using:
  - `az desktopvirtualization hostpool retrieve-registration-token`

### 4) Session Host VM
- VM created: `vm-fin-01`
- Image: `MicrosoftWindowsDesktop:windows-11:win11-24h2-avd:latest`
- Size: `Standard_B2ms`
- Security type: `TrustedLaunch`
- Secure Boot: `true`
- vTPM: `true`
- Managed identity: `SystemAssigned`

### 5) Entra VM Sign-In
- VM extension installed:
  - Publisher: `Microsoft.Azure.ActiveDirectory`
  - Type: `AADLoginForWindows`

### 6) Session Host Registration and Health Validation
- AVD Agent + Bootloader installed on VM using official fwlinks:
  - Agent: `https://go.microsoft.com/fwlink/?linkid=2310011`
  - Bootloader: `https://go.microsoft.com/fwlink/?linkid=2311028`
- Registration token passed to agent MSI install.
- Services verified running:
  - `RdAgent`
  - `RDAgentBootLoader`
- Host pool queried through ARM REST endpoint for session hosts.
- Final state:
  - Session host `POOL-FIN-01/vm-fin-01` status `Available`
  - AAD joined health check succeeded.

### 7) End-User Access RBAC
- User `p07@zippyops.in` assigned:
  - `Virtual Machine User Login` on:
    - `/subscriptions/265adc95-4fa6-4207-a717-b2cdcd750171/resourceGroups/dwp-lab-rg/providers/Microsoft.Compute/virtualMachines/vm-fin-01`
  - `Desktop Virtualization User` on:
    - `/subscriptions/265adc95-4fa6-4207-a717-b2cdcd750171/resourceGroups/dwp-lab-rg/providers/Microsoft.DesktopVirtualization/applicationGroups/POOL-FIN-01-DAG`

## Published Desktop Name for Testing

The desktop published from app group `POOL-FIN-01-DAG` is:
- `SessionDesktop`

Workspace in client:
- `FinBridge-Workspace`

## Live Backend Validation Method Used During Client Launch

To capture exact landing time of an end-user session, backend polling was performed against:
- Session hosts endpoint
- User sessions endpoint

Detection output captured:
- Session count
- Detected timestamp in UTC
- Session name
- Session user
- Session state
- Session create time

Scriptized monitor is saved in this folder:
- `Monitor-AVD-Session-Landing.ps1`

## Troubleshooting Notes from This Build

1. AVD CLI subgroup mismatch
- Installed `desktopvirtualization` extension did not expose `session-host` subgroup.
- Workaround used: ARM REST API queries with `az rest` for session host and user session state.

2. First agent download method failed
- Legacy direct binary URL returned `BlobNotFound` from VM context.
- Resolution: switched to Microsoft fwlink-based download links and reinstalled.

3. PowerShell 5 `Invoke-WebRequest` parsing issue in VM Run Command
- Error indicated IE engine dependency.
- Resolution: used `-UseBasicParsing`.

4. Interactive terminal prompt encountered (`Terminate batch job (Y/N)?`)
- Occurred in long/combined shell runs.
- Resolution: reran as smaller atomic commands and verified each result.

## Day9 Artifacts Created

- `AVD-Provisioning-Runbook-POOL-FIN-01.md` (this document)
- `Provision-AVD-POOL-FIN-01.ps1` (repeatable provisioning script)
- `Monitor-AVD-Session-Landing.ps1` (live session landing monitor)

## Security/Operational Notes

- Rotate any local admin password used during test provisioning.
- Remove public RDP exposure for production design; prefer private access/Bastion.
- Keep token lifetime minimal and regenerate only as needed.
- Validate licensing and conditional access requirements for Entra-joined AVD sign-ins.
