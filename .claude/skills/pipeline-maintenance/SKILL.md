---
name: pipeline-maintenance
description: Edit the planning-pipeline ecosystem — the master-plan / plan-and-dispatch skills, their reviewer / implementer / writer subagents, the git-guard hooks, and the shared cores — without breaking the couplings between them. Carries the ecosystem map, the cross-file dependency graph, and the editing discipline. Use whenever you are about to change any of those files, or reason about how such a change ripples.
---

# Pipeline-maintenance working agreement

This skill is for **editing the planning-pipeline ecosystem itself** — the interconnected skills,
subagents, and hooks under `~/.claude/` that turn a project brief into committed code along the
ladder **project → feature → commit**. These files change often and depend on each other in
non-obvious ways; a change to one silently breaks another unless you know the couplings. This
skill carries the **map**, the **dependency graph**, and the **editing discipline** so you edit
them as one coherent system.

Read this first, then the two memories it points to: [[plan-and-dispatch-ecosystem]] (the
point-in-time record of the design and its rationale) and [[editing-subagent-guideline-files]]
(how to compact a guideline file without dulling it). **Before editing, verify the map below
against the actual files** — memories and maps drift; the files are ground truth.

## Intake — read the improvement inbox first

Before editing, read [[pipeline-improvement-inbox]] — the memory where `plan-and-dispatch`
appends per-run pipeline-improvement suggestions at feature close (Phase 6). It is a **queue**:
act on the relevant items this session, then **reconcile it** — delete each item you implemented,
and annotate each you deliberately deferred with a one-line reason so it is not re-proposed. An
item left untouched resurfaces (the point); an item silently dropped loses the feedback.

## The map — what exists and who reads it

Each file is read by a **different model**, which sets how tersely to write it (see *Calibrate by
reader*).

**Skills (main session, Opus):**
- `skills/master-plan/SKILL.md` — the **master planner**. Top altitude: through-line,
  decomposition into **feature briefs**, repo architecture, risk register. Persists to the
  project's `docs/plan/`. Writes no code, signatures, or tolerances.
- `skills/plan-and-dispatch/SKILL.md` — the **feature planner**. Decomposes one feature brief into
  a set of commit plans (one per file); pins contracts + decisions + test *intent/target/method*;
  hardens the set through a review loop; then dispatches each commit. **Writes no code bodies or
  numeric bounds** — the implementer does.
- `skills/pipeline-maintenance/SKILL.md` — **this file**.

**Subagents (`agents/*.md`):**
- `master-plan-reviewer` (Opus, xhigh) — reviews the master plan. Persistent across rounds.
- `feature-plan-reviewer` (Opus, xhigh) — reviews the whole feature set as a unit. Persistent
  across rounds.
- `commit-plan-implementer` (Sonnet, high) — executes one commit plan: **writes the code**,
  derives test bounds theory-first, verifies, `/code-review`s, commits locally (never pushes).
  Delegates doc *authoring* to the two writers.
- `commit-doc-writer` (Opus, high) — authors the per-commit, maintainer-facing
  `docs/commits/<slug>/<NN>-*.md`. Reads one diff. Does not stage/commit.
- `feature-readme-writer` (Opus, high) — authors the feature's outward-facing showcase
  `README.md`. Dispatched last. Synthesizes the whole feature. Does not stage/commit.

**Shared cores (`shared/*.md`, read by the agents that reference them):**
- `shared/reviewer-core.md` — the discipline both reviewers share (independence, objective-list
  workflow, resumed-not-respawned, converge-don't-circle). Each reviewer file carries only its
  altitude-specific objectives.

**Hooks (POSIX sh, `#!/bin/sh`):**
- `hooks/pre-commit` — during a pipeline run, rejects a **code** commit missing its staged
  `docs/commits/` file; **exempts docs-only commits** (nothing staged outside
  `README.md`/`CLAUDE.md`/`docs/`).
- `hooks/pre-push` — during a pipeline run, blocks every push (pushing is a manual human step).
- `hooks/commit-msg` — during a pipeline run, rejects a degenerate commit message (empty, a
  subject under ~15 chars, or subject-only with no body), so the implementer cannot commit without
  a real description.
- All three are marker-gated on `$GIT_DIR/CLAUDE_PIPELINE_ACTIVE` (or `$CLAUDE_PIPELINE`), inert
  otherwise, and chain to any repo-local hook when inactive.

## The dependency graph — what breaks what

Before changing a file, check whether you are touching one of these couplings. **Each spans
multiple files; edit them together or you leave a relic.**

- **The altitude contract** spans `master-plan` ↔ `plan-and-dispatch` ↔ `commit-plan-implementer`.
  Each rung owns exactly one thing and copies nothing from another: master-plan owns
  philosophy/decomposition (no signatures, stubs, or tolerances); plan-and-dispatch owns contracts
  + decisions + test *targets*; the implementer owns code + measured numbers. A copy upstream is a
  competing source of truth. Changing *what a rung owns* means editing all three.
- **The docs/commits path** is **named** by plan-and-dispatch (template §8), **authored** by
  `commit-doc-writer`, **staged + committed** by the implementer, and **enforced** by `pre-commit`.
  Change the path convention or the exemption and all four must agree.
- **The git-guard quintet:** `plan-and-dispatch` Phase 5 (arms/disarms the marker) + the three
  hooks (`pre-commit`, `pre-push`, `commit-msg`) + the implementer's commit conventions. Two
  sub-couplings to keep in step: (a) the **docs-only exemption** lives in `pre-commit`'s logic and
  is described in both plan-and-dispatch (README plan) and the implementer — its file set is
  `README.md` / `CLAUDE.md` / `docs/`, and all three must agree; (b) the **descriptive-message
  rule** lives in `commit-msg`'s check and the implementer's commit conventions — keep the
  threshold described consistently across both.
- **The reviewer resumption protocol:** `plan-and-dispatch` Phase 3 resumes one persistent
  `feature-plan-reviewer` session each round; the reviewer + `reviewer-core.md` assume exactly that
  ("resumed, not respawned"). Same for `master-plan` ↔ `master-plan-reviewer`. Change how the loop
  resumes → change both sides.
- **The README routing:** the README plan is a full set member (plan-and-dispatch) that the
  implementer dispatches to `feature-readme-writer`; it is docs-only (no commit-doc, exempt from
  the guard). Spans plan-and-dispatch + implementer + feature-readme-writer + pre-commit.
- **The session boundary:** `master-plan` names the next feature and *stops*; the human starts
  `plan-and-dispatch` in a fresh top-level session. master-plan's "never dispatch p-a-d as a
  subagent" rationale (ExitPlanMode gate + budget) depends on p-a-d keeping its Phase 4 human gate;
  if that gate ever changes, revisit the rationale.
- **The shared cores:** a file that references a `shared/*.md` core assumes the content is there
  and *not* duplicated locally. Move a rule into a core → delete it from every referrer. Move it
  out → the referrers must re-inline or re-point.
- **The improvement-inbox loop:** `plan-and-dispatch` Phase 6 *appends* pipeline-improvement
  suggestions to [[pipeline-improvement-inbox]]; this skill's *Intake* step *consumes and
  reconciles* them. Change the memory's name or shape → update both the Phase 6 step and the Intake
  step (and the [[pipeline-improvement-inbox]] pointer in `MEMORY.md`).

## Editing discipline

- **Objective-synthesis first (do not skip).** Before editing, restate and *extend* the user's
  stated objectives — the reason for the change and what a correct result looks like. This user
  cares that this step is not skipped. See [[editing-subagent-guideline-files]].
- **The operative-why test.** For every sentence ask: *does it change what the agent does in a
  case we didn't spell out?* Keep operative rationale (the mistake-preventing "why" whose tail
  makes the rule generalize) and decision records (rejected-alternative notes). Cut purely
  motivational framing.
- **Single source of truth.** Each concern gets ONE owning file/section; others reference it by
  name. A rule restated 3–4× with drifting wording reads as several rules — the exact defect to hunt.
- **Calibrate by reader.** Tersest, imperative-first for the weaker model (the Sonnet
  implementer); lighter touch for the stronger ones (Opus reviewers/writers); hardest dedup on the
  most capable + most repetitive file.
- **Preserve decision records.** A rationale carrying its rejected alternative is the most
  expensive, least-recoverable content — it survives a rewrite even when the prose around it does not.

## Post-edit checklist

Run this before declaring an ecosystem edit done:

1. **Consistency** — every coupling above that the change touches is updated on *all* its files.
   Sweep for retired vocabulary: `grep -rniE '<retired terms>' ~/.claude/{skills,agents,shared,hooks}`.
2. **No bloat** — no rule restated with drifting wording; nothing that fails the operative-why test.
3. **Everything explicit** — no rule that assumes context living only in a conversation; a cold
   reader of the file can act on it.
4. **Why behind every rule** — each non-obvious rule carries the operative "why" that lets an agent
   generalize it to an unspelled case.
5. **No relics** — no leftover reference to a retired concept, path, tier, or agent. Organic edits
   leave these; find them.
6. **Update the record** — reflect any structural change in [[plan-and-dispatch-ecosystem]] and, if
   the map or a coupling changed, in this skill's *map* and *dependency graph*.
7. **Reconcile the inbox** — delete or annotate every [[pipeline-improvement-inbox]] item this
   session addressed, so it is not re-proposed next cycle.
