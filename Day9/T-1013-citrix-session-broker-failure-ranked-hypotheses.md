# T-1013: Citrix Session Broker Failure – Ranked Hypotheses

## Incident Summary
- **Affected Pool**: FinBridge-VDI-Pool-02
- **Impact**: 22 of 30 users (73%)
- **Error**: 1030 – 'No machines available in the desktop group'
- **Timeline**: Failure observed 08:58:03; broker timeout at 08:58:34 (30000ms)

---

## Ranked Hypothesis List

### **Hypothesis 1: dc-vdi-02 Broker Service stopped by Windows Update (pending reboot) — MOST PROBABLE**

**Why it fits the evidence:**
- dc-vdi-02 Citrix Broker Service: **STOPPED** (last running yesterday 23:40)
- Windows Update installed today 00:15 with reboot required flag **not yet actioned**
- All 22 unregistered machines in Pool-02 report: `Unable to contact Delivery Controller dc-vdi-02.finbridge.local:80 - connection refused`
- Pool-01 (different DC: dc-vdi-01) shows 95% (19/20) registration success
- Symmetry: 22 unregistered machines = 22 affected users
- No maintenance mode machines, no catalog inconsistency

**Fastest check to confirm:**
```powershell
# Method 1: Service status
Get-Service -Name 'CitrixBrokerService' -ComputerName dc-vdi-02

# Method 2: Port connectivity test
Test-NetConnection -ComputerName dc-vdi-02 -Port 80

# Method 3: Event log (if available)
Get-EventLog -LogName 'System' -ComputerName dc-vdi-02 -Source 'Service Control Manager' -Newest 20
```

**Remediation action if confirmed:**
1. **Reboot dc-vdi-02 immediately** to complete Windows Update
2. Verify Citrix Broker Service starts automatically post-reboot
3. Monitor machine registration recovery (expect ~5–10 minutes)

---

### **Hypothesis 2: Broker Service crashed/hung after update (requires manual restart)**

**Why it fits the evidence:**
- Service stopped but system has not yet been rebooted
- Windows Update may have left Broker Service in hung/crashed state
- Manual service restart may restore functionality without full reboot

**Fastest check to confirm:**
```powershell
# RDP to dc-vdi-02 and:
# 1. Check Services console: services.msc (look for CitrixBrokerService state and error codes)
# 2. Check Event Viewer:
Get-EventLog -LogName 'System' -ComputerName dc-vdi-02 | Where-Object {$_.Source -match 'Broker|Citrix'} | Select-Object -First 10

# 3. Check if process is running:
Get-Process -ComputerName dc-vdi-02 | Where-Object Name -match 'Broker'
```

**Remediation action if confirmed:**
1. RDP to dc-vdi-02
2. Open Services console (`services.msc`)
3. Stop Citrix Broker Service (if hung, may need force-kill via Task Manager)
4. Clear any temp broker locks: `Remove-Item C:\ProgramData\Citrix\Broker\locks -Force` (if exists)
5. Restart Citrix Broker Service
6. Verify service is in 'Running' state
7. Test machine registration recovery

---

### **Hypothesis 3: Broker Service port 80 blocked/reassigned (firewall or port conflict)**

**Why it fits the evidence:**
- Connection refused could indicate port unavailable or firewall rule disabled
- Windows Update sometimes modifies firewall rules or triggers registry changes
- Less likely given Pool-01 (same subnet, likely same firewall policy) is operational

**Fastest check to confirm:**
```powershell
# On dc-vdi-02:
# Check port binding
netstat -ano | findstr :80

# Check Citrix-specific firewall rules
Get-NetFirewallRule -DisplayName '*Citrix*' -Direction Inbound | Select-Object DisplayName, Enabled, Action

# Check if Windows Firewall is blocking Broker port
Get-NetFirewallRule | Where-Object {$_.LocalPort -eq 80 -or $_.DisplayName -match 'Broker'}
```

**Remediation action if confirmed:**
1. If port 80 is bound to wrong service: `Stop-Service -Name <ServiceName>`
2. If Citrix firewall rule is disabled: `Enable-NetFirewallRule -DisplayName 'Citrix Broker Service'`
3. Verify no software firewall (e.g., Kaspersky, McAfee) is blocking port 80
4. Restart Citrix Broker Service
5. Test machine registration recovery

---

## Evidence Weighting

| Evidence | Supports Hyp 1 | Supports Hyp 2 | Supports Hyp 3 |
|----------|---|---|---|
| Service STOPPED | ✓✓ | ✓✓ | ✗ |
| Windows Update today + reboot flag | ✓✓ | ✓ | ✓ |
| Connection refused on port 80 | ✓ | ✓ | ✓✓ |
| Pool-01 operational | ✓ (different DC) | ✓ | ✓ (different DC) |
| Symmetry (22 affected = 22 unregistered) | ✓✓ | ✓✓ | ✓ |

**Conclusion: Hypothesis 1 is most probable** — System reboot to complete Windows Update will restore Broker Service and machine registration.

