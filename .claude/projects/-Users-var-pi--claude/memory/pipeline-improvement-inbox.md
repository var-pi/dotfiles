---
name: pipeline-improvement-inbox
description: "Rolling queue of pipeline-improvement suggestions — filed by feature-close retrospectives and by the operator, consumed and reconciled by pipeline-maintenance; APPROVAL-GATED items need explicit operator sign-off before implementation"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: b5754bbc-be30-4fea-9c42-56f330fe29c6
  modified: 2026-07-25T19:10:25.802Z
---

Rolling inbox of **pipeline-improvement suggestions**. The `pipeline-retrospector` subagent files
here at feature close (dispatched by `plan-and-dispatch` Phase 6); `pipeline-maintenance` reads this
first (its Intake step), acts on what it can, then **reconciles** — deletes an implemented item,
annotates a deferred one with the reason. An item left here resurfaces next cycle; that is
intentional. Part of the improvement-inbox loop recorded in [[plan-and-dispatch-ecosystem]].

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
now recorded in [[plan-and-dispatch-ecosystem]]); on deferring, append `— deferred: <reason>`.
Never reconcile an `APPROVAL-GATED` item on your own judgement — neither by shipping it nor by
deferring it away.

---

## 2026-07-25 — operator-filed candidates from the FOSS survey (**all `APPROVAL-GATED`**)

Five ideas surfaced by a survey of open-source agentic-development tooling, filed by the operator
to discuss later. **None may be implemented without explicit approval in the session that does it.**
Sourced from external tools, so each needs its own design pass before it fits the ecosystem's
altitude contract — adopting a foreign shape wholesale is how a pipeline acquires machinery that
serves someone else's workflow.

- **A first-class shape for changing an already-shipped contract** (`APPROVAL-GATED`). *Principle:*
  the pipeline has exactly one shape — the new feature — so a change to a contract that already
  exists gets re-planned as if nothing were there, and the diff against the current state is
  nowhere stated. A brownfield change should be able to declare what it **adds, alters, and
  removes** relative to what shipped. *Evidence:* OpenSpec's delta-marked change proposals, the
  lightest of the three spec-driven frameworks surveyed and the only one with a first-class
  brownfield form. *Owning file:* `skills/master-plan/SKILL.md` (the feature brief) and
  `skills/plan-and-dispatch/SKILL.md` (the commit-plan template). *Cost of not doing it:* every
  revision to shipped work is planned as a greenfield feature, so the reviewer cannot check the one
  thing that matters most on a change — what breaks — and the altitude contract's "no competing
  source of truth" rule silently degrades as the second plan restates the first.
- **Fixed, named handoff artifacts between rungs** (`APPROVAL-GATED`). *Principle:* what one rung
  hands the next is currently composed fresh at each dispatch, so its completeness depends on the
  dispatching agent remembering the list. Making the handoff a **named artifact with a fixed
  shape** — as the plan template already is for the commit plan — would make an incomplete handoff
  visible rather than silent. *Evidence:* BMAD-METHOD bakes handoff prompts into the workflow file
  rather than composing them per-transition; it is the framework's organising idea, not a detail.
  *Owning file:* `agents/commit-plan-implementer.md` (its bundles to the writers and the code
  reviewer) and `skills/plan-and-dispatch/SKILL.md` (its bundle to `pipeline-retrospector`).
  *Cost of not doing it:* a bundle that quietly loses a field degrades the receiving agent's output
  with no error anywhere — the exact failure mode the doc-style contract already warns about.
- **A schema check over the ecosystem's own config** (`APPROVAL-GATED`). *Principle:* agent
  frontmatter and `settings.json` are parsed **loose** — an unknown key is dropped, never flagged —
  so a config that has quietly stopped working looks identical to one that works. A validator run
  over `agents/*.md`, `skills/*/SKILL.md` and `settings.json` against the published field tables
  turns that class of silent failure into a loud one. *Evidence:* `reasoning_effort:` sat in all
  seven agents for months, so the two "xhigh" plan reviewers ran at the session default the whole
  time and nothing anywhere said so; `/code-review` and `/verify` failed the same way from the other
  direction. *Owning file:* a new script + the `pipeline-maintenance` post-edit checklist (check 6
  already names the failure but relies on a human remembering to look). *Cost of not doing it:* the
  ecosystem keeps paying for capabilities it is not getting, and only notices by accident.
- **Behavioural regression tests for the agent definitions** (`APPROVAL-GATED`). *Principle:* the
  schema check above catches a dead key; nothing catches a **live rule that stopped biting** — a
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
- **A deterministic static-analysis pass beside the LLM code review** (`APPROVAL-GATED`).
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
