# Copilot Support Ticket Triage — FinBridge Legal Team

---

## Ticket 1 — Paralegal: "I don't have access to that content" on client NDA in SharePoint

**Likely Cause (ranked)**
1. Permissions/access boundary — she has never opened the folder; SharePoint permission inheritance or explicit folder permissions likely exclude her account
2. Sensitivity label restriction — NDAs are typically highly classified; a label-enforced policy may block Copilot from surfacing the file even if she has read rights
3. Data indexing lag — file may not yet be indexed for Copilot semantic search

**Fastest Check**
Ask her to navigate directly to the SharePoint folder in her browser. If she receives an "Access denied" page, this is a permissions issue — Copilot correctly reflects her actual access boundary.

**Is this actually a Copilot bug?**
No. Copilot returns "I don't have access" when the user genuinely lacks file permissions. Heard-about-in-a-meeting ≠ granted access. Expected behaviour.

---

## Ticket 2 — New Associate: Copilot in Outlook can't find case emails

**Likely Cause (ranked)**
1. License/client prerequisite issue — account provisioned this week; Microsoft 365 Copilot licence may not yet be assigned or may still be propagating
2. Data indexing lag — a brand-new mailbox has little or no indexed content; the Microsoft Graph index typically takes 24–72 hours after provisioning to reach full coverage
3. Permissions/access boundary — if case emails live in shared mailboxes she has not been granted delegate access to, Copilot cannot retrieve them

**Fastest Check**
Confirm in the Microsoft 365 Admin Center (Users → Licences) that a Copilot licence is assigned to the account and shows as active, not pending.

**Is this actually a Copilot bug?**
No. New accounts require licence assignment and index warm-up time before Copilot has content to work with. Both are expected operational constraints.

---

## Ticket 3 — Partner: Copilot surfaced a draft settlement from a matter he is not assigned to

**Likely Cause (ranked)**
1. Permissions/access boundary — the matter folder is not properly restricted; the partner likely has broad SharePoint site-level read access that grants implicit access to sub-folders that should be matter-specific
2. Sensitivity label restriction — absence of a label on the draft means no label-enforced access control is in place to prevent surfacing
3. Genuine Copilot fault — unlikely; Copilot surfaces what the user is permitted to access; if permissions are too broad, Copilot will correctly (but problematically) surface the content

**Fastest Check**
Check the SharePoint permissions on the settlement document/folder directly (Site Contents → folder → Manage Access). Verify whether the partner has explicit or inherited access he should not have.

**Fastest Check**
⚠️ This is a **potential data governance/information barrier incident**, not just a support ticket. Escalate to the Information Security or Data Governance team alongside the permissions fix.

**Is this actually a Copilot bug?**
No. Copilot correctly returned content the user had permission to access. The root cause is misconfigured SharePoint permissions or missing information barriers. Copilot behaved as designed.

---

## Ticket 4 — Legal Ops Manager: All 40 Legal team users lost Copilot access this morning

**Likely Cause (ranked)**
1. License/client prerequisite issue — a bulk licence change, group-based licence assignment failure, or subscription event (e.g. renewal lapse, admin error removing the group from the Copilot licence plan) is the most probable cause of a sudden, team-wide outage
2. Permissions/access boundary — an Entra ID group policy change or conditional access policy applied overnight could have blocked the service for the group
3. Genuine Copilot fault — a service-side outage affecting a tenant or region is possible but should be confirmed against the Microsoft 365 Service Health dashboard before assuming

**Fastest Check**
Check Microsoft 365 Admin Center → Billing → Licences and confirm the Copilot licence is still assigned to the Legal team group. Also check Microsoft 365 Service Health for any active incidents.

**Is this actually a Copilot bug?**
Unclear. A team-wide simultaneous loss of access is almost always an admin/licence event rather than a Copilot fault, but a genuine service-side incident cannot be ruled out until the Service Health dashboard is checked.

---

## Ticket 5 — Contract Specialist: Vague, generic answers about contract template clauses

**Likely Cause (ranked)**
1. Data indexing lag — the contract templates library may be recently created, recently moved, or not yet fully crawled by the Microsoft Graph index, so Copilot is answering from training knowledge rather than the actual documents
2. Sensitivity label restriction — a label may be blocking Copilot from reading document content even though the user can open the files manually
3. Permissions/access boundary — if the library requires explicit access and she only has browse-level rights, Copilot can see file metadata but not document content
4. Genuine Copilot fault — unlikely; vague answers when documents are inaccessible is expected degraded behaviour

**Fastest Check**
Open one of the contract templates directly in Word/browser and use Copilot's "Summarise this document" command from within the open file. If that works, the issue is search/index coverage, not the documents themselves.

**Is this actually a Copilot bug?**
No. Copilot falls back to generic responses when it cannot retrieve grounded content. The cause is almost certainly indexing, label, or permission coverage — not a fault in Copilot itself.

---

*Triage completed: 2026-08-12*
