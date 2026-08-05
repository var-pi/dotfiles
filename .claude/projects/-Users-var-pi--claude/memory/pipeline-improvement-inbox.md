---
name: pipeline-improvement-inbox
description: "Rolling queue of pipeline-improvement suggestions — filed by feature-close retrospectives and by the operator, consumed and reconciled by pipeline-maintenance; APPROVAL-GATED items need explicit operator sign-off before implementation"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: b5754bbc-be30-4fea-9c42-56f330fe29c6
  modified: 2026-08-05T16:56:28.471Z
---

Rolling inbox of **pipeline-improvement suggestions**. The `pipeline-retrospector` subagent files
here at feature close (dispatched by `feature-plan` Phase 6); `pipeline-maintenance` reads this
first (its Intake step), acts on what it can, then **reconciles** — deletes an implemented item,
annotates a deferred one with the reason. An item left here resurfaces next cycle; that is
intentional. Part of the improvement-inbox loop recorded in [[pipeline-ecosystem]].

**How to file (retrospector):** add a bullet under a `## <date> — <feature-slug>` heading carrying
the **principle** (the rule that should exist, generalized — never the incident verbatim), the
**evidence** (one line), the **owning file**, and the **cost of not doing it**. Filing nothing is a
fine outcome. Link related design records with [[…]].

**How to file (operator):** the operator files here too, in the same shape. An operator-filed item
may carry the marker **`APPROVAL-GATED`**, which means: *research it, cost it, bring a concrete
proposal — but do not implement it until the operator says so in that session.* This is stronger
than the ordinary Intake license to "act on what you can", and it exists because an idea the
operator wants to think about is not the same as one they have decided on. Treat an
`APPROVAL-GATED` item as a standing agenda entry, not a backlog ticket: it stays in the file,
un-reconciled, until it is explicitly approved and shipped, or explicitly dropped.

**How to reconcile (maintainer):** on implementing a suggestion, delete its bullet (the change is
now recorded in [[pipeline-ecosystem]]); on deferring, append `— deferred: <reason>`.
Never reconcile an `APPROVAL-GATED` item on your own judgement — neither by shipping it nor by
deferring it away.

**Where this file lives, and why that matters.** The one path is
`~/.claude/projects/-Users-var-pi--claude/memory/pipeline-improvement-inbox.md`. A retrospector once
filed six well-argued items to the *project's* memory directory instead; `/pipeline-maintenance`
does not read there, and they sat unseen until someone went looking. **Never create a second inbox** —
if you cannot resolve the path from your bundle, use the absolute one above.

---

*(The `2026-07-26 — 06-fbm` retrospector block was fully reconciled on 2026-07-28 — all five items
shipped. The altitude one shipped in a **narrower** form than proposed: the planner may measure only
to certify that a gate *discriminates* and writes the **margin**, never a tolerance; every
`atol`/`rtol`/SE-multiple/sample size is the implementer's. See [[pipeline-ecosystem]].)*

*(The `2026-08-04 — 07-sde-bridge` block — six items, filed to the wrong directory — was merged here
and **fully reconciled on 2026-08-05**: all six shipped. Two were folded into larger changes rather
than shipped as written — the marginal-gate protocol became part of the Opus-5 implementer
re-baseline, and the late/misrouted-result item was split across the implementer's merge half and
`feature-plan` Phase 5's relay half. See [[pipeline-ecosystem]].)*

---

## 2026-07-25 — operator-filed candidates from the FOSS survey (**all `APPROVAL-GATED`**)

Five ideas surfaced by a survey of open-source agentic-development tooling, filed by the operator
to discuss later. **None may be implemented without explicit approval in the session that does it.**
Sourced from external tools, so each needs its own design pass before it fits the ecosystem's
altitude contract — adopting a foreign shape wholesale is how a pipeline acquires machinery that
serves someone else's workflow.

*(**2026-07-28:** the operator worked all five. Three shipped and are deleted — the
feature-altitude brownfield delta, the fixed handoff artifacts as the new `handoff-core`, and the
config schema check as `skills/pipeline-maintenance/validate-config.sh`; see
[[pipeline-ecosystem]]. The two below were **deferred by the operator**, not by a
maintainer's judgement, and keep their marker: they are still gated if reopened.)*

- **Behavioural regression tests for the agent definitions** (`APPROVAL-GATED`)
  **— deferred 2026-07-28 by the operator ("pass on this for now").** It is a project rather than
  an edit: a new dependency, real API spend per CI run, and LLM variance that tends to get
  assertions loosened until they assert nothing. Reopen scoped to three or four cap-shaped
  assertions, or not at all. *Principle:* the
  schema check now shipped catches a dead key; nothing catches a **live rule that stopped biting** — a
  core compacted until a discipline is merely implied, a cap softened into an encouragement. Pinning
  a handful of observable behaviours (the reviewer emits its justified objective list before any
  finding; the implementer never attempts a push; a docs-only commit is exempted) as assertions run
  in CI would fail the edit rather than the next feature run. *Evidence:* `promptfoo` — open source,
  has a Claude Agent SDK provider and can forward subagent transcripts to assert against what a
  subagent actually did. *Owning file:* a new test suite beside the ecosystem files; conceptually
  owned by `skills/pipeline-maintenance/SKILL.md`, since it is what makes the editing discipline
  enforceable rather than aspirational. *Cost of not doing it:* every rule in ~2,500 lines is
  enforced only by the next agent reading it carefully, and a dulled rule is invisible until a run
  goes wrong. Note the known trap first: a rule stated as a **cap** is assertable, one stated as an
  encouragement is not — so this would also be a forcing function on how rules are written.
- **A deterministic static-analysis pass beside the LLM code review** (`APPROVAL-GATED`)
  **— deferred 2026-07-28 by the operator ("pass on it for now").** Check before reopening:
  Semgrep is not believed to support Julia, which is what these projects are mostly written in — if
  so the item largely evaporates and the real candidates are Julia-native (JET.jl, Aqua.jl) wired
  into the implementer's verification order instead.
  *Principle:* `commit-code-reviewer` re-derives the same mechanical checks on every commit at Opus
  prices and with an LLM's variance, while the checks that *can* be expressed as rules should be
  run as rules — freeing the model pass for the judgement only it can make (does this test actually
  bite?). *Evidence:* Semgrep — open source, self-hostable, rule-based. *Owning file:*
  `agents/commit-plan-implementer.md` (verification order) and `agents/commit-code-reviewer.md`
  (which must then stop claiming the mechanical objectives as its own, or the two compete).
  *Cost of not doing it:* mechanical defects are caught non-deterministically and expensively, and
  the review's scarce attention is spent where a linter would do.

---

## 2026-07-24 — deferred candidates (evaluated during the 05-bm-scaling-limit tune-up)

- Standalone **API-doc artifacts** so an agent needn't scan whole implementation files — deferred:
  the plan's pinned **contract surface** already serves this for the implementer; build only if a
  future run shows implementation-file reads are a real token sink (context is not the bottleneck).
- Route **Explore** onto a cheaper model than the session's Opus — deferred: Explore was ~35k
  (right-sized), so there is nothing worth changing. *Correction 2026-07-25:* the stated reason
  ("its model is harness-controlled") is **wrong** — the `Agent` tool takes a per-invocation `model`
  parameter that overrides any agent's model, so `Agent(subagent_type: "Explore", model: "haiku")`
  is available whenever the survey is ever large enough to matter. The right-sizing reason stands.
- A dedicated **planner context-offload subagent** — still deferred *as context relief* (planner
  context peaked at ~33%; context is not the bottleneck). Partly overtaken 2026-07-25: Phase 6's
  retrospective moved to the new `pipeline-retrospector` subagent — but for **independence**, not
  context, since the planner reviewing its own run is the author's account.
