# M365 Copilot Readiness — Tiered Priority Ranking
**Department:** Finance (~200 users)
**Reference checklist:** M365-Copilot-Readiness-Checklist-Finance.md
**Prepared by:** DWP Engineer
**Date:** 2026-08-12

---

## Why this document exists

The readiness checklist is a comprehensive task list. This document answers a different question: **if you had to sequence these tasks under time or resource pressure, what order do you work in, and what is genuinely blocking?**

The three tiers below are Finance-specific. The same items might sit in a different tier for a lower-sensitivity department. Context matters.

---

---

## TIER 1 — MUST Complete Before Rollout (Blocking)

> These items are prerequisites. Copilot licences must not be assigned until every item in this tier is complete and signed off. Skipping any of these creates an irreversible or very hard-to-remediate data exposure or compliance failure.

### Permissions & Oversharing Audit *(entire Section 1)*

- [ ] Run SharePoint Permission Reports across all Finance sites and export findings
- [ ] Identify and document all permissions inherited from the 2019 migration
- [ ] Remove all "Everyone", "Everyone except external users", and "All authenticated users" sharing links on Finance content
- [ ] Revoke all anonymous/Anyone sharing links across Finance SharePoint and OneDrive
- [ ] Audit and remediate broad security group memberships not reviewed since 2019
- [ ] Remove access for non-Finance staff without documented business justification
- [ ] Set tenant/site-level default sharing to "Specific people" or internal-only for Finance sites
- [ ] Disable "Anyone" link types for Finance site collections
- [ ] Assign a named active site owner to every Finance site collection
- [ ] Document all findings in a signed-off permissions remediation log

### Identity & MFA Readiness *(critical subset)*

- [ ] Confirm MFA is enforced for all Finance users via Conditional Access (not Security Defaults)
- [ ] Confirm CA policy requires compliant device + MFA for all Finance M365 access — no Finance accounts excluded
- [ ] Remediate all Risky Users and Risky Sign-ins flagged in Entra ID Identity Protection

### Sensitivity Labelling *(minimum viable subset)*

- [ ] Confirm sensitivity labels are published to Finance users
- [ ] Confirm mandatory labelling is enabled in Office apps for Finance users
- [ ] Confirm DLP policies are active and blocking external sharing of `Highly Confidential — Finance` content

---

---

## TIER 2 — SHOULD Complete Before Rollout (High Risk if Skipped)

> These items are not hard technical blockers in the sense that Copilot will not function without them — but skipping them creates significant operational, compliance, or user-experience risk during rollout. They should be completed before the pilot cohort is enabled.

### Licensing

- [ ] Confirm all ~200 Finance users hold an active M365 E5 licence
- [ ] Confirm Copilot add-on licences are procured for the pilot cohort
- [ ] Plan staged licence assignment — pilot group first (~20 users), then full rollout
- [ ] Verify no Finance users remain on legacy E1/E3 licences

### M365 Apps Client Versions

- [ ] Verify all Finance devices run M365 Apps build 2307 (16626) or later
- [ ] Confirm update channel — decide if Semi-Annual Enterprise Channel delay is acceptable for pilot
- [ ] Identify and plan migration for any devices still running Office 2019/2021 perpetual licences
- [ ] Confirm New Teams client is deployed to all Finance devices

### Identity & MFA *(remaining items)*

- [ ] Confirm all Finance accounts are Entra ID cloud or hybrid-synced — no on-premises-only accounts
- [ ] Verify MFA method quality — Microsoft Authenticator preferred; flag any SMS-only MFA users
- [ ] Confirm no Finance user accounts carry persistent admin roles
- [ ] Verify no guest/external accounts have access to Finance sites or M365 groups

### Sensitivity Labelling *(remaining items)*

- [ ] Define and publish the Finance labelling taxonomy (Public / Internal / Confidential — Finance / Highly Confidential — Finance)
- [ ] Enable auto-labelling policies in Purview to detect Finance-sensitive content in SharePoint and OneDrive
- [ ] Confirm Copilot-generated outputs inherit the highest sensitivity label of source content — validate in test
- [ ] Review Copilot interaction log retention settings in Purview

### Ongoing Permissions Governance *(set up before go-live)*

- [ ] Enable Entra ID Access Reviews for Finance SharePoint security groups — schedule quarterly cadence
- [ ] Enable Purview Data Access Governance reports for ongoing oversharing visibility
- [ ] Set sharing link expiry policies on Finance sites (30-day maximum recommended)

### End-User Comms *(pre-launch)*

- [ ] Draft and send pre-launch comms email to Finance users and line managers
- [ ] Publish Finance-specific Copilot quick-start guide

---

---

## TIER 3 — CAN Complete During or After Rollout (Lower Risk)

> These items improve the deployment's long-term sustainability and user adoption but do not expose the organisation to immediate data risk if they are completed during or shortly after go-live rather than before it.

### Licensing

- [ ] Confirm licence assignments are managed via group-based licensing in Entra ID
- [ ] Document the Copilot licence assignment process and approval chain

### M365 Apps

- [ ] Confirm M365 Apps updates are managed via Intune or Configuration Manager — no manual installs
- [ ] Run functional test of Copilot in Word, Excel, PowerPoint, Outlook, Teams on a Finance device

### Identity & MFA

- [ ] Enable SSPR for Finance users if not already active

### Sensitivity Labelling

- [ ] Train Finance users on the labelling taxonomy (can form part of the enablement session)

### End-User Comms & Enablement *(rollout phase)*

- [ ] Schedule and deliver live Copilot enablement session for Finance users
- [ ] Identify 2–3 Copilot champions within Finance
- [ ] Set up feedback channel (Teams channel or shared mailbox) for pilot issues
- [ ] Schedule 4-week pilot review meeting with Finance management and IT

### Governance

- [ ] Draft and publish Finance data access governance policy

---

---

## Why Permissions/Oversharing Is TIER 1 — The Finance-Specific Case

Licensing checks and client version verification are **simpler, faster, and reversible**. You can check a licence report in minutes, assign licences the same day you verify them, and push a client update via Intune overnight. If you get them wrong, you notice immediately: Copilot simply does not appear for the user, or features are missing. No data is at risk. You fix it and move on.

**Permissions are different in every one of the following ways:**

### 1. Copilot is a permissions multiplier, not a search engine
Microsoft Copilot does not index or expose content beyond what a user's permissions already allow. But it **dramatically lowers the effort required to find and surface that content**. A Finance user who has, through 2019 migration inheritance, read access to a payroll spreadsheet or an M&A data room they were never supposed to see — but never found because SharePoint search wasn't prominent — will be handed that content directly by Copilot in response to a natural-language question. The permission existed before; the practical exposure did not. Copilot closes that gap instantly and at scale.

### 2. The 2019 migration is a known, unaudited liability
This is not a hypothetical risk. Permissions were set during a migration seven years ago and have never been reviewed. In that time, staff have joined, left, changed roles, and changed departments. Security groups have drifted. Inheritance chains from parent sites created in a different organisational structure are still active. Nobody currently knows what a Finance user can actually access. That uncertainty alone is sufficient to block Copilot enablement — you cannot responsibly enable a tool that surfaces content at scale when you do not know what content is accessible.

### 3. Finance data categories carry regulatory and legal weight
Payroll data is subject to GDPR as special-category-adjacent personal financial data. Board packs and M&A documents carry legal privilege and market-sensitivity obligations. Client financial data may carry FCA or PRA regulatory obligations depending on the firm's authorisations. An oversharing event in this context is not an internal embarrassment — it is a potential regulatory breach, a legal privilege waiver, or an insider trading risk if M&A content surfaces to the wrong staff member. The consequence of getting this wrong after Copilot is enabled is not fixable by removing a licence.

### 4. Remediation after exposure is not the same as prevention
If Copilot is enabled before the permissions audit and a user receives a summary of a board pack they were not supposed to see, the exposure has already occurred. Removing Copilot's licence does not un-surface that information in the user's memory or undo any action they may have taken on it. Permissions errors are **pre-exposure problems** — they must be fixed before the capability is live, not after.

### 5. Licensing and client version checks take hours; permissions remediation takes weeks
This is the practical sequencing argument. A permissions audit across Finance SharePoint sites with 7 years of inherited, unreviewed access will take time: running reports, triaging findings, engaging site owners, removing access, waiting for confirmation. Licensing can be verified and actioned in a single afternoon. The permissions work must start first and run in parallel with everything else — not be left until last because it seems like a lower-level infrastructure task.

---

### Summary table

| Item | Tier | Reason for tier placement |
|---|---|---|
| Permissions & oversharing audit (2019 migration) | MUST | Unaudited access + Copilot = scaled exposure of sensitive Finance data. Not reversible after the fact. |
| Remove "Everyone" / anonymous links | MUST | Broadest possible exposure vector. Blocks go-live. |
| MFA via Conditional Access | MUST | Account compromise of a Copilot-enabled Finance user = full content access at AI speed. |
| DLP for Highly Confidential content | MUST | Prevents Copilot-generated summaries of regulated data being exfiltrated externally. |
| Licence verification | SHOULD | Fast to fix; Copilot simply won't appear if wrong. No data risk. |
| Client version check | SHOULD | Fast to fix via Intune; functional issue, not a security issue. |
| New Teams deployment | SHOULD | Affects feature availability, not data safety. |
| SSPR enablement | CAN | Operational convenience; no data risk if absent at go-live. |
| Copilot champion programme | CAN | Adoption support; no risk if deferred. |
| Enablement sessions | CAN | User experience item; can run at or after go-live. |

---

*Document owner: DWP Engineering | Linked to: M365-Copilot-Readiness-Checklist-Finance.md | Classification: Internal*
