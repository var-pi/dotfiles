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

## 2026-07-26 — 06-fbm (retrospector)

A six-commit run with **zero operator interventions and zero re-dispatches**; every finding below is
about a rule that was ambiguous or absent, not about an agent performing badly.

- **Who *verifies* a number, not who *writes it down*, is the altitude line.** *Principle:* a planner
  may pin a numeric gate value **when it measured that value against infrastructure that already
  exists and the plan reviewer independently re-measured it**; a value that cannot be measured at plan
  time (the code it would run against is not written yet) stays the implementer's to derive
  theory-first. The current rule bans planner numbers outright and gives no way to distinguish the two
  cases. *Evidence:* every gate threshold in `06-fbm` was measured during planning against the real
  library and re-measured by the reviewer, which caught two wrong ones (a circulant eigenvalue quoted
  at the wrong `n`; a 5 % amplitude gate that sat at ~1.6σ and was widened to 10 %) — deterministic
  gates then reproduced to the digit and stochastic ones landed within ~1–2σ, with no commit
  re-dispatched. *Owning files:* `skills/plan-and-dispatch/SKILL.md` — "What the plan pins" (which
  forbids it) vs. template §6 (which already half-permits it: "pin the near-final starting
  configuration … the run is a check, not a search"); `agents/feature-plan-reviewer.md`, whose "do not
  fault a plan for leaving numbers out" needs its converse — *re-measure every number a plan does
  pin*; `PIPELINE.md` §3's altitude table ("must never contain: numeric bounds and tolerances").
  *Coupling:* this is the **altitude contract** (master-plan ↔ plan-and-dispatch ↔
  commit-plan-implementer) plus the `PIPELINE.md` mirror — a four-file change, and the three files
  currently disagree with each other regardless of which way it is resolved. *Also undocumented:* no
  phase authorizes the planner to **run code** during planning, which is what made the measurement
  possible. *Cost of not doing it:* the practice that produced this run's clean execution is presently
  a rule violation, so the next planner either does it against its own agreement or skips it and hands
  the implementer a costly search.

- **An agent must never return control in a waiting state, and a delegated child that does not return
  is a failure the parent owns.** *Principle:* a subagent has no operator to wait for; if something it
  dispatched fails to come back, it re-dispatches once, else proceeds with that step recorded as
  not-performed — it never hands back mid-workflow, because its dispatcher cannot distinguish "waiting"
  from "done". The symmetric rule belongs upstream: **a dispatch that returns without its commit landed
  is neither success nor failure** — verify the tree yourself and *resume the same session* with the
  verified state, rather than halting the chain or re-dispatching cold. *Evidence:* implementer 04
  returned saying it was waiting for a `commit-code-reviewer` notification that could not arrive (the
  child had been interrupted by an API error); the orphaned reviewer then completed and delivered its
  result to the **orchestrator**. Not a one-off: the same waiting-on-a-child shape stalled *every*
  dispatch of the preceding feature. *Owning files:* `agents/commit-plan-implementer.md` (the
  independent-review section + the handoff section) and `skills/plan-and-dispatch/SKILL.md` Phase 5,
  whose only failure branch today is "halt the chain". *Coupling:* the **independent code review**
  coupling (four files cite that pass) and Phase 5's gating paragraph. *Cost of not doing it:* ~30 min
  and a manual recovery inside a run that is supposed to be unattended, twice in two features — and the
  recovery procedure the planner improvised is written down only in a *project* memory
  (`implementer-stalls-pre-commit`, under the StochasticProcesses project), where `pipeline-maintenance`
  will never read it.

- **A negative control has to be certified to actually fail.** *Principle:* naming a control is not
  proposing one — a plan that specifies a negative control must state what it checked that shows the
  control genuinely violates the hypothesis, and the plan reviewer must verify that independently.
  *Evidence:* review round 1 caught a proposed PSD control, `½(t^H + s^H − |t−s|^H)`, which is exactly
  `R_{H/2}` — a perfectly valid covariance, so the test meant to fail would have passed. *Owning
  file:* `agents/feature-plan-reviewer.md`, review objectives, "Test intent" bullet (it currently says
  "with a negative control", which the bad control satisfied); trigger in
  `skills/plan-and-dispatch/SKILL.md` template §6. *Coupling:* the implementer's "ship a negative
  control per feature" is the third site and should keep saying the same thing. *Cost of not doing it:*
  a control that cannot fail is a green test certifying nothing — the most expensive false assurance
  there is. It was caught here by reviewer diligence, not because any objective directed the check.

- **When a plan knows of a systematic effect that can make a correct implementation look like a failing
  gate, the pass conditions must name it as the first hypothesis — and name the parameters that must
  not be "fixed" in response.** *Principle:* the planner's knowledge of a bias is otherwise lost at the
  dispatch boundary, and the implementer's default response to a marginal gate (enlarge N, widen the
  gate) is exactly wrong when the deviation is a bias rather than scatter. *Evidence:* plan 05's pass
  condition 4 pinned the trapezoid edge term as the first non-bug explanation for gate 05a and forbade
  widening `SE_MULT`; 05a then ran at 2.3× margin in precisely the regime the note anticipated.
  *Owning file:* `skills/plan-and-dispatch/SKILL.md`, Phase 2 template §7 (Pass conditions).
  *Coupling:* the implementer's "a factor-of-2 or convention offset is a bug, never a tuning knob" and
  "fix root causes" — the new clause must read as *diagnosis*, never as licence to retune. *Cost of not
  doing it:* marginal gates get resolved by enlarging the ensemble, which makes a biased gate
  systematically *worse*, and the failure looks like a code defect.

- **The effort estimate must separate agent wall-clock from the heavy run's compute time; only the
  former can support a stall diagnosis.** *Principle:* these are different quantities by an order of
  magnitude, and a stall judgement made against the wrong one is worse than none. *Evidence:* this
  feature's execution budget concluded "a dispatch running past ~10 min of wall clock is a stall"
  — derived from a sub-minute experiment — while all six dispatches legitimately ran 12–32 min; had the
  planner believed its own line it would have interrupted five healthy dispatches. *Owning file:*
  `skills/plan-and-dispatch/SKILL.md` template §0, which today permits "the magnitude of the heavy
  runs, **or** a legitimate wall-clock band", and Phase 5, which then tells the planner to judge a
  stall against that §0 estimate. *Coupling:* `agents/commit-plan-implementer.md` "Respect the commit's
  effort budget" and `PIPELINE.md` §9's stall row. *Cost of not doing it:* a healthy long dispatch gets
  interrupted, or a genuinely stalled cheap commit has no threshold at all — and the ambiguity is in
  the word "or", so it recurs on every feature. (Evidence from one feature; the defect is in the
  wording, not the run.)

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
