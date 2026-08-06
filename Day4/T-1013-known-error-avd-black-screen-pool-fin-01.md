# Known Error Record - AVD Black Screen (POOL-FIN-01)

Symptom: Users see a black screen immediately after sign-in to AVD. For some users it clears after about 30 seconds; for others sessions disconnect or remain unusable.

Cause: A graphics stack regression introduced by the POOL-FIN-01 image update caused Desktop Window Manager (dwm.exe) to crash in Intel graphics module igdumd64.dll. The observed exception was 0xc0000005.

Scope: The incident affected approximately 40% of users on POOL-FIN-01. POOL-FIN-02 was unaffected.

Workaround: Control or drain user placement on POOL-FIN-01 and shift sign-ins to POOL-FIN-02 to restore access while remediation is applied. This was used during the incident to maintain service availability.

Permanent fix: Apply graphics-path mitigation as needed, correct the graphics driver path on POOL-FIN-01 hosts via rollback/fix, and update the image/host baseline accordingly. Validate host stability and then reopen traffic to POOL-FIN-01.

How to spot it: On affected hosts, look for TerminalServices Event 21 (logon succeeded) followed by Application Error Event 1000 showing dwm.exe faulting in igdumd64.dll, then Desktop Window Manager Event 9009 and TerminalServices Event 40 (disconnect). In this incident, dwm.exe was version 10.0.22621.2861 and igdumd64.dll was version 31.0.101.4146.
