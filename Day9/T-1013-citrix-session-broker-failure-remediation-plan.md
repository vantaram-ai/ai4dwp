# T-1013: Citrix Session Broker Failure – Finalized Remediation Plan

## Finalized Hypothesis
**Root Cause: dc-vdi-02 Citrix Broker Service stopped after Windows Update with pending reboot**

**Confidence Level**: HIGH (95%)

**Supporting Evidence**:
- Service status: STOPPED (last running yesterday 23:40)
- Windows Update installed today 00:15 UTC with reboot required flag
- System has not been rebooted since update
- All 22 unregistered Pool-02 machines report connection refused to dc-vdi-02:80
- Pool-01 (different Delivery Controller) shows normal operation (95% registration)
- Exact error: Registration timeout + Error 1030 only on Pool-02

---

## Exact Remediation Steps (Priority Order)

### **Phase 1: Immediate Action (Estimated duration: 15–20 minutes)**

#### Step 1.1: Prepare System
```powershell
# Verify current Broker Service status
Get-Service -Name 'CitrixBrokerService' -ComputerName dc-vdi-02

# Verify Windows Update pending reboot
(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update' -Name 'RebootRequired' -ErrorAction SilentlyContinue).RebootRequired
# Expected: Returns 1 or error (confirming reboot needed)
```

#### Step 1.2: Notify Active Users (if any)
- Check if any users are currently connected to Pool-02 (expected: 0 due to failure, but verify)
- If Pool-01 is in use, ensure administrators understand dc-vdi-02 reboot will not affect it

#### Step 1.3: Reboot dc-vdi-02 (Windows Update Completion)
```powershell
# Schedule graceful reboot (60-second delay allows log persistence)
Restart-Computer -ComputerName dc-vdi-02 -Force -Delay 60

# Alternatively, if remote connection preferred:
# RDP to dc-vdi-02, then:
# - Go to Settings > System > About
# - Click "Restart now" 
# OR via PowerShell on dc-vdi-02:
Restart-Computer -Force
```

**Expected outcome:**
- System reboots → Windows Update completes → Citrix Broker Service auto-starts
- Broker Service listens on port 80
- VDI machines can reconnect to dc-vdi-02

#### Step 1.4: Wait for Boot Completion (5–10 minutes)
- System restart: ~3–5 minutes
- Broker Service initialization: ~2–3 minutes
- Machine re-registration window: ~5–10 minutes from restart

---

### **Phase 2: Verification (During boot completion)**

#### Step 2.1: Monitor Broker Service Recovery (at 5-minute mark post-reboot)
```powershell
# After reboot, verify service is running
do {
    $service = Get-Service -Name 'CitrixBrokerService' -ComputerName dc-vdi-02
    Write-Host "Broker Service status: $($service.Status) at $(Get-Date -Format 'HH:mm:ss')"
    
    if ($service.Status -eq 'Running') {
        Write-Host "✓ Broker Service is running"
        break
    }
    Start-Sleep -Seconds 30
} while ($true)

# Verify port 80 is listening
Test-NetConnection -ComputerName dc-vdi-02 -Port 80 -InformationLevel Detailed
```

**Expected result**: Service Running, port 80 responsive

#### Step 2.2: Check Machine Registration Recovery (at 10-minute mark)
```powershell
# Query Pool-02 machine registration status (via Citrix PowerShell on admin machine)
# Install Citrix PowerShell modules if not present (one-time setup):
# Get-BrokerDesktop -DesktopGroupName 'FinBridge-VDI-Pool-02' | Select-Object MachineName, RegistrationState, Enabled

# OR via Citrix Director:
# 1. Open Citrix Director
# 2. Navigate to Machines > Pool-02
# 3. Verify "Registered" count increases from 3 → target (20–24 of 25)
```

**Expected result**: Registration count rises to 95%+ (20–24 of 25) within 10 minutes

---

### **Phase 3: Post-Remediation Validation (At 15–20 minute mark)**

#### Step 3.1: Session Launch Test
```powershell
# Test session launch from client machine
# Method 1: Citrix Workspace App
# - Open Citrix Workspace
# - Right-click FinBridge-VDI-Pool-02 desktop
# - Click "Connect"
# Expected: Connection succeeds within 30 seconds

# Method 2: Citrix PowerShell (admin/support console)
New-BrokerSession -DesktopGroupName 'FinBridge-VDI-Pool-02' -UserName 'labuser' -Force

# Method 3: Broker SDK PowerShell
Get-BrokerDesktop -DesktopGroupName 'FinBridge-VDI-Pool-02' | 
    Where-Object {$_.RegistrationState -eq 'Registered' -and $_.Enabled -eq $true} | 
    Select-Object MachineName, SessionCount
```

**Expected result**: At least 19+ machines show 'Registered' state; session launch succeeds

#### Step 3.2: Verify Full Pool Restoration
```powershell
# Confirm Pool-02 matches Pool-01 health pattern
$pool02 = Get-BrokerDesktop -DesktopGroupName 'FinBridge-VDI-Pool-02' | 
    Measure-Object -Property RegistrationState | 
    Where-Object {$_.Name -eq 'Registered'}

$pool01 = Get-BrokerDesktop -DesktopGroupName 'FinBridge-VDI-Pool-01' | 
    Measure-Object -Property RegistrationState | 
    Where-Object {$_.Name -eq 'Registered'}

Write-Host "Pool-02 registered: $($pool02.Count) / 25"
Write-Host "Pool-01 registered: $($pool01.Count) / 20"
```

**Expected result**: Pool-02 registered ≥ 19 (76%); Pool-01 unchanged (~19)

---

## Correct Order of Operations (CRITICAL)

| Sequence | Action | Timing | Reason |
|----------|--------|--------|--------|
| 1 | Verify reboot pending (Step 1.1) | 2 min | Confirm diagnosis before action |
| 2 | Notify stakeholders | 1 min | Minimize surprise impact |
| 3 | **Reboot dc-vdi-02** (Step 1.3) | 1 min | Primary remediation action |
| 4 | Wait for boot + Broker startup | 8 min | Allow system to stabilize |
| 5 | Monitor Broker Service (Step 2.1) | 2 min | Confirm startup success |
| 6 | Test machine registration (Step 2.2) | 3 min | Verify registration recovery |
| 7 | **Test end-user session launch** (Step 3.1) | 3 min | Confirm user impact resolved |
| 8 | Full pool health check (Step 3.2) | 2 min | Confirm complete recovery |
| **Total** | | **~22 minutes** | Full resolution + validation |

---

## Verification Check: Confirm Resolution After Remediation

### **Success Criteria (ALL must be met)**

1. **Broker Service Status**
   ```
   ✓ dc-vdi-02 Citrix Broker Service: RUNNING
   ✓ Uptime: > 5 minutes (shows successful restart)
   ✓ Port 80: LISTENING (confirmed via Test-NetConnection)
   ```

2. **Machine Registration Recovery**
   ```
   ✓ Pool-02 Registered machines: ≥ 19 / 25 (76%+)
   ✓ Pool-02 Unregistered machines: ≤ 6 / 25
   ✓ Registration errors in Event Viewer: CLEARED
   ```

3. **Error Resolution**
   ```
   ✓ Session launch error 1030: NO LONGER OCCURS
   ✓ Broker timeout (30000ms exceeded): RESOLVED
   ✓ "Connection refused" errors from machines: STOPPED
   ```

4. **User Impact Resolution**
   ```
   ✓ Affected users (22) can now launch sessions to Pool-02
   ✓ Session launch time: < 60 seconds (normal)
   ✓ No new session failures in Broker logs
   ```

### **Quick Pass/Fail Test (Single Command)**
```powershell
# Run this after 15-minute wait to confirm resolution
$results = @{
    BrokerService = (Get-Service -Name 'CitrixBrokerService' -ComputerName dc-vdi-02).Status
    PortListening = (Test-NetConnection -ComputerName dc-vdi-02 -Port 80).TcpTestSucceeded
    RegisteredMachines = (Get-BrokerDesktop -DesktopGroupName 'FinBridge-VDI-Pool-02' | 
        Where-Object {$_.RegistrationState -eq 'Registered'} | Measure-Object).Count
}

Write-Host "RESOLUTION CHECK:"
Write-Host "Broker Service: $($results.BrokerService) (expect: Running)"
Write-Host "Port 80 listening: $($results.PortListening) (expect: True)"
Write-Host "Registered machines: $($results.RegisteredMachines) / 25 (expect: ≥19)"

if ($results.BrokerService -eq 'Running' -and $results.PortListening -and $results.RegisteredMachines -ge 19) {
    Write-Host "✓ RESOLUTION VERIFIED - Issue is resolved"
} else {
    Write-Host "✗ RESOLUTION INCOMPLETE - Escalate to Citrix support"
}
```

---

## Preventive Action: Stop This Recurring

### **Root Prevention: Windows Update Reboot Enforcement**

#### **Preventive Action 1: Automatic Reboot Policy (Primary)**
```powershell
# Configure Windows Update to auto-reboot without user intervention
# On dc-vdi-02 (and all Delivery Controllers):

# Via Group Policy (preferred for domain-joined systems):
# 1. Open gpedit.msc
# 2. Navigate: Computer Configuration > Administrative Templates > Windows Components > Windows Update
# 3. Set: "Configure Automatic Updates" = "4 - Auto download and schedule the install"
# 4. Set: "No auto-restart with logged-in users" = DISABLED (enforce auto-reboot)
# 5. Set: "Scheduled install day/time" = Off-peak (e.g., 23:00 daily or Sunday 02:00)

# Via PowerShell (if local policy preferred):
$regPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
Set-ItemProperty -Path $regPath -Name 'NoAutoRebootWithLoggedInUsers' -Value 0
Set-ItemProperty -Path $regPath -Name 'AUOptions' -Value 4
Set-ItemProperty -Path $regPath -Name 'ScheduledInstallDay' -Value 0  # Every day
Set-ItemProperty -Path $regPath -Name 'ScheduledInstallTime' -Value 23  # 23:00 (11 PM)
```

#### **Preventive Action 2: Monitoring & Alert**
```powershell
# Create scheduled task to monitor reboot-pending status
# On each Delivery Controller:

$taskName = 'Check-PendingReboot'
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -Command {
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update"
    if ((Get-ItemProperty -Path $regPath -Name RebootRequired -ErrorAction SilentlyContinue).RebootRequired -eq 1) {
        # Send alert: reboot pending for > 4 hours
        Write-EventLog -LogName Application -Source CitrixAdmin -EventId 9999 -EntryType Warning -Message "ALERT: DC pending reboot for >4 hours. Citrix services may be at risk."
    }
}'

$trigger = New-ScheduledTaskTrigger -Daily -At 06:00, 12:00, 18:00  # Check 3x daily
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -RunLevel Highest
```

#### **Preventive Action 3: Change Management Review**
- **Before** any Windows Update deployment:
  1. Schedule reboot during change window (maintenance window)
  2. Notify Citrix team of DC reboot timing
  3. Verify backup Delivery Controller is operational (dc-vdi-01)
  4. Stagger updates (never reboot all DCs simultaneously)

- **After** Windows Update deployment:
  1. Verify Citrix Broker Service is running on ALL DCs
  2. Confirm machine registration rate within 30 minutes
  3. Log reboot completion time in change ticket
  4. Alert escalation if registration not restored within 15 min

#### **Preventive Action 4: Broker Service Health Monitoring**
```powershell
# Add Citrix Broker Service to monitoring/alerting (e.g., SCCM, Nagios, Datadog)
# Alert on: Service NOT running for > 5 minutes outside scheduled maintenance

# Example: PowerShell monitoring function
function Monitor-BrokerService {
    param([string]$ComputerName, [int]$CheckIntervalSeconds = 300)
    
    while ($true) {
        $service = Get-Service -Name 'CitrixBrokerService' -ComputerName $ComputerName -ErrorAction SilentlyContinue
        
        if ($service.Status -ne 'Running') {
            # Alert: send to monitoring system
            Write-EventLog -LogName Application -Source CitrixMonitor -EventId 1001 -EntryType Error -Message "CRITICAL: Broker Service down on $ComputerName"
            Send-Email -To "citrix-admins@company.com" -Subject "ALERT: Broker Service failure on $ComputerName"
        }
        
        Start-Sleep -Seconds $CheckIntervalSeconds
    }
}
```

#### **Preventive Action 5: Redundancy & Failover**
- Ensure **minimum 2 Delivery Controllers** per site (already in place: dc-vdi-01 & dc-vdi-02)
- Configure Citrix Broker for load-balancing across both DCs
- Test failover quarterly: simulate dc-vdi-02 outage, verify Pool-02 sessions route to dc-vdi-01

---

## Implementation Timeline

| Action | Owner | Target Date | Priority |
|--------|-------|-------------|----------|
| Apply remediation (reboot dc-vdi-02) | Citrix Ops | **Immediate** | CRITICAL |
| Verify resolution | Citrix Ops | Within 30 min | CRITICAL |
| Implement auto-reboot policy (GPO) | Infrastructure | Within 1 week | HIGH |
| Deploy monitoring alert for Broker Service | Monitoring Team | Within 3 days | HIGH |
| Review Windows Update schedule with change management | IT Change Board | Within 1 week | MEDIUM |
| Test DC failover | Citrix Ops | Within 2 weeks | MEDIUM |

