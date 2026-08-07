Title: AVD Black Screen Post-Login (POOL-FIN-01) Runbook  
Version: 1.0  
Date: 07/08/2026  
Author: Giribabu  
reviewed: self  
status: draft  
change: initial version from RCA

# Runbook: AVD Black Screen Post-Login (POOL-FIN-01)

Source RCA: Day4/T-1013-avd-black-screen-rca.md  
Incident pattern: post-login black screen, reconnect loop, or delayed desktop caused by DWM crash in `igdumd64.dll` after image update.

## Prerequisites

1. Access: Azure role with permissions to manage AVD host pools, session hosts, and VM extensions in the affected subscription. **[ELEVATED]**
2. Access: Permission to start drain mode and remove session hosts from rotation in AVD. **[ELEVATED]**
3. Access: Local administrator rights on affected session hosts for driver remediation/rollback actions. **[ELEVATED]**
4. Access: Permission to query Windows Event Logs on affected and control hosts. **[ELEVATED]**
5. Tool: Azure Portal access to Azure Virtual Desktop (or equivalent approved automation tooling).
6. Tool: RDP/AVD admin access path to a session host in POOL-FIN-01.
7. Tool: PowerShell 5.1+ on admin workstation.
8. System scope: Confirm the affected host pool is POOL-FIN-01 and identify one unaffected comparison host in POOL-FIN-02.
9. Data needed: Timestamp window for first user reports (default triage window: incident start minus 30 minutes to plus 60 minutes).
10. Safety prerequisite: Confirm rollback package or known-good graphics driver version is available before making any host change.

## Procedure

Use this exact order. Do not skip steps.

1. In Azure Portal, go to Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts.
Expected result: The Session hosts grid for POOL-FIN-01 is visible and lists all hosts.

2. In the POOL-FIN-01 Session hosts grid, set Allow new sessions to Off for every host. **[ELEVATED]**
Expected result: Every host in POOL-FIN-01 shows Allow new sessions = Off.

3. In Azure Portal, go to Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts.
Expected result: The Session hosts grid for POOL-FIN-02 is visible.

4. In the POOL-FIN-02 Session hosts grid, confirm at least one host shows Status = Available and Allow new sessions = On.
Expected result: At least one POOL-FIN-02 host is available to accept redirected user logins.

5. In Azure Portal, go to Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts, and pick one affected host name (example: SHFIN-01-A) as PilotHost.
Expected result: One specific host is selected and documented as PilotHost for evidence and first remediation.

6. Connect to PilotHost using Remote Desktop Connection (mstsc.exe) with local admin credentials. **[ELEVATED]**
Expected result: An interactive admin desktop session opens on PilotHost.

7. On PilotHost, open Event Viewer at Windows Logs > Application.
Expected result: Application log entries are visible.

8. In Application log, run Filter Current Log with Event IDs = 1000 and Logged = Custom range covering incident start minus 30 minutes through plus 60 minutes.
Expected result: Filtered results show only Event ID 1000 entries in the selected time window.

9. Open the latest Event ID 1000 and confirm General tab contains Faulting application name: dwm.exe.
Expected result: The selected event explicitly names dwm.exe as the faulting application.

10. In the same Event ID 1000 details, confirm Faulting module name: igdumd64.dll and Exception code: 0xc0000005.
Expected result: Both values exactly match igdumd64.dll and 0xc0000005.

11. On PilotHost, open Event Viewer path Applications and Services Logs > Microsoft > Windows > Desktop Window Manager > Operational.
Expected result: Desktop Window Manager Operational log entries are visible.

12. In Desktop Window Manager Operational log, run Filter Current Log with Event IDs = 9009 and the same custom time range.
Expected result: One or more Event ID 9009 entries are present within 0 to 60 seconds of the Event ID 1000 timestamps.

13. On PilotHost, open Event Viewer path Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational.
Expected result: TerminalServices-LocalSessionManager Operational log entries are visible.

14. In TerminalServices-LocalSessionManager Operational log, run Filter Current Log with Event IDs = 21,40 and the same custom time range.
Expected result: At least one sequence exists where Event 21 is followed by Event 40 for the same user session.

15. Connect to one POOL-FIN-02 host (example: SHFIN-02-A), open Windows Logs > Application, and filter Event ID 1000 for the same time range.
Expected result: No Event ID 1000 entry in that window contains both dwm.exe and igdumd64.dll.

16. On PilotHost, open Device Manager > Display adapters > Intel(R) graphics adapter > Properties > Driver tab.
Expected result: Driver Version value is visible and recorded in the incident notes.

17. On PilotHost, uninstall the Intel display adapter driver from Device Manager and select the option Delete the driver software for this device if offered. **[ELEVATED]**
Expected result: The Intel display driver package is removed and the adapter shows a basic display driver or prompts for reinstall.

18. On PilotHost, install the approved known-good Intel graphics driver package from the rollback package source. **[ELEVATED]**
Expected result: Installer exits with success and Device Manager shows the approved driver version.

19. On PilotHost, restart Windows from Start > Power > Restart. **[ELEVATED]**
Expected result: PilotHost returns online in Azure Portal with Session host status = Available.

20. Repeat Steps 16 through 19 on each remaining POOL-FIN-01 host listed in Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts. **[ELEVATED]**
Expected result: Every POOL-FIN-01 host shows the approved known-good driver version.

21. In Azure Portal, set Allow new sessions = On for PilotHost only. **[ELEVATED]**
Expected result: Exactly one POOL-FIN-01 host is open for new sessions.

22. Sign in with one test user through the AVD Windows client and connect to the desktop assigned to POOL-FIN-01.
Expected result: The user sees the desktop within 30 seconds, no black screen appears, and the session stays connected for 5 minutes.

23. In Azure Portal, set Allow new sessions = On for remaining remediated POOL-FIN-01 hosts. **[ELEVATED]**
Expected result: All remediated POOL-FIN-01 hosts are accepting new sessions.

## Verification

Complete all checks before closure.

1. On each remediated POOL-FIN-01 host, open Event Viewer > Windows Logs > Application and filter Event ID 1000 for the last 30 minutes. **[ELEVATED]**
Expected result: Zero events in that period contain both dwm.exe and igdumd64.dll.

2. On each remediated POOL-FIN-01 host, open Event Viewer > Desktop Window Manager > Operational and filter Event ID 9009 for the last 30 minutes. **[ELEVATED]**
Expected result: Event count is 0 on every remediated host.

3. On each remediated POOL-FIN-01 host, open Event Viewer > TerminalServices-LocalSessionManager > Operational and filter Event ID 40 for the last 30 minutes. **[ELEVATED]**
Expected result: Event count is 0 for test-user sessions during the validation window.

4. Perform three user login tests from three different user accounts to POOL-FIN-01 hosts.
Expected result: All three users reach a usable desktop in 30 seconds or less and remain connected for 5 minutes.

5. Check the service desk queue filter Assigned Service = AVD and Keyword = black screen for the last 30 minutes.
Expected result: Zero new tickets are opened for POOL-FIN-01 black-screen symptoms.

6. Attach evidence to the incident record: one screenshot of each log filter result (Application 1000, DWM 9009, LSM 40), one screenshot of POOL-FIN-01 session host status, and timestamps of three successful user tests.
Expected result: Incident record contains all five evidence artifacts and is ready for closure approval.

## Rollback

Use this emergency rollback when symptoms return after reintroduction. Target completion time: under 3 minutes.

1. In Azure Portal, go to Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts. **[ELEVATED]**
Expected result: The POOL-FIN-01 Session hosts grid is visible.

2. In the Session hosts grid, select all hosts, click Allow new sessions, and set value to Off. **[ELEVATED]**
Expected result: Every POOL-FIN-01 host shows Allow new sessions = Off.

3. In Azure Portal, go to Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts. **[ELEVATED]**
Expected result: The POOL-FIN-02 Session hosts grid is visible.

4. In the POOL-FIN-02 Session hosts grid, confirm at least one host shows Status = Available and Allow new sessions = On. **[ELEVATED]**
Expected result: POOL-FIN-02 is ready to accept all new sessions.

5. In Azure Portal, go to Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts, open each host that still has Active sessions, click User sessions, then click Send message. **[ELEVATED]**
Expected result: Message dialog opens for every active session.

6. In each Send message dialog, send title "Service Recovery" and message "You will be moved to backup pool. Save work and reconnect in 2 minutes." **[ELEVATED]**
Expected result: Broadcast warning is sent to all active users on POOL-FIN-01.

7. In the same User sessions view, select each active session and click Log off. **[ELEVATED]**
Expected result: Active session count on every POOL-FIN-01 host becomes 0.

8. In Azure Portal, stay on Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts, and verify each row shows Allow new sessions = Off and Sessions = 0. **[ELEVATED]**
Expected result: All POOL-FIN-01 hosts display Off and 0 in the grid.

9. In Azure Portal, go to Azure Virtual Desktop > Host pools > POOL-FIN-01 > Overview and add note "Emergency rollback active - pool drained to POOL-FIN-02" in incident tracking field/process used by your team. **[ELEVATED]**
Expected result: The incident record clearly shows rollback start time and containment state.

10. Stop here and do not perform driver changes during the 3-minute rollback window.
Expected result: User impact is contained to POOL-FIN-02 while engineering performs controlled root-fix work.

## Notes

- Warning: Do not reopen all POOL-FIN-01 hosts at once; use one-host pilot reintroduction to limit blast radius.
- Warning: Do not close the incident based only on user confirmation; complete log-based verification first.
- Edge case: If POOL-FIN-02 nears capacity during containment, coordinate temporary user throttling with service desk before reopening unstable hosts.
- Edge case: If Event 1000 module differs from `igdumd64.dll`, stop this runbook and open a new hypothesis path because root cause may be different.
- Edge case: If affected hosts show mixed driver versions, remediate all hosts to one approved baseline before reintroduction.
- Related incident artifacts: Day4/T-1013-avd-black-screen-hypothesis-ranked.md, Day4/T-1013-known-error-avd-black-screen-pool-fin-01.md, Day4/T-1013-avd-black-screen-closure-note.md.
