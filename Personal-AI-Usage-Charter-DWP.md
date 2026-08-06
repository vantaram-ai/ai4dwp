# Personal AI Usage Charter
## For a DWP Desktop and Endpoint Engineer Using Public AI Assistants

**Date:** 03 August 2026

## Purpose
I use public AI assistants to improve speed and quality of low-risk engineering work while protecting DWP users, services, and data. I remain accountable for every output I use, change I deploy, and decision I make.

## Scope
This charter applies to my day-to-day desktop, endpoint, packaging, scripting, troubleshooting, and support activities when using public AI tools that are not DWP-hosted.

## 1. DWP Tasks Appropriate for Public LLM Help
I will use public AI for tasks where no sensitive data is required and outputs can be independently validated.

Appropriate examples:
- Drafting PowerShell or batch script templates for generic actions such as service checks, file cleanup logic, log rotation, and software uninstall flow.
- Improving script readability, comments, and error handling in code that contains no DWP-specific identifiers or secrets.
- Generating troubleshooting checklists for common endpoint symptoms such as high CPU, failed patching, startup delays, profile issues, and application crashes.
- Explaining command syntax, flags, and tool behavior for Microsoft and cross-platform utilities.
- Drafting knowledge-base notes, ticket updates, handover notes, and standard operating steps from sanitized facts.
- Creating test plans for desktop changes, patch validation, rollback rehearsal, and post-change verification.
- Building regex, parsing logic, and report formatting using synthetic sample data only.

## 2. Tasks Not Appropriate for Public LLM Help
I will not use public AI for tasks that expose protected information, sensitive operations, or decision authority that must remain internal.

Not appropriate examples:
- Sharing or summarizing end-user records, case details, HR details, health information, financial information, or any directly or indirectly identifying citizen data.
- Sharing credentials, tokens, API keys, private certificates, one-time codes, privileged command output, or security tool findings.
- Uploading internal architecture details, endpoint inventories, hostnames, IP ranges, domain structure, VPN details, or vulnerability/incident information.
- Asking AI to decide production change approvals, risk acceptance, exception handling, or policy interpretation on my behalf.
- Pasting raw logs, memory dumps, screenshots, registry exports, or configuration files that may contain identifiers or secrets.
- Using AI outputs directly in production without testing, peer challenge where needed, and change controls.

## 3. Data-Handling Rule for End-User PII and Credentials
**Hard rule:** No end-user PII, no credentials, and no secrets go into public AI tools under any circumstances.

My personal control steps:
- Stop before every prompt and classify data as Public, Internal, or Sensitive.
- If content is not clearly Public, do not paste it.
- Replace real values with synthetic placeholders before asking for help.
- Remove names, National Insurance numbers, emails, phone numbers, addresses, usernames, hostnames, IPs, ticket numbers, and unique IDs.
- Never share passwords, hashes, tokens, cookies, private keys, certificate material, or authentication outputs.
- If a task cannot be completed safely with sanitized data, use internal DWP-approved tools or ask a colleague through approved channels.

## 4. Personal Generate-Then-Verify Rule for Scripts and System Changes
I treat AI output as a draft, never as a final answer.

My mandatory verification flow:
- Generate: Ask AI for a first draft with clear assumptions and safety constraints.
- Read: Review every line to confirm intent, side effects, dependencies, and error paths.
- Test safely: Run first in non-production context using test devices or lab environments.
- Add safeguards: Use dry-run options where possible, bounded scope, logging, and rollback steps.
- Validate outcome: Confirm expected results and check for regressions on endpoint performance, policy compliance, and user impact.
- Approve and document: Record what changed, what was tested, and why it is safe before wider rollout.
- Escalate when high impact: For broad deployment, security-relevant changes, or uncertain behavior, seek peer review and follow formal change control.

## Commitment
I will use public AI to accelerate safe engineering, not to bypass governance. I remain responsible for data protection, technical correctness, operational safety, and user trust.
