# Floor 6 incident post-mortem

## Incident summary
Floor 6 Legal experienced a Monday-morning service disruption after a Friday afternoon rollout of a new document management app. The evidence pointed most strongly to a deployment-related issue on the Win11 + Intune cohort, with a separate security investigation for the Copilot matter exposure report. That conclusion was based on the timing, the shared floor-specific impact, and the mix of symptoms: slow or failed sign-in, missing desktop shortcuts, and one report of a client matter surfacing unexpectedly.

## Security Signal Classification
The Copilot incident must be treated as a security signal, not a software bug. The reason is simple: the user reported possible access to client information they believed they should not have seen, which creates a confidentiality and permissions risk even if the underlying cause later turns out to be a normal access-control issue.

## What we knew and why it mattered
- The issue started after a Friday deployment, so a change-related cause was more likely than a random device fault.
- The symptoms were spread across sign-in and desktop behaviour, which meant the problem was probably not limited to one app screen.
- The Copilot report was separate from the login symptoms, so it needed its own evidence trail.

## Required Reflection
My first instinct was to treat the Floor 6 problem as a generic Win11 profile issue, because missing shortcuts and slow sign-in often look like profile corruption. That instinct was wrong. The evidence that changed my mind was the deployment overlap: the same floor received a new app on Friday afternoon, the symptoms began the following Monday, and the affected users shared a change window that the unaffected cohort did not. Once that pattern appeared, the app rollout became the leading cause to test first.

## Before / After script pivot
The first AI-generated version had a weak assumption and a formatting mistake that I corrected.

### AI-generated first draft
```powershell
$apps += Get-ItemProperty -Path $path -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -and $_.DisplayName -match [regex]::Escape($NameHint) } |
    Select-Object \
        @{ Name = "DisplayName"; Expression = { $_.DisplayName } },
        @{ Name = "DisplayVersion"; Expression = { $_.DisplayVersion } }
```

### Hand-corrected version
```powershell
$apps += Get-ItemProperty -Path $path -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -and $_.DisplayName -match [regex]::Escape($NameHint) } |
    Select-Object 
        @{ Name = "DisplayName"; Expression = { $_.DisplayName } },
        @{ Name = "DisplayVersion"; Expression = { $_.DisplayVersion } },
        @{ Name = "InstallDateParsed"; Expression = { Convert-InstallDate -InstallDate $_.InstallDate } }
```

What I fixed and why: I removed the invalid continuation character, and I added install-date parsing so the rollout timeline can be compared reliably against the incident window.

## Single source documentation
The L1 self-service article and the L2 technical article must both come from the same runbook logic.
- L1 self-service is a plain-language re-expression of the runbook steps: wait, retry, restart, report with name/device/time/symptom, and escalate urgent Copilot exposure immediately.
- L2 technical article is the same runbook in engineer language: confirm deployment footprint, inspect installer and shell signals, compare affected versus unaffected devices, and preserve the security track separately.
- Because both articles share the same source truth, they should never diverge on cause, containment, or escalation path.

## Prevention Note
Implement a mandatory Intune ring-gate check that blocks any Friday afternoon app deployment to Floor 6 unless the deployment has already passed on a pilot device with the same Win11 build and user profile policy set. This would have caught the issue before Monday morning because the ring-gate would have forced a real-device validation on the same platform and profile conditions before the full floor received the app.

## What is still open
- The exact app/version and ring group ID still need to be confirmed.
- The Copilot report still needs permission-trace validation against the underlying source.
- It is still not fully proven whether the rollout alone caused all symptoms, or whether it exposed more than one issue at once.

## Partner note
Floor 6 had a change-related service issue after Friday's software rollout, and we are treating the Copilot report as a separate security matter until the permission trail is checked. We have already isolated the most likely change, compared affected and unaffected devices, and started the evidence review needed to confirm what happened before we say the issue is closed.