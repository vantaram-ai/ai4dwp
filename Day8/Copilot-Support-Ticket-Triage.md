# Copilot Support Ticket Triage
**Prepared by:** DWP Engineer
**Date:** 2026-08-12

---

## Scope

Ranked triage for each ticket using only these cause categories:

- permissions/access boundary
- data indexing lag
- sensitivity label restriction
- license/client prerequisite issue
- guest/external sharing limitation
- genuine Copilot fault

`genuine Copilot fault` is kept as the last resort unless the ticket text rules out the other categories.

---

## Ticket Triage

| ID | Ticket | Likely cause (ranked, most probable first) | Fastest check | Is this actually a Copilot bug? |
|---|---|---|---|---|
| 1 | Finance lead: Copilot won't summarise the Q3 board pack in SharePoint. "It's right there, I can see it myself." | 1. data indexing lag  2. sensitivity label restriction  3. permissions/access boundary  4. license/client prerequisite issue  5. genuine Copilot fault | Check whether the board pack was added, moved, or had permissions/labels changed recently; if so, treat indexing delay as first suspect. | **No**. The user being able to open the file does not prove Copilot can ground on it immediately; recent indexing delay or label-based restriction is more likely than a product bug. |
| 2 | New hire (started yesterday): Copilot in Outlook seems to know nothing about my recent emails. | 1. data indexing lag  2. license/client prerequisite issue  3. permissions/access boundary  4. genuine Copilot fault | Check the user's start date and mailbox activation timing first; if they started yesterday, recent mailbox/content indexing is the fastest explanation to confirm. | **No**. A brand new user with very recent mailbox activity fits indexing delay far better than a Copilot defect. |
| 3 | HR manager: Asked Copilot in Word to pull data from a sensitive salary review spreadsheet, got "I don't have access to that content." | 1. permissions/access boundary  2. sensitivity label restriction  3. license/client prerequisite issue  4. genuine Copilot fault | Verify the HR manager can open the exact spreadsheet directly with their own account. | **No**. The error text itself points first to access boundaries; a sensitivity restriction is the next most plausible non-bug explanation. |
| 4 | Sales rep: Copilot in Teams can't find a client contract that was shared with her via a guest link from another org. | 1. guest/external sharing limitation  2. permissions/access boundary  3. data indexing lag  4. genuine Copilot fault | Confirm whether the contract is only available through a guest/external share from another tenant. | **No**. Cross-tenant guest sharing is a known limitation area and is more likely than a Copilot bug. |
| 5 | IT admin: Copilot suddenly stopped working for the whole Finance team this morning, was fine yesterday. | 1. license/client prerequisite issue  2. permissions/access boundary  3. genuine Copilot fault | Check whether the affected Finance users still have the required Copilot and base M365 licences assigned. | **Unclear**. Tenant-wide scope raises the possibility of a service-side issue, but a licensing or client prerequisite problem affecting the group is still the faster and more probable explanation. |
| 6 | Manager: Copilot found and summarised a file I don't remember ever opening, from a folder I forgot I had access to. | 1. permissions/access boundary  2. data indexing lag  3. genuine Copilot fault | Check the manager's effective permissions on the source folder/file. | **No**. This is exactly how Copilot behaves when a user already has access: it can surface content they were permitted to read even if they forgot it existed. |
| 7 | Analyst: Copilot gives generic answers, doesn't seem to use any of our internal SharePoint content at all. | 1. permissions/access boundary  2. data indexing lag  3. license/client prerequisite issue  4. genuine Copilot fault | Check whether the analyst can open the relevant SharePoint content directly and whether those documents are established, not newly added. | **Unclear**. Generic responses often mean Copilot is not grounding on accessible content, but the ticket does not yet distinguish between missing access, indexing delay, and a broader service problem. |
| 8 | Executive assistant: Copilot in Outlook can't see a shared mailbox's calendar that I manage on behalf of my director. | 1. permissions/access boundary  2. license/client prerequisite issue  3. genuine Copilot fault | Verify whether the assistant is working from delegated/shared mailbox access rather than their own primary mailbox/calendar. | **No**. Delegated or shared mailbox access sits on an access-boundary edge case and is more likely than a core Copilot product bug. |

---

## Short Notes

- Tickets 1 and 2 most strongly fit `data indexing lag` because the content/user context is very recent.
- Tickets 3, 6, and 8 most strongly fit `permissions/access boundary` because the issue depends on what Copilot is allowed to ground on, not whether the user can describe the content.
- Ticket 4 most strongly fits `guest/external sharing limitation` because the source content lives in another organisation's sharing boundary.
- Ticket 5 is the only one where `genuine Copilot fault` is meaningfully on the table, but it still should not be the first assumption.

---

*Document owner: DWP Engineering | Classification: Internal*