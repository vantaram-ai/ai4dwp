v 1.0, 07/08/2026, status : Draft

# KB: AVD black screen after login in POOL-FIN-01

## Background

Azure Virtual Desktop provides user desktops from shared session hosts. Stable desktop rendering at login is critical because users cannot work until a full desktop appears. In this incident pattern, one production pool can fail while another pool remains healthy, so rapid pool comparison and containment are essential to reduce business impact.

## Symptom

What users report:
- Black screen immediately after login
- Reconnect loop or disconnect after login
- Desktop appears only after delay, or not at all

What engineer observes:
- Incidents concentrated in POOL-FIN-01
- POOL-FIN-02 users unaffected in the same time window
- Repeated login and disconnect events on affected hosts

## Root cause

Specific cause:
- Regression introduced by overnight POOL-FIN-01 update causes dwm.exe to crash in igdumd64.dll (Intel user-mode graphics module), typically with exception code 0xc0000005.

Evidence that confirms this cause:
- Affected host chain repeats in sequence: Event 21, Event 1000, Event 9009, Event 40.
- Event 1000 fields show Faulting application name = dwm.exe and Faulting module name = igdumd64.dll.
- Comparison host in POOL-FIN-02 shows Event 9011 startup success and no matching Event 1000 signature in the same window.

## Detection

Target diagnosis time: under 3 minutes.

1. In Azure Portal, open Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts, then select one affected host and connect by RDP.
Expected result: You are on one affected host console.

2. On the affected host PowerShell console, run:
$Start = (Get-Date).AddHours(-2)
Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000; StartTime=$Start} | Where-Object { $_.Message -match 'Faulting application name:\s*dwm.exe' -and $_.Message -match 'Faulting module name:\s*igdumd64.dll' } | Select-Object -First 5 TimeCreated, Id, MachineName, Message
Expected result: At least one Application log Event 1000 is returned with Faulting application name: dwm.exe and Faulting module name: igdumd64.dll.

3. On the same affected host PowerShell console, run:
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Desktop Window Manager/Operational'; Id=9009; StartTime=$Start} | Select-Object -First 10 TimeCreated, Id, MachineName, Message
Expected result: Desktop Window Manager Operational log Event 9009 is present in the same time period as Event 1000.

4. On the same affected host, open Event Viewer > Windows Logs > Application, open one returned Event 1000, and verify these exact fields on the General tab: Faulting application name, Faulting module name, Exception code.
Expected result: Faulting application name = dwm.exe, Faulting module name = igdumd64.dll, Exception code = 0xc0000005.

5. In Azure Portal, open Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts, then connect by RDP to one control host.
Expected result: You are on one unaffected control host console.

6. On the POOL-FIN-02 control host PowerShell console, run:
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Desktop Window Manager/Operational'; Id=9011; StartTime=$Start} | Select-Object -First 10 TimeCreated, Id, MachineName, Message
Expected result: Event 9011 exists, establishing healthy baseline startup behavior on POOL-FIN-02.

7. On the same POOL-FIN-02 control host PowerShell console, run:
Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000; StartTime=$Start} | Where-Object { $_.Message -match 'Faulting application name:\s*dwm.exe' -and $_.Message -match 'Faulting module name:\s*igdumd64.dll' } | Select-Object -First 5 TimeCreated, Id, MachineName, Message
Expected result: No matching Event 1000 records are returned.

8. Confirm issue signature by comparing affected vs control host evidence.
Expected result: Affected POOL-FIN-01 host has Event 1000 plus igdumd64.dll and Event 9009, while POOL-FIN-02 control host has Event 9011 and no matching Event 1000 signature.

If all expected results match, classify this as the known POOL-FIN-01 black-screen incident pattern and proceed to Resolution.

## Resolution

Command-first path for 5 to 10 minute execution.

1. Open Azure CLI and load AVD extension.
Command:
az extension add --name desktopvirtualization --upgrade
Expected result: Extension installs or reports already installed.

2. Set variables for the affected and control pools.
Command:
$RG = "<resource-group-name>"
$HP_BAD = "POOL-FIN-01"
$HP_GOOD = "POOL-FIN-02"
Expected result: Variables are set in current shell.

3. Drain all POOL-FIN-01 session hosts.
Command:
$badHosts = az desktopvirtualization session-host list --resource-group $RG --host-pool-name $HP_BAD --query "[].name" -o tsv
foreach ($h in $badHosts) { az desktopvirtualization session-host update --resource-group $RG --host-pool-name $HP_BAD --name $h --allow-new-session false | Out-Null }
Expected result: All POOL-FIN-01 hosts are set to Allow new sessions = Off.

4. Confirm POOL-FIN-02 has available capacity.
Command:
az desktopvirtualization session-host list --resource-group $RG --host-pool-name $HP_GOOD --query "[].{Name:name,Status:status,AllowNew:allowNewSession,Sessions:sessions}" -o table
Expected result: At least one POOL-FIN-02 host shows Status Available and AllowNew true.

5. Verify drain state in portal at Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts.
Option to check: column Allow new sessions.
Expected result: Every POOL-FIN-01 row shows Allow new sessions = Off.

6. Remediate pilot host display driver.
Portal path: Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > select pilot host > Connect > RDP.
Console path on host: Device Manager > Display adapters > Intel adapter > Properties > Driver.
Action: Uninstall device and select Delete the driver software for this device, then install approved known-good package.
Expected result: Driver Version matches approved baseline on pilot host.

7. Restart pilot host and wait for availability.
Command:
shutdown /r /t 0
Expected result: In Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts, pilot host Status returns to Available.

8. Re-open only the pilot host.
Command:
$pilot = "<pilot-session-host-resource-name>"
az desktopvirtualization session-host update --resource-group $RG --host-pool-name $HP_BAD --name $pilot --allow-new-session true
Expected result: Pilot host shows Allow new sessions = On while all other POOL-FIN-01 hosts remain Off.

9. Validate one pilot login.
Portal path: Azure Portal > Azure Virtual Desktop > Application groups > <desktop app group tied to POOL-FIN-01> > Assignments.
Action: Use assigned test user to connect with AVD client.
Expected result: Desktop loads within 30 seconds and stays connected 5 minutes.

10. Remediate remaining POOL-FIN-01 hosts with the same driver steps as pilot host.
Portal path per host: Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > host > Connect.
Expected result: Each remediated host shows approved driver version and Status Available after restart.

11. Re-open all remediated POOL-FIN-01 hosts.
Command:
$badHosts = az desktopvirtualization session-host list --resource-group $RG --host-pool-name $HP_BAD --query "[].name" -o tsv
foreach ($h in $badHosts) { az desktopvirtualization session-host update --resource-group $RG --host-pool-name $HP_BAD --name $h --allow-new-session true | Out-Null }
Expected result: All POOL-FIN-01 hosts show Allow new sessions = On.

## Verification

1. Verify pool state in portal.
Portal path: Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts.
Options to check: columns Status, Allow new sessions, Sessions.
Expected result: Status = Available and Allow new sessions = On for remediated hosts.

2. Verify no recurrence signature on one remediated host by command.
Command:
$Start = (Get-Date).AddMinutes(-30)
Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000; StartTime=$Start} | Where-Object { $_.Message -match 'Faulting application name:\s*dwm.exe' -and $_.Message -match 'Faulting module name:\s*igdumd64.dll' } | Measure-Object
Expected result: Count = 0.

3. Verify DWM crash exits are absent by command.
Command:
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Desktop Window Manager/Operational'; Id=9009; StartTime=$Start} | Measure-Object
Expected result: Count = 0.

4. Verify session disconnect bursts are absent by command.
Command:
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'; Id=40; StartTime=$Start} | Measure-Object
Expected result: Count = 0 for test window.

5. Verify successful baseline events exist on control pool.
Command on POOL-FIN-02 control host:
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Desktop Window Manager/Operational'; Id=9011; StartTime=$Start} | Select-Object -First 5 TimeCreated, Id, Message
Expected result: Event 9011 records are present.

6. Verify three user logins.
Portal path: Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > each host > User sessions.
Options to check: Session state transitions and stable connected duration.
Expected result: Three separate users connect successfully and remain connected for at least 5 minutes.

## Rollback

Use immediately if symptoms increase after reintroduction.

1. Drain POOL-FIN-01 immediately by CLI.
Command:
$badHosts = az desktopvirtualization session-host list --resource-group $RG --host-pool-name $HP_BAD --query "[].name" -o tsv
foreach ($h in $badHosts) { az desktopvirtualization session-host update --resource-group $RG --host-pool-name $HP_BAD --name $h --allow-new-session false | Out-Null }
Expected result: All POOL-FIN-01 hosts stop accepting new sessions.

2. Confirm rollback state in portal.
Portal path: Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts.
Options to check: Allow new sessions and Sessions columns.
Expected result: Allow new sessions = Off for all rows.

3. Notify active users before forced logoff.
Command:
foreach ($h in $badHosts) {
	$hostName = ($h -split '/sessionHosts/')[1]
	$sessions = az desktopvirtualization user-session list --resource-group $RG --host-pool-name $HP_BAD --session-host-name $hostName --query "[].name" -o tsv
	foreach ($s in $sessions) {
		$sessionId = ($s -split '/userSessions/')[1]
		az desktopvirtualization user-session send-message --resource-group $RG --host-pool-name $HP_BAD --session-host-name $hostName --user-session-id $sessionId --message-title "Service Recovery" --message-body "You will be moved to backup pool. Save work and reconnect in 2 minutes." | Out-Null
	}
}
Expected result: Warning message is sent to active users.

4. Log off active users on affected hosts.
Command:
foreach ($h in $badHosts) {
	$hostName = ($h -split '/sessionHosts/')[1]
	$sessions = az desktopvirtualization user-session list --resource-group $RG --host-pool-name $HP_BAD --session-host-name $hostName --query "[].name" -o tsv
	foreach ($s in $sessions) {
		$sessionId = ($s -split '/userSessions/')[1]
		az desktopvirtualization user-session delete --resource-group $RG --host-pool-name $HP_BAD --session-host-name $hostName --user-session-id $sessionId --yes | Out-Null
	}
}
Expected result: Active sessions on targeted affected hosts are terminated.

5. Confirm backup pool capacity.
Portal path: Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts.
Options to check: Status and Allow new sessions columns.
Expected result: At least one POOL-FIN-02 host is Available with Allow new sessions = On.

6. Keep POOL-FIN-01 drained and halt further changes.
Portal path: Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts.
Option to keep: Allow new sessions = Off.
Expected result: User impact remains contained while engineering re-runs controlled fix.

## Preventive

1. Image release gate for crash signature. Owner: release engineer. Timing: before deployment. Type: automated. [REQUIRES: CI/CD release gate + log query integration]
Pass: canary 60-minute soak has Application Event 1000 count = 0 where Faulting application = dwm.exe and Faulting module = igdumd64.dll; Fail: any count >= 1.
If fail: pipeline blocks promotion, creates incident, and notifies DWP engineer and image owner.

2. A/B control check against unaffected pool. Owner: DWP engineer. Timing: before deployment. Type: manual.
Pass: POOL-FIN-01 canary vs POOL-FIN-02 control in same 30-minute window shows Event 1000 signature = 0, Event 9009 = 0, Event 40 = 0 on canary, and Event 9011 >= 1 on control; Fail: any threshold miss.
If fail: change manager rejects rollout approval and keeps pool drained; automation note: script this as a pre-check job. [REQUIRES: pre-check script process]

3. In-flight rollout monitoring alert. Owner: DWP engineer. Timing: during deployment. Type: automated. [REQUIRES: Azure Monitor scheduled query alerts + action group]
Pass: no alert fires in rollout window; Fail: any of these fire: Event 1000 signature >= 1 in 10 minutes, Event 9009 >= 3 in 10 minutes, or Event 40 >= 5 in 10 minutes.
If fail: freeze rollout, auto-page on-call, and start rollback within 5 minutes.

4. Approved graphics driver baseline enforcement. Owner: image owner. Timing: before and during deployment. Type: automated.
Pass: compliance report shows 100 percent session hosts on approved driver version; Fail: any non-approved version detected.
If fail: non-compliant host is set Allow new sessions = Off and excluded from rotation until remediated. [REQUIRES: configuration compliance tooling]

5. Rollback package readiness control. Owner: release engineer. Timing: before deployment. Type: manual.
Pass: release bundle contains signed rollback installer, checksum file, execution instructions, and tested restore runtime under 5 minutes; Fail: any artifact missing or runtime above 5 minutes.
If fail: deployment cannot start; automation note: add artifact validation in pipeline. [REQUIRES: artifact validation gate]

6. Post-deployment health scorecard gate. Owner: change manager. Timing: after deployment and before change closure. Type: manual. [REQUIRES: shared operations dashboard]
Pass: first 60 minutes meet all thresholds: login success >= 99 percent, Event 1000 signature = 0, Event 9009 = 0, Event 40 = 0; Fail: any threshold breach.
If fail: do not close change, re-enable containment, and assign DWP engineer for immediate re-triage.

7. Rollback trigger threshold policy. Owner: change manager. Timing: during deployment. Type: automated plus manual approval. [REQUIRES: alert-to-runbook trigger]
Pass: no trigger thresholds breached; Fail: Event 1000 signature >= 1 in 10 minutes or more than 3 new black-screen tickets in 15 minutes.
If fail: execute rollback runbook immediately, mark release as failed, and block further rollout rings.

8. Knowledge update and checklist hardening. Owner: service desk lead. Timing: after deployment and after incident closure. Type: manual.
Pass: within 2 business days, update runbook, L1 article, and release checklist with this incident signature and obtain DWP engineer review; Fail: any document missing update.
If fail: change record cannot be formally closed; automation note: enforce a mandatory documentation checklist field in change workflow. [REQUIRES: change workflow field]

## Related

- Day4/T-1013-avd-black-screen-rca.md
- Day4/T-1013-avd-black-screen-hypothesis-ranked.md
- Day4/T-1013-known-error-avd-black-screen-pool-fin-01.md
- Day4/T-1013-avd-black-screen-closure-note.md
- Day5/T-1013-avd-black-screen-runbook.md
