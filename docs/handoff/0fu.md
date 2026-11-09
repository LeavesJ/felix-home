### 0fu. 2026-11-07: who authorizes a change that removes what a need checks

This section records one decision the founder made in the trust-plane revisit. It changes no code. Under direction point 3 it binds from this section until the fold (#490, row 48) lands.

**The question.** Trust-plane design draft 4 §4.3 reads a need's applicability on both the base and the candidate. If a need was ACTIVE on the base and DORMANT on the candidate, the change removed the need's subject. The design calls this `subject_removed`. The need stays in force for that change, and it is cleared in one of two ways:
- its evidence still holds on the candidate;
- an authorized removal exists.

This rule is what stops a change from retiring its own requirements. For example, a reroute that hides an endpoint from discovery would otherwise make that endpoint's authentication need dormant.

**Decided by the founder, 2026-11-07.** "Task intent; you for top." A removal is authorized as follows:
- **TASK_BLOCKING and RELEASE_BLOCKING needs:** by the task's admitted intent, admitted before the work began, which names the removal.
- **AUTHORITY_BLOCKING needs:** by the founder.

Once a change lands with that authorization, the need goes dormant in the normal way.

**Not decided here.** The rest of draft 4 is still under review by the founder and an external reviewer. The working papers are in the memory root, under `designs/2026-11-06-trust-plane-revisit/`.
