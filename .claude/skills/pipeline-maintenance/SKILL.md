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

Read this first, then the two memories it points to: [[pipeline-ecosystem]] (the
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
subagent files to at feature close (dispatched by `feature-plan` Phase 6), and that the
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

**Read [[pipeline-metrics]] alongside the inbox.** The inbox says what someone thought went wrong;
the metrics say what the last change actually did to cost, turns and review rounds. A proposal that
the numbers contradict is the most valuable thing either file can give you, and it is invisible if
you read only one of them.

## The map — what exists and who reads it

Each file is read by a **different model**, which sets how tersely to write it (see *Calibrate by
reader*).

**Skills (main session, Opus):**
- `skills/project-plan/SKILL.md` — the **project planner**. Top altitude: through-line,
  decomposition into **feature briefs**, repo architecture, risk register. Persists to the
  project's `docs/plan/`. Writes no code, signatures, or tolerances.
- `skills/feature-plan/SKILL.md` — the **feature planner**. Decomposes one feature brief into
  a set of commit plans (one per file); pins contracts + decisions + test *intent/target/method*;
  hardens the set through a review loop; then dispatches **one commit per session** (Phases 1–4 run
  once; Phase 5 runs per session). **Writes no code bodies or numeric bounds** — the implementer does.
- `skills/pipeline-maintenance/SKILL.md` — **this file**. Ships two scripts beside it:
  `validate-config.sh` (POSIX sh) — the mechanical half of post-edit check 6, also run by
  `feature-plan` Phase 1 — and `pipeline-stats.py` (Python 3), which reads the transcripts to say
  what a run actually cost. They answer different questions: the validator asks *is the config
  still wired*, the stats script asks *did the last change help*.

**Orientation (`~/.claude/PIPELINE.md`, read by humans):**
- The **visual map** — Mermaid diagrams of the lifecycle, the commit inner loop, the guard's
  decision logic, the improvement loop, plus the artifact-path table and file index. **Pointer-only:
  it names the owning file for every rule and states none itself**, so it can never compete with the
  agreements. Mirror-only, so it goes stale silently — see the coupling below.

**Subagents (`agents/*.md`):**
- `project-plan-reviewer` (Opus, xhigh) — reviews the project plan. Persistent across rounds.
- `feature-plan-reviewer` (Opus, xhigh) — reviews the whole feature set as a unit. Persistent
  across rounds.
- `commit-plan-implementer` (**Sonnet, xhigh** — the planner may override to Opus per commit via
  template §0) — executes one commit plan: **writes the code**, owns **all test mechanics and every
  numeric bound** (derived theory-first), verifies, dispatches `commit-code-reviewer`, commits
  locally (never pushes). Delegates doc *authoring* to the two writers. The most expensive node by
  far: 35–60% of a feature's tokens, scaling as ~turns^1.5, so a rule that adds turns here costs
  more than the same rule anywhere else.
- `commit-code-reviewer` (Opus, high, **read-only**) — independent fresh-context review of one
  increment's diff, dispatched by the implementer before it commits. **One-shot per commit**, not
  resumed — so it does *not* read `reviewer-core.md` (that core assumes a session resumed across
  rounds). Reports; never fixes.
- `commit-doc-writer` (Opus, high) — authors the per-commit, maintainer-facing
  `docs/commits/<slug>/<NN>-*.md`. Reads one diff. Does not stage/commit.
- `feature-readme-writer` (Opus, high) — authors the feature's outward-facing showcase
  `README.md`. Dispatched last. Synthesizes the whole feature. Does not stage/commit.
- `pipeline-retrospector` (Opus, high) — reviews the **run**, not the code: dispatched by
  `feature-plan` Phase 6, measures the run with `pipeline-stats.py`, appends a row to
  [[pipeline-metrics]], files improvement proposals to [[pipeline-improvement-inbox]], and returns
  an operator-facing retrospective. **Writes only those two memories** — never an ecosystem file.

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
- `skills/handoff-core/` — the four agent-to-agent **bundle** field sets (code-review, commit-doc,
  feature-README, retrospective) plus the protocol both ends follow: sender writes every field
  including `none`, receiver names any gap in its handback and proceeds rather than stalling.
  Preloaded into the implementer and the four receivers. **`feature-plan` cannot preload it**
  — `skills:` is a subagent-only frontmatter field — so the planner invokes it via the `Skill`
  tool at Phase 6.

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

- **The altitude contract** spans `project-plan` ↔ `feature-plan` ↔ `commit-plan-implementer`
  ↔ `feature-plan-reviewer` (which enforces it) ↔ `PIPELINE.md` §3 (which mirrors it). Each rung
  owns exactly one thing and copies nothing from another: project-plan owns
  philosophy/decomposition (no signatures, stubs, or tolerances); feature-plan owns contracts
  + decisions + each test's intent/target/**method class**/**discrimination**; the implementer owns
  code + **all test mechanics** + **every numeric bound**. A copy upstream is a competing source of
  truth. Changing *what a rung owns* means editing all five.
  - **Measurement splits by question, not by rung** — the subtlety most likely to be lost in a
    future edit. The planner may run code at plan time to certify that a gate *discriminates*
    (because that answer can add or delete a commit, and the implementer reading one plan cannot see
    across the set); it writes the margin. Tolerances are never its. Owned by
    `feature-plan` — "Measuring during planning"; the reviewer's converse duty (re-verify
    discrimination claims **and the mechanism story attached to them**, **fault a plan that contains
    an expression or a tolerance**) is the other half and must move with it.
  - **The model override rides the same rung.** Template §0 lets the planner mark a commit
    `model: opus`; the criterion is *load-bearing mathematics*, which is an altitude judgement the
    planner is uniquely placed to make (it sees the whole set) and the implementer structurally
    cannot (it sees one plan). Spans `feature-plan` §0 ↔ Phase 5's dispatch line ↔
    `commit-plan-implementer`'s frontmatter default ↔ `feature-plan-reviewer`'s discrimination
    objective. **There is no effort override** — the Agent tool takes `model` only — so any text
    offering one is naming a capability that does not exist.
- **The delta / consolidation shape** spans `feature-plan` template §3 ("Files & delta"),
  `commit-plan-implementer` ("Build only what the increment needs"), and `feature-plan-reviewer`
  ("Declared deltas"). The load-bearing guarantee in all three is the same sentence: **the existing
  test-set must stay green *unmodified* in that commit**, and a legacy test that must change is a
  contract change needing its own step. Weaken it in one place and the other two are promising
  something nothing enforces. **The feature-altitude half spans two more files:** project-plan's
  brief field 8 (*Delta*) and `project-plan-reviewer`'s "Declared deltas" objective, joined by
  feature-plan Phase 2's "carry a brief's delta down into the set". Its two bounds are what
  keep it from collapsing into the rung below — a brief **names modules, never signatures**, and it
  must **name every shipped guarantee it intends to break**, since that is precisely the change the
  green-unmodified test-set cannot cover. Loosen either and the brief starts competing with the
  commit plans.
- **The docs/commits path** is **named** by feature-plan (template §8), **authored** by
  `commit-doc-writer`, **staged + committed** by the implementer, and **enforced** by `pre-commit`.
  Change the path convention or the exemption and all four must agree.
- **The git-guard quintet:** `hooks/pipeline-marker.sh` + its two `settings.json` wirings (the
  `SubagentStart`/`SubagentStop` matchers on `commit-plan-implementer`) + the three git hooks
  (`pre-commit`, `pre-push`, `commit-msg`) + the implementer's commit conventions + the Phase 5
  paragraph that tells the planner **not** to touch the marker. Rename the implementer and the
  matchers stop matching, silently leaving every commit unguarded — so a rename means editing
  `settings.json` in the same pass. Two sub-couplings to keep in step: (a) the **docs-only
  exemption** lives in `pre-commit`'s logic and
  is described in both feature-plan (README plan) and the implementer — its file set is
  `README.md` / `CLAUDE.md` / `docs/`, and all three must agree; (b) the **descriptive-message
  rule** lives in `commit-msg`'s check and the implementer's commit conventions — keep the
  threshold described consistently across both.
- **The reviewer resumption protocol:** `feature-plan` Phase 3 resumes one persistent
  `feature-plan-reviewer` session each round; the reviewer + `reviewer-core` assume exactly that
  ("resumed, not respawned"). Same for `project-plan` ↔ `project-plan-reviewer`. Change how the loop
  resumes → change both sides.
- **The README routing:** the README plan is a full set member (feature-plan) that the
  implementer dispatches to `feature-readme-writer`; it is docs-only (no commit-doc, exempt from
  the guard). Spans feature-plan + implementer + feature-readme-writer + pre-commit.
- **The session boundary:** `project-plan` names the next feature and *stops*; the human starts
  `feature-plan` in a fresh top-level session, **bare — no plan path, no feature name**.
  project-plan's "never dispatch p-a-d as a subagent" rationale (ExitPlanMode gate + budget) depends
  on p-a-d keeping its Phase 4 human gate; if that gate ever changes, revisit the rationale. What
  crosses the boundary is written, not spoken: the project plan at `docs/plan/` plus the state block
  below. Both ends must agree on both — project-plan seeds the block (workflow step 4) and p-a-d
  derives its feature from it.
- **The project-state record:** the pipeline-state block in the *project's* `CLAUDE.md` is
  **written** by `feature-plan` at four points (Phase 4 opens the feature and records the plan-set
  path, **every Phase 5 dispatch updates the landed count**, Phase 5's failure path records where a
  run stopped, Phase 6 closes it), **seeded** by `project-plan` step 4, and **read** by
  `feature-plan`'s own *How you are invoked*. It rides `pre-commit`'s docs-only exemption, so the
  planner can commit it mid-run. Six places must agree on one shape; change the shape and the bare
  invocation silently starts reading a format nothing writes — and its failure mode is not an error
  but a plausible wrong feature.
  - **This block is now load-bearing, not merely informative.** Under one-commit-per-session it is
    the *only* thing carrying a run between sessions: which commit is next, and **where the approved
    plan set lives**. Drop the path field and a continuing session can name the right commit and
    still not find its plan; drop the count and it re-dispatches work already on disk. The two
    writes to defend in any future compaction are the per-dispatch count and the failure record —
    both fire unattended, and a stopped feature that looks identical to a finished one is what sends
    the next invocation past a half-built feature into the next one.
- **The shared cores:** an agent that lists a core in its `skills:` frontmatter assumes the content
  arrives preloaded and is *not* duplicated locally. Move a rule into a core → delete it from every
  referrer. Move it out → the referrers must re-inline or re-point. Two harness constraints the
  preload depends on: a core must **not** set `disable-model-invocation: true` (that flag also
  blocks preloading — use `user-invocable: false` to keep it out of the `/` menu), and a **missing
  or renamed core is skipped with only a debug-log warning**, so the agent runs on without it. That
  silent failure is why each core opens by saying it is preloaded and what to do if it is absent,
  and why renaming a core means grepping every `skills:` list.
- **The improvement-inbox loop:** `feature-plan` Phase 6 *dispatches* `pipeline-retrospector`,
  which *files* proposals to [[pipeline-improvement-inbox]]; this skill's *Intake* step *consumes and
  reconciles* them. Spans four places — the Phase 6 step, the retrospector agreement, this skill's
  Intake, and the [[pipeline-improvement-inbox]] pointer in `MEMORY.md`. Change the memory's name or
  shape, or the retrospector's propose-only boundary, and all four must agree.
- **The independent code review:** the implementer dispatches `commit-code-reviewer` over its own
  diff; `feature-plan` and `feature-plan-reviewer` both cite that pass as the reason a plan may
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
  - **Every new file needs `git add -f`.** The dotfiles repo's `.gitignore` is a `*` catch-all with
    tracked paths opted in individually, so a file you create is **not** untracked-and-visible — it
    is *ignored*, absent from `git status` entirely. Nothing warns you; the edit simply never leaves
    this machine. Check with `git check-ignore -v <path>` and force-add, then confirm the file shows
    as `A` in the staged set before the sync.
- **The dispatch shape — foreground, and two levels deep.** Two harness defaults this pipeline
  depends on, both of which have already moved once and both of which fail *silently*:
  - **Subagents run in the background by default** (since v2.1.198), so a dispatch without
    `run_in_background: false` returns a notification in a later turn. Every handoff here is
    sequential and dependent, so the rule is stated once in `skills/handoff-core/` (sender half of
    the protocol) and only *named* by `commit-plan-implementer` — *Never return in a waiting state* —
    and by `feature-plan` Phase 5 beat 1, which must carry its own copy of the instruction because a
    skill cannot preload a core. The tell that this regressed is not an error: it is a dispatch that
    "stalls", a child that never reports, or a result addressed to someone else. **Diagnose it from
    the transcripts, not from the agreements** — grep the `Agent` tool_use inputs of the last run for
    `run_in_background`; the two features that recorded stalls are exactly the two whose nested
    dispatches went out backgrounded, and nine of twenty-two `commit-code-reviewer` dispatches were
    backgrounded while the main session got it right 40 times out of 41.
  - **Nesting depth ≥ 2.** The pipeline is main session → implementer → reviewer/writers. The
    default limit was **1** until v2.1.219 raised it to 3, and `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`
    can put it back. At the limit the harness simply **withholds the `Agent` tool** from the
    implementer, so the failure is not a blocked dispatch but an implementer that quietly writes its
    own commit doc and skips its independent review. Nothing in `validate-config.sh` can see this;
    if the delegation layer ever appears to vanish, check that env var before editing an agreement.
- **The handoff bundles:** `skills/handoff-core/` owns all four field sets; the five agents that
  preload it and `feature-plan` Phase 6 (which invokes it) may only **name** a bundle. A field
  list that reappears inline in a sending or receiving agreement is the drift the core exists to
  prevent — so adding a field means editing the core alone, and renaming the core means grepping
  every `skills:` list plus that Phase 6 step. Keep it clear of the **doc-style contract**: the
  core says what must *reach* an agent, never what its artifact contains. Its two rules are a
  matched pair — the sender's explicit `none` is what gives the receiver's gap-check anything to
  bite on, so dropping either leaves the other inert.
- **The measurement loop:** `pipeline-stats.py` is run by `pipeline-retrospector` (objective 1) and
  by post-edit check 7; its input is the **session-id list** in the retrospective bundle
  (`handoff-core`), which `feature-plan` Phase 6 fills from the state block; its output is a row in
  [[pipeline-metrics]]. Five places. The load-bearing fact, and the reason no agreement may quote a
  token figure it was told: **the only number an agent can see (`totalTokens` on an Agent result)
  excludes cache reads and understates by ~170×.** Any rule that lets a cost number travel by
  narration instead of by measurement re-opens that hole. Under one-commit-per-session the id list
  is also unrecoverable after the fact — no single transcript holds the run — so dropping that field
  silently truncates the cost account rather than erroring.
- **The generated-artifact bar** is *stated* once, in `commit-plan-implementer` → *Make outputs
  self-explanatory*, because that agreement owns the generating. `commit-code-reviewer` and
  `writer-core` **name it and add only their own act** (margins fit at save time; readable before
  embedding); [[figure-legibility-requirements]] records why it exists. Restating the bar in any of
  the three is the drift to hunt — it read as four rules for one requirement, and the copies had
  already begun to differ.
- **The config validator:** `skills/pipeline-maintenance/validate-config.sh` is named by post-edit
  check 6 **and** by `feature-plan` Phase 1; move or rename it and both go stale. Its field
  lists are transcribed from the published frontmatter tables, so a harness change can make the
  *validator* the stale party — which is why an unknown key is a warning and only an unresolvable
  reference is an error. It cannot check whether a named capability is still *invocable*; that
  half of check 6 stays human.
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
- **Calibrate by the file's job, not by model tier.** Tier follows the job rather than setting it —
  the implementer runs Sonnet by default precisely *because* its agreement is a checklist, and the
  planner may raise one commit to Opus without the file changing. What differentiates a file is what
  it is *for*. The implementer's agreement is a
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
6. **Named capabilities still exist, and named config keys are still read.** Start with the
   mechanical half: **run `sh ~/.claude/skills/pipeline-maintenance/validate-config.sh`** (it must
   exit 0). It checks what a script can — frontmatter keys against the published field tables, that
   every preloaded `skills:` entry resolves and does not block its own preload, that each agent's
   `name` matches its filename, and that the `settings.json` matchers and command paths still
   resolve. It cannot check whether a *named capability* is still invocable; that half is yours.
   Every skill, slash
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
7. **Check the change against the measurements — before and after.** Read [[pipeline-metrics]] at
   the *start* of a session that proposes to change cost or behaviour, and run
   `python3 ~/.claude/skills/pipeline-maintenance/pipeline-stats.py <project>` on the last run when
   the memory has no row for it. Two rules follow, and the first is the one this skill kept getting
   wrong: **never quote a token or cost figure an agent reported** — the visible number excludes
   cache reads and understates by ~170×, and a retrospective built on it sent several rounds of
   tuning against fiction. And **know where the cost actually is before optimising**: it concentrates
   hard (one feature had two of eight commits carrying 60% of the implementer tier), so a rule that
   trims the cheap majority is effort spent where there was nothing to win. After the next feature
   runs, the new row is what says whether this session's edit worked.
8. **Update the record** — reflect any structural change in [[pipeline-ecosystem]] and, if
   the map or a coupling changed, in this skill's *map* and *dependency graph*. Then update
   `~/.claude/PIPELINE.md` for anything it mirrors (flow, ownership, paths, guard logic, models,
   agent roster) and re-date its verified line.
9. **Reconcile the inbox** — delete or annotate every [[pipeline-improvement-inbox]] item this
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
