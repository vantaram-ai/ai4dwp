# Microsoft 365 Copilot Readiness Checklist — Finance Department
**Organisation:** DWP (Financial Services)
**Department:** Finance (~200 users)
**Prepared by:** DWP Engineer
**Date:** 2026-08-12
**Licensing baseline:** M365 E5 — Copilot add-on not yet assigned

---

> **Risk flag:** SharePoint permissions inherited from a 2019 migration with no audit since. Finance data includes payroll, board packs, M&A documents, and client financial data. Permissions and oversharing checks are designated **CRITICAL — complete before any Copilot licence is assigned.**

---

## How to use this checklist

Work through sections in order. Do **not** assign Copilot licences until all **[CRITICAL]** items are signed off by a named owner. Items marked **[HIGH]** should be resolved before pilot go-live. **[STANDARD]** items should be completed before full rollout.

| Priority | Meaning |
|---|---|
| 🔴 CRITICAL | Blocker — Copilot must not be enabled until resolved |
| 🟠 HIGH | Resolve before pilot; significant risk if skipped |
| 🟢 STANDARD | Good practice; complete before full rollout |

---

---

## SECTION 1 — Permissions & Oversharing Audit
### ⚠️ HIGHEST PRIORITY — Complete before any other section is actioned on Copilot enablement

> Copilot respects Microsoft 365 permissions — it will surface content that users can already access. In this Finance department, permissions inherited from a 2019 migration represent the single biggest data-exposure risk. Copilot will make over-permissioned content discoverable at scale. This section must be fully completed and signed off before licences are assigned.

---

### 1.1 — SharePoint Site & Library Permissions

- [ ] 🔴 **CRITICAL** — Run SharePoint Permission Reports across all Finance sites using SharePoint Admin Centre or Microsoft 365 Assessment Tool (MSAT). Export and review all sites, libraries, and folders for unexpected access.
- [ ] 🔴 **CRITICAL** — Identify all sites/libraries still carrying permissions set during the 2019 migration. Flag any group memberships, broken inheritance, or unique permissions that were never re-validated.
- [ ] 🔴 **CRITICAL** — Remove or re-scope all "Everyone", "Everyone except external users", and "All authenticated users" sharing links found on Finance content (payroll, board packs, M&A, client financials).
- [ ] 🔴 **CRITICAL** — Revoke or convert all anonymous/Anyone sharing links on Finance SharePoint sites and OneDrive accounts.
- [ ] 🔴 **CRITICAL** — Audit and remediate all sites with broad security group membership where membership has not been reviewed since 2019. Remove stale members (leavers, role-changers).
- [ ] 🔴 **CRITICAL** — Identify any SharePoint sites shared with non-Finance internal staff without a documented business justification. Re-scope or remove access.
- [ ] 🔴 **CRITICAL** — Check for Finance content stored in personal OneDrive accounts shared broadly or synced to unmanaged devices. Migrate to governed SharePoint sites.
- [ ] 🔴 **CRITICAL** — Document findings in a permissions remediation log with owner, action taken, and sign-off date.

### 1.2 — OneDrive & Sharing Controls (Tenant / Site Level)

- [ ] 🔴 **CRITICAL** — Confirm tenant-level default sharing settings restrict sharing to "Specific people" or "Only people in your organisation" for Finance-scoped sites. Disable "Anyone" link types for Finance site collections.
- [ ] 🔴 **CRITICAL** — Set expiry policies for sharing links on Finance sites (recommended: 30 days maximum for internal links, disabled for anonymous).
- [ ] 🟠 HIGH — Enable SharePoint sharing notifications so site owners are alerted when content is shared externally.
- [ ] 🟠 HIGH — Review and enforce that Finance SharePoint sites are not set to "Classic" permissions inheritance from pre-migration parent structures.

### 1.3 — Ongoing Permissions Governance

- [ ] 🟠 HIGH — Enable Microsoft Entra ID Access Reviews for security groups used to gate Finance SharePoint sites. Schedule quarterly reviews with Finance line managers as reviewers.
- [ ] 🟠 HIGH — Enable Microsoft Purview Data Access Governance reports (SharePoint Advanced Management or Purview) for ongoing oversharing visibility.
- [ ] 🟠 HIGH — Assign a named SharePoint site owner for every Finance site collection. Sites with no active owner must be remediated or decommissioned before Copilot enablement.
- [ ] 🟢 STANDARD — Document and publish a Finance data access governance policy outlining who can grant access to what, approved by the Finance Director.

---

---

## SECTION 2 — Licensing Prerequisites

- [ ] 🟠 HIGH — Confirm all ~200 Finance users hold an active **Microsoft 365 E5** licence in M365 Admin Centre (Users > Active users > filter by licence).
- [ ] 🟠 HIGH — Confirm **Microsoft 365 Copilot add-on** licences have been procured for the Finance department (minimum: pilot cohort; full: all 200 users for rollout).
- [ ] 🟠 HIGH — Assign Copilot licences only after Sections 1, 3, and 4 are signed off. Use a staged approach — pilot group first (~20 users), then full rollout.
- [ ] 🟢 STANDARD — Verify no Finance users are on legacy licences (E1/E3 without Copilot eligibility) that were missed during E5 migration.
- [ ] 🟢 STANDARD — Confirm licence assignments are managed via group-based licensing in Entra ID (not manually assigned) to ensure consistency and audit trail.
- [ ] 🟢 STANDARD — Document the Copilot licence assignment process and approval chain (who authorises, who assigns, who reviews monthly).

---

## SECTION 3 — Microsoft 365 Apps Client Version Requirements

- [ ] 🟠 HIGH — Verify all Finance user devices are running **Microsoft 365 Apps version 2307 (build 16626) or later** — minimum required for Copilot features. Check via M365 Admin Centre > Reports > Microsoft 365 Apps usage, or Intune device compliance reports.
- [ ] 🟠 HIGH — Confirm Update Channel for Finance devices. Copilot features are delivered first to **Current Channel** and **Monthly Enterprise Channel**. Devices on Semi-Annual Enterprise Channel may receive features with a delay — decide if acceptable for pilot.
- [ ] 🟠 HIGH — Identify any Finance devices running Office 2019/2021 perpetual licences — these do **not** support Copilot. Plan migration to M365 Apps.
- [ ] 🟢 STANDARD — Confirm Microsoft 365 Apps is deployed and managed via Intune or SCCM/Configuration Manager with automatic updates enabled. No manual/offline installs.
- [ ] 🟢 STANDARD — Verify Microsoft Teams desktop client is up to date (New Teams required; classic Teams has limited Copilot integration). Enable via Teams Admin Centre or Intune app policy.
- [ ] 🟢 STANDARD — Test Copilot feature availability in Word, Excel, PowerPoint, Outlook, and Teams on a representative Finance device before pilot launch.

---

## SECTION 4 — Identity & MFA Readiness

- [ ] 🟠 HIGH — Confirm all ~200 Finance user accounts are **cloud-only or hybrid-synced** to Microsoft Entra ID (Azure AD). No on-premises-only accounts eligible for Copilot.
- [ ] 🟠 HIGH — Verify **MFA is enforced** for all Finance users, either via Conditional Access policy or Security Defaults. Given data sensitivity, Conditional Access is strongly preferred over Security Defaults.
- [ ] 🟠 HIGH — Confirm MFA method: Microsoft Authenticator app (push notifications or passwordless) is the recommended method. SMS-based MFA is not recommended for Finance-sensitivity data.
- [ ] 🟠 HIGH — Check Conditional Access policies: ensure Finance users are covered by a policy requiring compliant device + MFA for M365 access. Confirm no Finance accounts are excluded from CA policies.
- [ ] 🟠 HIGH — Review all Finance accounts for signs of Risky Users or Risky Sign-ins in Entra ID Identity Protection. Remediate any flagged accounts before Copilot enablement.
- [ ] 🟢 STANDARD — Confirm no Finance user accounts have persistent admin roles assigned (Finance staff should use standard user accounts; admins should use separate privileged accounts).
- [ ] 🟢 STANDARD — Enable SSPR (Self-Service Password Reset) for Finance users if not already active — reduces helpdesk burden during Copilot rollout.
- [ ] 🟢 STANDARD — Verify guest/external accounts do not have access to Finance sites or M365 groups. Copilot will not be licensed for guests, but oversharing risk remains.

---

## SECTION 5 — Sensitivity Labelling

> Finance data (payroll, board packs, M&A, client financials) must be classified before Copilot is enabled. Copilot can generate and summarise documents; without labels, outputs may not carry correct protections.

- [ ] 🟠 HIGH — Confirm Microsoft Purview sensitivity labels are deployed and published to Finance users in the M365 compliance portal.
- [ ] 🟠 HIGH — Define and publish a minimum labelling taxonomy for Finance, e.g.:
  - `Public`
  - `Internal`
  - `Confidential — Finance`
  - `Highly Confidential — Finance` (for payroll, M&A, board packs, client data)
- [ ] 🟠 HIGH — Enable **auto-labelling policies** in Purview to detect and label Finance-sensitive content (payroll data patterns, financial keywords, client references) in SharePoint and OneDrive.
- [ ] 🟠 HIGH — Enable **mandatory labelling** in Office apps for Finance users — users must apply a label before saving or sending documents.
- [ ] 🟠 HIGH — Confirm DLP (Data Loss Prevention) policies are active for `Highly Confidential — Finance` labelled content: block external sharing, block Teams chat attachments to guests, alert on email send externally.
- [ ] 🟢 STANDARD — Train Finance users on the labelling taxonomy before Copilot go-live (include in end-user comms — see Section 6).
- [ ] 🟢 STANDARD — Review Copilot interaction data retention and audit log settings in Purview. Confirm Copilot interaction logs are retained per your organisation's data retention policy.
- [ ] 🟢 STANDARD — Confirm that Copilot-generated content (summaries, drafts) inherits the highest sensitivity label of the source content — validate this in test scenarios before pilot.

---

## SECTION 6 — End-User Communications & Enablement

- [ ] 🟢 STANDARD — Draft and send a **pre-launch comms email** to Finance users and their line managers: what Copilot is, what it can and cannot access, timeline, and who to contact with questions.
- [ ] 🟢 STANDARD — Communicate clearly to Finance users that **Copilot can only surface content they already have permission to access** — but that the permissions audit has been completed to ensure no unintended content is accessible.
- [ ] 🟢 STANDARD — Publish a **Finance-specific Copilot quick-start guide** covering: how to use Copilot in Outlook, Teams, Word, and Excel; what to do if Copilot returns content they shouldn't see; how to label documents correctly.
- [ ] 🟢 STANDARD — Schedule a **live enablement session** (30–45 min, remote or in-person) for Finance users before or at go-live. Demonstrate key scenarios: summarising meeting notes, drafting finance reports, searching for content.
- [ ] 🟢 STANDARD — Identify **2–3 Copilot champions** within the Finance department (power users willing to advocate and support peers).
- [ ] 🟢 STANDARD — Set up a **feedback channel** (Teams channel or shared mailbox) for Finance users to report issues, unexpected content surfacing, or concerns during the pilot period.
- [ ] 🟢 STANDARD — Schedule a **4-week pilot review meeting** with Finance management, the Copilot champion group, and IT to assess adoption, resolve issues, and confirm readiness for full rollout.

---

## Sign-off

| Section | Owner | Status | Sign-off Date |
|---|---|---|---|
| 1 — Permissions & Oversharing Audit | | | |
| 2 — Licensing Prerequisites | | | |
| 3 — M365 Apps Client Versions | | | |
| 4 — Identity & MFA Readiness | | | |
| 5 — Sensitivity Labelling | | | |
| 6 — End-User Comms & Enablement | | | |
| **Overall — Approved for Copilot Licence Assignment** | | | |

> **Note:** Section 1 (Permissions & Oversharing) sign-off must be obtained from both the DWP IT lead and the Finance Director before Copilot licences are assigned to any user.

---

*Document owner: DWP Engineering | Review cycle: Per deployment phase | Classification: Internal*
