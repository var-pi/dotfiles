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

Before editing, read [[pipeline-improvement-inbox]] — the memory the `pipeline-retrospector`
subagent files to at feature close (dispatched by `plan-and-dispatch` Phase 6). It is a **queue**:
act on the relevant items this session, then **reconcile it** — delete each item you implemented,
and annotate each you deliberately deferred with a one-line reason so it is not re-proposed. An
item left untouched resurfaces (the point); an item silently dropped loses the feedback.

The retrospector **proposes only** — it never edits an ecosystem file. Applying a change is this
skill's job, with the operator present, because these files govern every future run and an
unattended edit changes them with nobody reading the diff.

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

**Orientation (`~/.claude/PIPELINE.md`, read by humans):**
- The **visual map** — Mermaid diagrams of the lifecycle, the commit inner loop, the guard's
  decision logic, the improvement loop, plus the artifact-path table and file index. **Pointer-only:
  it names the owning file for every rule and states none itself**, so it can never compete with the
  agreements. Mirror-only, so it goes stale silently — see the coupling below.

**Subagents (`agents/*.md`):**
- `master-plan-reviewer` (Opus, xhigh) — reviews the master plan. Persistent across rounds.
- `feature-plan-reviewer` (Opus, xhigh) — reviews the whole feature set as a unit. Persistent
  across rounds.
- `commit-plan-implementer` (Sonnet, high) — executes one commit plan: **writes the code**,
  derives test bounds theory-first, verifies, dispatches `commit-code-reviewer`, commits locally
  (never pushes). Delegates doc *authoring* to the two writers.
- `commit-code-reviewer` (Opus, high, **read-only**) — independent fresh-context review of one
  increment's diff, dispatched by the implementer before it commits. **One-shot per commit**, not
  resumed — so it does *not* read `reviewer-core.md` (that core assumes a session resumed across
  rounds). Reports; never fixes.
- `commit-doc-writer` (Opus, high) — authors the per-commit, maintainer-facing
  `docs/commits/<slug>/<NN>-*.md`. Reads one diff. Does not stage/commit.
- `feature-readme-writer` (Opus, high) — authors the feature's outward-facing showcase
  `README.md`. Dispatched last. Synthesizes the whole feature. Does not stage/commit.
- `pipeline-retrospector` (Opus, high) — reviews the **run**, not the code: dispatched by
  `plan-and-dispatch` Phase 6, files improvement proposals to [[pipeline-improvement-inbox]] and
  returns an operator-facing retrospective. **Writes only that memory** — never an ecosystem file.

**Shared cores (`skills/*-core/SKILL.md`, `user-invocable: false`, **preloaded** into the agents
that list them in their `skills:` frontmatter — not read via a tool call):**
- `skills/reviewer-core/` — the discipline the two **plan** reviewers share (independence,
  objective-list workflow, resumed-not-respawned, converge-don't-circle). Each reviewer file carries
  only its altitude-specific objectives. Deliberately **not** preloaded into `commit-code-reviewer`.
- `skills/writer-core/` — the craft both **doc writers** share: the rushed-team-lead reader and
  the reader-time economics, layering (`<details>` folds, front-loading, heading navigability),
  signal hierarchy (bold/callouts, used sparingly), denser-form selection, the cut list, figure
  embedding + the self-explanatory bar, style constraints, weight calibration, handoff. Each writer
  file carries only its audience, sources, sections, and altitude.

**Hooks (POSIX sh, `#!/bin/sh`):**
- `hooks/pipeline-marker.sh` — arms the marker (and points the repo at these hooks) on
  `SubagentStart`, clears it on `SubagentStop`, both matching `^commit-plan-implementer$` and wired
  in `~/.claude/settings.json`. The guard is therefore live for exactly one dispatch at a time and
  nobody arms it by hand. Never `exit 2` on the disarm path — on `SubagentStop` that blocks the
  subagent from finishing.
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
- **The git-guard quintet:** `hooks/pipeline-marker.sh` + its two `settings.json` wirings (the
  `SubagentStart`/`SubagentStop` matchers on `commit-plan-implementer`) + the three git hooks
  (`pre-commit`, `pre-push`, `commit-msg`) + the implementer's commit conventions + the Phase 5
  paragraph that tells the planner **not** to touch the marker. Rename the implementer and the
  matchers stop matching, silently leaving every commit unguarded — so a rename means editing
  `settings.json` in the same pass. Two sub-couplings to keep in step: (a) the **docs-only
  exemption** lives in `pre-commit`'s logic and
  is described in both plan-and-dispatch (README plan) and the implementer — its file set is
  `README.md` / `CLAUDE.md` / `docs/`, and all three must agree; (b) the **descriptive-message
  rule** lives in `commit-msg`'s check and the implementer's commit conventions — keep the
  threshold described consistently across both.
- **The reviewer resumption protocol:** `plan-and-dispatch` Phase 3 resumes one persistent
  `feature-plan-reviewer` session each round; the reviewer + `reviewer-core` assume exactly that
  ("resumed, not respawned"). Same for `master-plan` ↔ `master-plan-reviewer`. Change how the loop
  resumes → change both sides.
- **The README routing:** the README plan is a full set member (plan-and-dispatch) that the
  implementer dispatches to `feature-readme-writer`; it is docs-only (no commit-doc, exempt from
  the guard). Spans plan-and-dispatch + implementer + feature-readme-writer + pre-commit.
- **The session boundary:** `master-plan` names the next feature and *stops*; the human starts
  `plan-and-dispatch` in a fresh top-level session. master-plan's "never dispatch p-a-d as a
  subagent" rationale (ExitPlanMode gate + budget) depends on p-a-d keeping its Phase 4 human gate;
  if that gate ever changes, revisit the rationale.
- **The shared cores:** an agent that lists a core in its `skills:` frontmatter assumes the content
  arrives preloaded and is *not* duplicated locally. Move a rule into a core → delete it from every
  referrer. Move it out → the referrers must re-inline or re-point. Two harness constraints the
  preload depends on: a core must **not** set `disable-model-invocation: true` (that flag also
  blocks preloading — use `user-invocable: false` to keep it out of the `/` menu), and a **missing
  or renamed core is skipped with only a debug-log warning**, so the agent runs on without it. That
  silent failure is why each core opens by saying it is preloaded and what to do if it is absent,
  and why renaming a core means grepping every `skills:` list.
- **The improvement-inbox loop:** `plan-and-dispatch` Phase 6 *dispatches* `pipeline-retrospector`,
  which *files* proposals to [[pipeline-improvement-inbox]]; this skill's *Intake* step *consumes and
  reconciles* them. Spans four places — the Phase 6 step, the retrospector agreement, this skill's
  Intake, and the [[pipeline-improvement-inbox]] pointer in `MEMORY.md`. Change the memory's name or
  shape, or the retrospector's propose-only boundary, and all four must agree.
- **The independent code review:** the implementer dispatches `commit-code-reviewer` over its own
  diff; `plan-and-dispatch` and `feature-plan-reviewer` both cite that pass as the reason a plan may
  omit code bodies and numeric bounds. Retire or rename it → update all four. **The built-in
  `/code-review` command is not model-invocable** (it fails with `disable-model-invocation`); if a
  future harness restores it, this agent is what it would replace, not supplement.
- **The doc-style contract:** what a doc contains is owned by `commit-doc-writer` /
  `feature-readme-writer` (+ `writer-core.md`); what the *implementer* hands them is owned by the
  implementer's bundle sections. The implementer must pass a **superset** and let the writer select
  — a bundle that dictates content competes with the writer's agreement and wins by accident.
  Changing what docs contain means checking the bundle lists too.
- **The visual map:** `~/.claude/PIPELINE.md` mirrors the map above, the altitude contract, the
  artifact paths, the guard's branch logic and thresholds, the file index (model/effort per agent),
  and the improvement loop. It is a **mirror with no authority** — nothing may be recorded only
  there, because a rule stated in a file that governs nothing still gets read and obeyed, and then
  drifts from the file that does govern. Change any of the mirrored facts → update it in the same
  edit and re-date its "verified against the files" line; a stale diagram is worse than none,
  because it is trusted at a glance.

## Editing discipline

- **Objective-synthesis first (do not skip).** Before editing, restate and *extend* the user's
  stated objectives — the reason for the change and what a correct result looks like. This user
  cares that this step is not skipped. See [[editing-subagent-guideline-files]].
- **Generalize the feedback; never transcribe it.** Operator feedback arrives as **examples** —
  "this sentence is bloat", "I liked this part". The rule you write must be the **principle
  extracted from the example**, never the example promoted to a rule. A transcribed example gets
  applied to every case that superficially resembles it, and the resemblance is usually shallow.
  *Precedent:* "I liked the war story" was written into `commit-doc-writer` as *include a war
  story* — so every doc grew one, and the device that made a single doc interesting became
  boilerplate the reader learned to skip. The correct extraction was *surface the one genuinely
  non-obvious thing, at most one, usually none.* Before writing a rule, ask: **what must it say so
  an agent facing a case the operator never mentioned still does the right thing?**
  Corollaries: praise for a device is not a mandate to use it everywhere; a single complaint may be
  a one-off, so weigh it before it becomes a standing rule; and a rule stated as a **cap or a
  bound** ("at most one", "under ~150 lines") survives contact with an eager agent, whereas one
  stated as an encouragement ("foreground the …") does not.
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
   Sweep for retired vocabulary: `grep -rniE '<retired terms>' ~/.claude/{skills,agents,hooks}`.
2. **No bloat** — no rule restated with drifting wording; nothing that fails the operative-why test.
3. **Everything explicit** — no rule that assumes context living only in a conversation; a cold
   reader of the file can act on it.
4. **Why behind every rule** — each non-obvious rule carries the operative "why" that lets an agent
   generalize it to an unspelled case.
5. **No relics** — no leftover reference to a retired concept, path, tier, or agent. Organic edits
   leave these; find them.
6. **Named capabilities still exist, and named config keys are still read** — every skill, slash
   command, or tool an agreement tells an agent to *use* must actually be invocable by that agent
   today, and every frontmatter/settings key must actually be one the harness parses. The harness
   changes underneath these files, and **both failure modes are silent**: `/code-review` and
   `/verify` became user-triggered-only, and the pipeline ran without its independent-review control
   until a commit doc happened to mention the error; separately, all seven agents carried
   `reasoning_effort:` — never a real key — so the "xhigh" reviewers ran at the session default for
   months with no warning anywhere. Frontmatter parses loose: an unknown key is dropped, not
   flagged. The cheap checks are the session's own available-skills listing (a bundled command
   absent from it is **not** model-invocable, whatever it did last month) and the published
   frontmatter field table; confirm both before an agreement depends on them.
7. **Update the record** — reflect any structural change in [[plan-and-dispatch-ecosystem]] and, if
   the map or a coupling changed, in this skill's *map* and *dependency graph*. Then update
   `~/.claude/PIPELINE.md` for anything it mirrors (flow, ownership, paths, guard logic, models,
   agent roster) and re-date its verified line.
8. **Reconcile the inbox** — delete or annotate every [[pipeline-improvement-inbox]] item this
   session addressed, so it is not re-proposed next cycle.
