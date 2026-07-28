---
name: pipeline-maintenance
description: Edit the planning-pipeline skills, subagents, hooks and cores under ~/.claude without breaking the couplings between them. Use before changing any pipeline file.
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

---

## The workflow, in order

Do these in order; later phases assume the earlier ones are done. Each points at the section
below that details it.

1. **Read the feedback** — the operator's message this session, then [[pipeline-improvement-inbox]].
   See *Intake*.
2. **Read the ground truth** — the two memories above, then the actual files the change touches.
   See *The map* and *The dependency graph*.
3. **Synthesize objectives, then ask.** Restate and extend the stated objectives (see *Editing
   discipline*), then put your open questions to the operator in **one batched round**.
4. **Surface a plan and get approval** via `ExitPlanMode`. **No ecosystem file is edited before
   the operator approves.**
5. **Implement, then run the *Post-edit checklist*.**
6. **Commit and push with `dotfiles-sync`.** See *Phase 6*.

**Phase 3 is bounded, not ritual.** Ask where two readings of the feedback would produce
*materially different edits* — and do everything an answer does not block first, so the questions
arrive together rather than trickling. *Why both halves:* these files govern every future run, so a
misread ships silently and surfaces a feature later; but a question round on unambiguous feedback
trains the operator to skim the one round that mattered.

**Phase 4 is the only gate.** These files are read by nobody but the agents that obey them, so an
unapproved edit changes every future run with no diff review — the same reason
`pipeline-retrospector` may propose but never edit.

## Intake — read the improvement inbox first

Before editing, read [[pipeline-improvement-inbox]] — the memory the `pipeline-retrospector`
subagent files to at feature close (dispatched by `plan-and-dispatch` Phase 6), and that the
operator files to directly. It is a **queue**: act on the relevant items this session, then
**reconcile it** — delete each item you implemented, and annotate each you deliberately deferred
with a one-line reason so it is not re-proposed. An item left untouched resurfaces (the point); an
item silently dropped loses the feedback.

**Except items marked `APPROVAL-GATED`.** Those are the operator's standing agenda, not your
backlog: research one, cost it, bring a concrete proposal — but **do not implement it, and do not
defer it away, without explicit approval in this session.** The marker means the operator wants to
think about the idea, which is not the same as having decided on it, and these files govern every
future run. Reconcile such an item only once they have said so.

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
- `commit-plan-implementer` (Opus, high) — executes one commit plan: **writes the code**, owns
  **all test mechanics and every numeric bound** (derived theory-first), verifies, dispatches
  `commit-code-reviewer`, commits locally (never pushes). Delegates doc *authoring* to the two
  writers.
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
  the reader-time economics, layering (`<details>` folds, front-loading, heading navigability,
  one-section-one-object, and the rule that **a fold buys opt-in, not exemption**), signal hierarchy
  (bold/callouts, used sparingly), denser-form selection **capped at ~5 unbroken prose sentences**,
  the cut list, the **stand-alone bar for figures *and* tables/display blocks**, claim-strength
  calibration, style constraints, weight calibration, handoff. Each writer file carries only its
  audience, sources, sections, and altitude.

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

- **The altitude contract** spans `master-plan` ↔ `plan-and-dispatch` ↔ `commit-plan-implementer`
  ↔ `feature-plan-reviewer` (which enforces it) ↔ `PIPELINE.md` §3 (which mirrors it). Each rung
  owns exactly one thing and copies nothing from another: master-plan owns
  philosophy/decomposition (no signatures, stubs, or tolerances); plan-and-dispatch owns contracts
  + decisions + each test's intent/target/**method class**/**discrimination**; the implementer owns
  code + **all test mechanics** + **every numeric bound**. A copy upstream is a competing source of
  truth. Changing *what a rung owns* means editing all five.
  - **Measurement splits by question, not by rung** — the subtlety most likely to be lost in a
    future edit. The planner may run code at plan time to certify that a gate *discriminates*
    (because that answer can add or delete a commit, and the implementer reading one plan cannot see
    across the set); it writes the margin. Tolerances are never its. Owned by
    `plan-and-dispatch` — "Measuring during planning"; the reviewer's converse duty (re-verify
    discrimination claims, **fault a plan that contains an expression or a tolerance**) is the other
    half and must move with it.
- **The delta / consolidation shape** spans `plan-and-dispatch` template §3 ("Files & delta"),
  `commit-plan-implementer` ("Build only what the increment needs"), and `feature-plan-reviewer`
  ("Declared deltas"). The load-bearing guarantee in all three is the same sentence: **the existing
  test-set must stay green *unmodified* in that commit**, and a legacy test that must change is a
  contract change needing its own step. Weaken it in one place and the other two are promising
  something nothing enforces. (A fuller brownfield form — deltas at *feature* altitude in
  master-plan's briefs — is a separate, still `APPROVAL-GATED` inbox item.)
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
- **The sync step:** Phase 6 depends on `skills/dotfiles-sync/SKILL.md` being present and
  model-invocable, and on the ecosystem files being tracked in the `~/.dotfiles` bare repo. Rename
  or retire that skill and this phase names a capability that no longer exists — post-edit check 6's
  exact silent failure. Untrack a file and the edit stops propagating to other machines with no
  error anywhere; a new ecosystem file must be added to that repo in the same pass that creates it.
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
- **A `description:` says what the thing does and when to reach for it — never how it works.**
  Cap: **~25 words, at most two sentences.** Mechanism in a description ("across a persistent
  session resumed each round") is an abstract of the body that owns the rule, so it is a copy free
  to drift, and it is read in the `/` menu by an operator who wants to know which file this is.
  Keep exactly two things beyond the *what*: the cue distinguishing the file from its **nearest
  neighbour** (`commit-doc-writer` vs `feature-readme-writer`; the three reviewers by altitude),
  and any **caller instruction the dispatcher cannot get right without it** — "one plan at a time",
  "read-only". Those are *what*, not *how*.
- **Calibrate by the file's job, not by model tier.** Every agent now runs Opus, so capability no
  longer differentiates them — what does is what the file is *for*. The implementer's agreement is a
  checklist executed under production pressure: tersest, imperative-first, every rule actionable
  without re-reading. The reviewers' and writers' agreements are judgment instruments: rationale
  earns more room there, because they must generalize to cases nobody enumerated. Hardest dedup on
  the most repetitive file, whichever that is.
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

## Phase 6 — commit and push the change

An edit that stays uncommitted is one machine's local divergence: the ecosystem is distributed
through the `~/.dotfiles` bare repo, so until it is pushed, every other session keeps running the
old rules and nothing anywhere reports the discrepancy. **The run is not finished until the change
is pushed.**

Invoke the **`dotfiles-sync`** skill, which owns that repo's mechanics and its own
confirm-before-push step — do not hand-roll the git commands, and do not add a second gate.

Two scope rules:

- **Commit only the files this session changed.** Name anything else dirty in that repo and leave
  it, so the ecosystem's history reads as a series of deliberate pipeline changes rather than a
  mixed config sweep — which is what makes `git log` on these files a usable record of *why the
  rules are what they are*.
- **The message says which coupling moved and why**, not which files changed. The diff already
  lists the files; only you can state the intent, and that is what a later reader is looking for.
