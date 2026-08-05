---
name: editing-subagent-guideline-files
description: "How to compact/edit agent & subagent guideline files (system prompts, skills) so subagents act precisely"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 685a0512-e644-4ce1-b0c2-2b309b52e7f9
  modified: 2026-07-25T14:42:44.053Z
---

When refactoring agent/subagent guideline files (system prompts, skill agreements) for
compactness, the goal is *precise subagent behavior*, not just fewer tokens.

**Why:** A subagent attends to its prompt rather than studying it. The enemy of precise action
is dilution and ambiguity — a load-bearing rule buried in motivational prose, or the same rule
restated 3–4× with drifting wording (the agent then can't tell if those are one rule or several).

**How to apply — the "operative-why test":** for every sentence ask *does it change what the
agent does in a case we didn't spell out?*
- Keep operative rationale (mistake-preventing "why", e.g. "seed the RNG so a FAIL reads as a
  code change, not an unlucky draw" — the tail is what makes the rule generalize) and decision
  records (rejected-alternative notes).
- Cut purely motivational framing ("the logic of the flow", "the payoff of the split").
- Calibrate by reader model: tersest/imperative-first for weaker models (e.g. Sonnet
  implementer), lighter touch for stronger ones (Opus reviewer), hardest dedup on the most
  capable+most repetitive file.
- Each concern gets ONE owning file/section; others reference it by name (single source of truth).

**Generalize the feedback; never transcribe it (2026-07-25).** Feedback arrives as *examples*
("this sentence is bloat", "I liked this part"); the rule you write must be the *principle extracted
from the example*. A transcribed example gets applied to every case that superficially resembles it.
*Canonical failure:* "I liked the war story" became *include a war story* in `commit-doc-writer`, so
every doc grew one and the device became boilerplate. Corollary: state a rule as a **cap** ("at most
one", "under ~150 lines") — an eager agent honours a bound and inflates an encouragement. Full
statement lives in `skills/pipeline-maintenance/SKILL.md`.

Also: this user cares that the **objective-synthesis step is not skipped** — restate + extend
the user's stated objectives before exploring/editing. See [[pipeline-ecosystem]].
