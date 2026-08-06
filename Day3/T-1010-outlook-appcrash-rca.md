# T-1010 - Outlook APPCRASH RCA

## Incident Summary

- Application: Microsoft Outlook (`OUTLOOK.EXE`), version `16.0.17126.20132`
- Host OS component involved: `KERNELBASE.dll`, version `10.0.22621.3155`
- Primary failure signal: Access violation (`0xc0000005`)
- Observation window: 2024-03-15 09:14:22 to 09:18:05
- User impact: Outlook repeatedly crashes shortly after launch, disrupting mail/calendar workflow.

## What Each Event ID Records

### Event ID 1000 (Source: Application Error)
This event records that a user-mode process crashed. It captures:
- Faulting application and version
- Faulting module (DLL) and version
- Exception code
- Fault offset within the module
- Process ID/start time/paths
- Crash report GUID

In this incident, Event ID 1000 shows Outlook crashing in `KERNELBASE.dll` with exception `0xc0000005` (access violation), which means the process attempted invalid memory access (read/write/execute).

### Event ID 1001 (Source: Windows Error Reporting)
This event records that Windows Error Reporting (WER) processed a crash and assigned telemetry metadata, including:
- Fault bucket ID (used by Microsoft for crash grouping)
- Event name (for example `APPCRASH`)
- CAB/report packaging status
- Whether a response/remediation was available

In this incident, Event ID 1001 confirms WER classified this as `APPCRASH` and bucketed it for pattern matching.

### Event ID 1026 (Source: .NET Runtime)
This event records a .NET runtime-level fatal exception in the process, including:
- Process/application name
- CLR/.NET Framework version
- Statement that process terminated due to unhandled exception
- Managed exception type

In this incident, Event ID 1026 reports an unhandled `System.AccessViolationException`, consistent with memory corruption or invalid unmanaged memory access surfaced through managed code.

## Reconstructed Sequence of Events (Plain English)

1. At 09:13:44, Outlook starts.
2. At 09:14:22, Outlook crashes (Event 1000). The crash occurs in `KERNELBASE.dll` with access violation `0xc0000005` at offset `0x000000000003a4b2`.
3. Outlook is launched again.
4. At 09:17:45, Outlook crashes a second time with the same signature (same app version, same module, same exception code, same fault offset), indicating a repeatable failure path rather than random instability.
5. At 09:18:01, Windows Error Reporting logs Event 1001 (`APPCRASH`) and creates crash telemetry bucket metadata.
6. At 09:18:05, .NET Runtime logs Event 1026 showing an unhandled `System.AccessViolationException`, confirming fatal exception handling failure in-process.

## Most Likely Cause of the Crash

Most likely cause: a deterministic access violation in Outlook triggered by a managed/unmanaged interaction path (commonly a faulty Outlook add-in, extension, or plugin code path) that results in invalid memory access and process termination.

Why this is most likely:
- Repeated crash with identical signature strongly suggests the same code path is triggered each launch.
- `0xc0000005` is a canonical invalid memory access code.
- Presence of Event 1026 (`System.AccessViolationException`) indicates managed runtime observed a severe memory violation that was not handled.
- Crash happening soon after startup aligns with startup initialization paths, where COM/.NET add-ins are commonly loaded.

Confidence: Medium-High, based on signature consistency and event correlation.

## 5-Why Analysis

### Problem Statement
Outlook crashes repeatedly shortly after startup.

1. Why did Outlook crash?
Because the process hit an access violation (`0xc0000005`) and terminated.

2. Why did it hit an access violation?
Because code executed in-process attempted invalid memory access in a path surfacing through `KERNELBASE.dll` and was not safely recoverable.

3. Why was that code path executed repeatedly?
Because the same startup/runtime action was triggered each launch (same fault offset/signature), indicating deterministic behavior.

4. Why was the exception not contained?
Because the runtime reported an unhandled `System.AccessViolationException` (Event 1026), so exception handling boundaries did not prevent process termination.

5. Why did this reach production user impact?
Because a high-risk in-process integration path (most likely add-in/extension initialization or unmanaged interop call) was allowed to execute at startup without guardrails to isolate failure.

### Root Cause (Most Probable)
A faulty Outlook in-process component path (most likely add-in or interop-dependent extension) caused repeat invalid memory access, producing `0xc0000005` and an unhandled `System.AccessViolationException`, resulting in APPCRASH.

## Evidence Matrix

- Event 1000 (09:14:22): First Outlook crash; access violation in `KERNELBASE.dll`.
- Event 1000 (09:17:45): Second crash with same signature; indicates reproducibility.
- Event 1001 (09:18:01): WER confirms APPCRASH bucketing.
- Event 1026 (09:18:05): .NET runtime confirms unhandled access violation exception.

## Recommended Follow-up Validation

1. Start Outlook in safe mode and compare crash behavior to isolate add-in involvement.
2. Disable COM/.NET add-ins in batches, then re-enable one-by-one to identify offender.
3. Collect and review WER crash dump for call stack at `KERNELBASE.dll+0x3a4b2`.
4. Verify Office build integrity and patch level; run Office repair if needed.
5. If tied to a third-party add-in, update/remove vendor component and monitor for recurrence.

## Analyst Conclusion

The event chain is internally consistent: repeated Application Error 1000 crashes are followed by WER classification (1001) and .NET fatal exception logging (1026). The strongest explanation is a repeatable startup code path in Outlook involving unstable in-process integration (most likely add-in/interop), leading to access violation and process termination.
