---
name: pipeline-ecosystem
description: The three-altitude planning pipeline (3 skills + 3 preloaded cores + 7 subagents + git-guard hooks + 2 check scripts) and its design intent
metadata: 
  node_type: memory
  type: project
  originSessionId: 685a0512-e644-4ce1-b0c2-2b309b52e7f9
  modified: 2026-08-05T18:03:11.251Z
---

A planning/execution pipeline on the ladder **project → feature → commit** lives in
interconnected files under `~/.claude/`, each read by a different model:

- `skills/project-plan/SKILL.md` — the **project planner** (Opus 4.8). Top altitude: through-line,
  decomposition into features, repo architecture, risk register. Emits one **feature brief** per
  feature. Added 2026-07-17.
- `agents/project-plan-reviewer.md` — its **reviewer** subagent (Opus, xhigh). Persistent;
  resumed with its full transcript (its prior reviews) intact each round.
- `skills/feature-plan/SKILL.md` — the lead **planner** (Opus 4.8). Decomposes a feature
  into one commit plan per file — the contract surface, decisions, and test intent — reviewed as
  one set. (Was "two tiers"; collapsed 2026-07-22, see below.)
- `agents/feature-plan-reviewer.md` — the **reviewer** subagent (Opus, xhigh). Persistent
  session, resumed each round over the whole set until the architecture converges.
- `agents/commit-plan-implementer.md` — the **implementer** subagent (Sonnet, xhigh as of
  2026-08-05; the planner may override one commit to Opus). Executes
  one commit plan at a time — **writes the code bodies and derives the test bounds theory-first**
  (as of 2026-07-22; the plan no longer carries code or numbers). It **delegates all durable doc
  *authoring* to two Opus writer subagents** (below) while owning verify/stage/commit itself.
- `agents/commit-doc-writer.md` — the **commit-doc writer** subagent (Opus, high). Authors the
  per-commit, *maintainer-facing* `docs/commits/<feature-slug>/<NN>-<commit-slug>.md` for every
  commit; reads that one diff; does not stage/commit. Added 2026-07-18.
- `agents/feature-readme-writer.md` — the **feature-README writer** subagent (Opus, high). Authors
  the feature's *outward-facing, showcase* `README.md`; dispatched **last**, once every commit has
  landed green; synthesizes the whole feature (all `docs/commits/` + code + existing experiment
  figures); does not stage/commit. Structure/captivation for outside readers is its craft. Added
  2026-07-18. The README increment still routes through the implementer (which commits it and gets
  its own `docs/commits/` doc from `commit-doc-writer`, satisfying the guard).
- `hooks/pre-commit` + `hooks/pre-push` — the **pipeline guard** (POSIX sh). Marker-gated on
  `$GIT_DIR/CLAUDE_PIPELINE_ACTIVE` (or `$CLAUDE_PIPELINE` override): during a run they block
  push and reject a commit missing a staged `docs/commits/` file; inert otherwise, chaining to
  any repo-local hook. Armed via per-repo `core.hooksPath` at Tier-2 start, disarmed at close.

Design intent: shared execution discipline lives once in the implementer's prompt; plans stay
lean. The planner pins the architecture — contracts, decisions, each test's intent/target/method —
and hardens it as one reviewed set; the **implementer writes the code bodies and derives the
numeric bounds theory-first**. The one human checkpoint is the plan approval (`ExitPlanMode`,
Phase 4).

**Two-tier planning collapsed (2026-07-22).** An earlier design had the planner complete "the two
deferred parts" (exact code + empirically-grounded bounds) just-in-time per commit in a "Tier 2,"
each reviewed before dispatch. Retired because pre-written code turns the implementer into a
transcriber that stops checking integration, drains context twice, and grounds "final" code in
not-yet-built infra; the real safety net is the pinned test *target* + the implementer's
verify/mutation/`/code-review` loop. *Rejected alt:* planner code for load-bearing commits only (a
fuzzy per-commit classification that keeps the machinery alive). Now: one planning pass → one
whole-set architectural review loop → a thin execution loop (dispatch → gate → halt).
feature-plan-reviewer is architecture-only, persistent across *rounds*. Bounds are **theory-first**
(analytic where the math gives one; measured ~3σ only for the constant it won't). Retired
vocabulary: "Tier 1/Tier 2", "the two deferred parts", "empirically-grounded test bounds" as the
default framing.

**Hooks (2026-07-22).** pre-commit now **exempts docs-only commits** (nothing staged outside
`README.md`/`docs/`), so the docs-only feature-README commit carries **no** `docs/commits/` doc and
no `commit-doc-writer` pass (still routed through the implementer, which commits it). pre-push
unchanged.

**Shared cores + meta-skill (2026-07-22).** `shared/reviewer-core.md` now holds the discipline both
reviewers share (independence, objective-list workflow, resumed-not-respawned, converge); each
reviewer file reads it at start and carries only its altitude-specific objectives.
`skills/pipeline-maintenance/SKILL.md` is a new meta-skill for **editing this ecosystem** — it
carries the map, the cross-file dependency graph (altitude contract, docs/commits path ownership,
git-guard quartet, reviewer-resumption, README routing, session boundary, shared cores), the
editing discipline, and a post-edit checklist. Invoke it before changing any pipeline file. (A
`writer-core.md` for the two writers was scoped but deferred — the two writers are more
differentiated and the overlap smaller; a candidate follow-up.) No global `~/.claude/CLAUDE.md`
exists, so truly-general one-line preferences stay inline rather than being centralized there.

**Altitude contract (2026-07-17).** Each rung owns exactly one thing and copies nothing from
another: project-plan owns philosophy/decomposition and must contain **no signatures, no stubs,
no tolerances**; feature-plan Tier 1 owns contracts; the implementer owns code; Tier 2
owns measured numbers. A copy upstream is not a head start — it is a competing source of truth
that drifts once the real one is decided. The motivating artifact was
`~/repo/pavliotis/.../pavliotis_ch1_project_plan_3.tex`, which reached down two altitudes (a
450-line Julia stub appendix + per-feature signature tables + invented tolerances).

**The project-plan → feature-plan handoff crosses a session boundary**, deliberately.
project-plan names the next feature and *stops*; the human starts each feature in a fresh
top-level session. Two reasons: (1) `ExitPlanMode` doesn't exist for subagents, so dispatching
feature-plan as one would silently delete the pipeline's only human gate; (2) a whole
project doesn't fit one context window, and an *in-session* gate doesn't help — it gates the
start without refilling the budget. The persisted plan in `docs/plan/`, not a live session,
carries state across the boundary. This is why a feature brief must be self-sufficient for a
cold reader.

Vocabulary collision to respect: a **feature brief** (project-plan's per-feature entry) is not a
**feature plan** (feature-plan's Tier 1 set of commit stubs). "Unit" is retired.

On 2026-07-16 these files were refactored for consistency/compactness under the operative-why
test — see [[editing-subagent-guideline-files]]. (The 2026-07-22 collapse above superseded the
Tier-2 machinery this era introduced.)

Also on 2026-07-16, six Claude Code features were wired in: Phase 1 delegates the fan-out
survey to the `Explore` subagent (planner still deep-reads what it carves up); Phase 4 approval
runs through plan mode / `ExitPlanMode`, reordered to persist-*after*-approve; Phase 5 arms the
git guard and sends a `PushNotification` on halt; a new **Phase 6** disarms the guard, notifies
"ready to push", and writes cross-feature learnings to memory (planner-writes-at-feature-end);
the implementer's empirical verification now routes through the `verify`/`run` skills.
Key finding that shaped the guard: **CC `settings.json` hooks did NOT fire on `Agent`-subagent
tool calls (GitHub #34692, closed "not planned"), and the harness runs each Bash call in a
fresh shell** — so a runtime env var can't gate the subagent, hence the repo-local marker file.
(**Half-superseded 2026-07-25:** hooks now *do* fire on subagent tool calls and carry
`agent_type` — see the harness-substitution entry below. The fresh-shell half still holds, which
is why enforcement stays at the git layer.)

**Self-compaction was removed (2026-07-18).** The reviewers and planner previously told the model
to run `/compact` on itself after each review. This can't work: `/compact` is a built-in
interactive command with **no tool behind it**, so no model can self-trigger it — it is not a skill,
and even the main-session model can't emit it as a command. (The original entry also claimed
subagents have no `Skill` tool; **that is false** — `Skill` is in their default pool. The `/compact`
conclusion stands for the other reason.) Confirmed empirically: sending `/compact` to a subagent via `SendMessage` arrives as
**literal wrapped text** (no `compact_boundary`, no token drop; the subagent just reads the string
"/compact"). It's also unnecessary for the reviewers — they run ~2–3 passes and are resumed with
their **full transcript intact** (prior reviews already in context), never nearing the ~95%
auto-compaction threshold, so a carry-forward recap would only duplicate context. Fix: reviewers
now rely on the persistent transcript; the two skills dropped the false "self-compacts / already
lean on resume" claim; the planner keeps a slimmed note that steers *auto-compaction (or the human
typing `/compact` at the REPL)* to preserve the decomposition/contracts/decisions. General fact
worth keeping: built-in slash commands like `/compact` are not model-invocable. (This entry once
claimed `code-review` and `verify` *were* invocable bundled skills — **no longer true**, see the
2026-07-25 entry.)

**Execution-tier tune-up (2026-07-24).** A retrospective on the `05-bm-scaling-limit` run (5
commits; implementer tier ~730k of ~1.25M subagent tokens) drove these changes:
- **One synchronous gated run.** commit-plan-implementer runs the verifying experiment in the
  foreground exactly once — no background monitors, no repeated "confirmation runs" (seeded +
  deterministic ⇒ a re-run only reproduces identical numbers at full cost). Biggest leak: the
  stall/re-run instinct was baked into the agent and ignored per-dispatch instructions.
- **Single verification owner (model a).** feature-plan Phase 5 gates on the implementer's own
  result (commit landed + `ALL GATES: PASS` in the returned log + cheap test suite) and does **not**
  re-run the heavy experiment as a second ground truth. Codified a **land-or-idle waiter** (one wait
  per commit; no reactive polling; judge stall-vs-legit-run by the effort estimate). *Rejected alt:*
  model (b) — implementer a pure coder, orchestrator owns the authoritative run + commit — rejected
  as too invasive (would rewrite git-guard/doc-staging ownership).
- **Per-commit effort estimate** (template §0, renamed "Dispatch & effort") **+ a Phase-4 Execution
  budget** section the operator approves. Primary purpose is **operator awareness** — a legit long
  commit isn't mistaken for a stall. Advisory by default; a **hard stop only when the planner can
  certify (~3σ) the pinned config suffices**, never a cap that could abort work at 80%. Costly
  statistical gates ship a **near-final starting config** in the plan so the run is a check, not a
  search.
- **Descriptive-message guard (new `hooks/commit-msg`).** Marker-gated like the others; rejects an
  empty/degenerate message (subject < ~15 chars, or subject-only with no body) during a run. The git guard is now a **quintet**
  (pre-commit + pre-push + commit-msg + Phase-5 arm/disarm + implementer conventions).
- **`CLAUDE.md` added to the pre-commit docs-only exemption** (file set now
  `README.md` / `CLAUDE.md` / `docs/`), so a pure docs commit touching CLAUDE.md no longer forces a
  disarm.
- **Phase 6 retrospective + improvement-inbox loop.** feature-plan emits an operator-facing
  token/workflow retrospective and appends suggestions to [[pipeline-improvement-inbox]];
  pipeline-maintenance reads that inbox first (new **Intake** step) and reconciles it — a new
  coupling in the meta-skill's graph.
- **Removed the Phase 3 `/compact` steering note** (the "2026-07-18 slimmed note" above is now gone
  entirely) — planner context peaked at ~33%, so it was dead weight.
- **commit-doc-writer** reinforced to foreground the design "war story" (iterations / rejected
  approaches) for load-bearing commits.
- **Deferred (in the inbox, with reasons):** standalone API-doc artifacts (contract surface already
  serves it), Explore on a cheaper model (~35k, right-sized, harness-controlled), a planner
  context-offload agent (context is a non-problem).

**Docs-readability overhaul + two new agents (2026-07-25).** Operator feedback on the Unit-5 README
and commit docs (too verbose, everything weighted equally, run-log content crowding out design
content) drove these changes:
- **`shared/writer-core.md` (new)** — the second shared core, for the two doc writers, mirroring
  `reviewer-core.md`. Owns: the **rushed-team-lead reader** model and its economics (operator reading
  time dominates this workflow and costs far more than agent tokens, so extra passes to compress are
  always a good trade); layering (front-load, `<details>` folds for opt-in depth, `<summary>` as a
  real title, never fold the essential, headings as a table of contents); signal hierarchy (bold the
  load-bearing term, blockquote callouts — **one or two per doc**); denser-form selection; the cut
  list; figure embedding + the self-explanatory bar; LaTeX/jargon style; weight calibration; handoff.
  Both writer files were rewritten to carry only their audience, sources, sections, and altitude.
  (The 2026-07-22 "writer-core deferred, writers too differentiated" note is now superseded — the
  scannability rules turned out to be identical for both.)
- **commit-doc-writer re-scoped to "the build and the approach."** Three exclusions, generalized from
  the operator's examples: **not the run log** (seeds, gate margins, re-run counts, review status —
  state the conclusion, fold the raw output), **not the development history** (a bug fixed mid-flight
  is invisible in the final design), **not the code's local traps** (those belong in a code comment,
  where the implementer is separately required to put them). "Code review" and "Deviations from plan"
  stopped being always-present sections. TL;DR hard-capped at ~5 lines / 3 bullets. New metric: the
  **unfolded surface** stays under ~150 lines regardless of weight — depth below a fold is free.
  "Open with the picture, then the mechanics" (generalized from the praised Donsker-first framing).
- **The war-story rule was over-applied and is now bounded.** 2026-07-24 told the writer to
  *foreground* the war story for load-bearing commits; every doc grew one. Replaced by **"the one
  interesting thing — at most one per doc, usually none,"** folded, qualifying only if it changed the
  design. This is the ecosystem's canonical example of the new maintenance rule below.
- **`agents/commit-code-reviewer.md` (new, Opus, read-only, one-shot).** **`/code-review` is no
  longer model-invocable** — in Claude Code 2.1.220 it is a user-triggered command that fails with
  `disable-model-invocation` for any agent. The pipeline had been running with **no** independent code
  review, visible only as an aside in a commit doc. The new agent restores the control: the
  implementer dispatches it over its own diff, it reports (no write tools) and never fixes. It
  deliberately does **not** read `reviewer-core.md` — that core assumes a session resumed across
  rounds, which a per-commit one-shot is not. The `verify`/`run` skills are likewise no longer
  guaranteed present; the implementer's empirical-verification rule is now phrased "use them if
  available, otherwise drive the flow directly."
- **`agents/pipeline-retrospector.md` (new, Opus).** feature-plan Phase 6 no longer writes its
  own run retrospective — it dispatches this agent, because the planner reviewing its own run is the
  author's account. It reads the run artifacts + the current ecosystem files, files proposals to
  [[pipeline-improvement-inbox]], and returns an operator-facing retrospective the planner relays
  **verbatim**. *Operator asked whether it should simply upgrade the pipeline itself; scoped to
  **propose-only** — it may write that one memory and nothing else.* Rationale: those files govern
  every future run and the run closes unattended, so an edit here would change pipeline behavior with
  nobody reading the diff. *Rejected alt:* auto-apply "low-risk" changes only — needs a
  risk-classification the agent must judge correctly, the same fuzzy per-case call the Tier-2
  collapse already rejected.
- **New maintenance rule: generalize the feedback, never transcribe it.** Operator feedback arrives
  as examples; the rule written must be the extracted principle. Corollaries now in the skill: praise
  for a device is not a mandate to use it everywhere; a rule stated as a **cap** ("at most one",
  "under ~150 lines") survives an eager agent, an encouragement ("foreground the …") does not.
- **New post-edit check: named capabilities still exist.** The harness changes underneath these
  files; verify a skill/command an agreement depends on against the session's available-skills
  listing before relying on it.
- New couplings in the maintenance skill's graph: the **independent code review** (implementer ↔
  commit-code-reviewer ↔ feature-plan ↔ feature-plan-reviewer) and the **doc-style contract**
  (the implementer's bundle must pass a *superset* and let the writer select, or it competes with the
  writer's agreement and wins by accident). The improvement-inbox loop now spans four places.

**Harness-substitution audit (2026-07-25, Claude Code 2.1.220).** Prompted by "has the harness grown
builtins that replace parts of this?". Three of these are corrections of harness facts the files
rested on — all three had failed *silently*, which is the generalizable lesson.
- **`reasoning_effort:` was never a real frontmatter key.** All seven agents carried it; the schema
  field is `effort:`. Frontmatter parses loose, so the key was dropped with no warning and every
  agent inherited the session's `effortLevel: high` — meaning the two "xhigh" plan reviewers had
  **never actually run at xhigh**. Renamed in all seven; operator chose to keep xhigh as designed.
- **Marker arm/disarm retired (`hooks/pipeline-marker.sh`, new).** Hooks now fire on subagent tool
  calls and `SubagentStart`/`SubagentStop` take an `agent_type` matcher, so the marker's lifetime is
  bound to a `commit-plan-implementer` dispatch via two `settings.json` wirings. feature-plan
  Phase 5/6 and the halt path no longer arm, disarm, or mention the marker. Gains: the operator's own
  push is never blocked between commits, and a halt cannot strand an armed marker. The git hooks
  **stay** as the enforcement — the git layer catches a commit by any route, a `PreToolUse` Bash
  matcher only catches one made through Bash. *Rejected alt:* `disallowedTools: Bash(git push:*)` on
  the implementer to replace `pre-push` — the frontmatter-parsing risk (it might resolve to removing
  `Bash` outright and break every dispatch) isn't worth duplicating a hook that already works.
- **Shared cores are now preloaded skills.** `shared/*.md` → `skills/reviewer-core/SKILL.md` +
  `skills/writer-core/SKILL.md`, `user-invocable: false`, listed in the four agents' `skills:`
  frontmatter, which injects the full body at startup instead of trusting a "read this file first"
  instruction the agent could skip. `shared/` is gone. Two constraints: a preloaded skill must **not**
  set `disable-model-invocation: true` (that also blocks preloading), and a missing core is skipped
  with only a debug-log warning — hence each core now opens by stating it is preloaded and what to do
  if it is absent.
- **`/verify` joined `/code-review` as user-triggered-only** (2.1.215); the implementer's empirical
  verification now names only `/run`.
- **Checked and rejected:** agent teams (experimental, off by default, explicitly worse than
  subagents for sequential/dependent work, much higher token cost); packaging the ecosystem as a
  **plugin** (plugin subagents silently ignore `hooks`/`mcpServers`/`permissionMode`, which would
  break the marker wiring, and skills get namespaced — the benefit is distribution, which the
  dotfiles repo already covers); `isolation: worktree` (commits would land in a throwaway worktree);
  `maxTurns` (could abort a legitimate long gated run); the builtin task list for Phase 5 (the
  persisted plan set is already that queue).

**Altitude re-cut + implementer promoted to Opus (2026-07-28).** Operator review of the `06-fbm`
artifacts, plus the five retrospector inbox items from that run (all shipped).
- **`commit-plan-implementer` is now Opus/high.** No non-Opus node remains. What this *retired* is
  the argument for handing over near-final configs ("so a weak implementer doesn't search"); the
  "guaranteed-sufficient hard stop" marker went with it, having never been used by any commit.
  Consequence for maintenance: `pipeline-maintenance`'s "calibrate by reader" rule no longer keys on
  model tier — it now keys on the *file's job* (checklist vs. judgment instrument).
- **Measurement splits by question, not by rung** — the session's central decision. The planner may
  run code at plan time, against **already-existing** infrastructure, for one purpose: certifying a
  gate **discriminates** and a negative control genuinely fails. It writes the **margin** ("a wrong
  exponent moves this by O(0.1)"); every `atol`/`rtol`/SE-multiple/sample size is the implementer's,
  theory-first. Template §6's columns are now *intent / target / method class / discrimination*.
  *Why not simply forbid planner numbers:* the measurement's real job is **timing and scope**, never
  capability — the circulant-margin measurement is what *created* `06-fbm`'s probe commit and
  corrected the project plan's risk line, and the implementer (reading one plan) structurally cannot
  check a control in the last commit against a kernel in the first. *Rejected alts:* (a) planner
  measures nothing — decomposition-changing findings would then surface as a halt during the last
  commit; (b) legitimize the status quo (any measured number, tolerances included, reviewer
  re-measures) — it is what produced the frozen expressions below, and made three passes measure the
  same quantities. Redundancy now collapses to one pass per question.
- **The plan states what a test must distinguish, never how it is written.** A `method` naming an
  expression, fixture, grid size, or loop is code. *Motivating evidence:* `06-fbm` commit 01 shipped
  a provably no-op `eigvals(Symmetric(Matrix(Σ)))` because simplifying it "would be an unrecorded
  override of a plan-pinned decision", and a plan-pinned PSD check had to be rewritten after
  contributing 82 % of the suite's assertions for something other than what its comment claimed. The
  matching half is the implementer's new **"plan-stated mechanics are yours"** (an expression in a
  plan is illustration, not a decision) and `feature-plan-reviewer`'s new converse duty: *fault a
  plan that contains* a body, mechanic, or tolerance — not only one that omits them.
- **Additive-only relaxed to planner-declared consolidation.** Template §3 → "Files & delta": a
  commit may declare what it alters, subsumes, or removes. The guarantee that makes it safe, stated
  identically in three files: **the existing test-set stays green *unmodified* in that commit**; a
  legacy test that must change is a *contract change* needing its own declared step, never a quiet
  edit inside the commit whose implementation that test guarded. The implementer's ban on
  *opportunistic* restructuring is untouched. This is the commit-altitude half of the
  `APPROVAL-GATED` brownfield inbox item; the feature-altitude half (deltas in project-plan's briefs)
  stays gated.
- **Four more inbox items shipped:** never return in a waiting state (implementer re-dispatches a
  silent child once, else proceeds recording the step as not-performed) with its upstream half in
  Phase 5 (*a dispatch returning without its commit landed is neither success nor failure* — verify
  the tree, resume that same session, don't halt and don't re-dispatch cold); negative controls must
  be **certified** to fail, not merely named; §7 pass conditions must name a known systematic bias as
  the first hypothesis *and* the parameters that must not move; §0 effort splits **agent wall-clock**
  from **compute** (only wall-clock supports a stall diagnosis — `06-fbm` derived "past ~10 min is a
  stall" from a sub-minute experiment while all six dispatches legitimately ran 12–32 min).
- **Writer rules restated as caps/bounds**, because each already existed as an encouragement and
  failed to bite: a fold buys opt-in, **not exemption** from structure or the cut list; `<summary>`
  under ~8 words; **≤ ~5 consecutive prose sentences** without a structural break (a multi-sentence
  bullet counts as prose); **one section, one object**; the stand-alone bar extends from figures to
  **tables and display blocks**; claim strength must match evidence *and stay consistent across the
  doc*; the **antithesis tic capped at one per doc** with the tell named (*was Y ever on the table?* —
  "the nugget is reported rather than assumed" says nothing). commit-doc-writer additionally: every
  item under a heading must be an **instance** of that heading (a padded section is worse than an
  absent one); mechanical "What changed" items get **one line**; a decision earns a row only if the
  rejected alternative was **genuinely tempting**; never compare the work against the plan; notes
  aimed at the next editor of a line are **code comments**. feature-readme-writer: **≤ ~6 lines** from
  title to the first concrete thing. *No rule was written from the operator's praise* — every praised
  device already followed an existing rule, and the war-story precedent is why.
- **New coupling registered:** the delta/consolidation shape (feature-plan §3 ↔ implementer ↔
  feature-plan-reviewer), plus the altitude contract now explicitly spanning five files (the
  reviewer enforces it, `PIPELINE.md` §3 mirrors it).

**Readability + invocation pass (2026-07-28, second session that day).** Operator feedback: the
descriptions read like abstracts, the meta-skill has no stated workflow, and starting
feature-plan required spoon-feeding it "read file X, plan unit Y" every time.
- **`pipeline-maintenance` gained a six-phase spine** (read feedback → read ground truth →
  synthesize + ask → plan & `ExitPlanMode` → implement + checklist → **`/dotfiles-sync` commit and
  push**). Its existing sections became the detail behind phases 1, 2 and 5. Two bounds written with
  the rules: the question round asks only where two readings give *materially different edits* and
  arrives **batched** (a ritual round trains the operator to skim the one that mattered), and Phase 4
  is the sole gate (nobody else reads this diff — the same reason the retrospector is propose-only).
- **Phase 6 is new and load-bearing.** The ecosystem is distributed through the `~/.dotfiles` bare
  repo, so an uncommitted edit is one machine's local divergence and every other session keeps
  running the old rules with nothing reporting it. Scope bound: commit **only this session's edits**,
  name anything else dirty and leave it, so `git log` on these files stays a record of *why the rules
  are what they are*. New coupling registered ("the sync step"): a rename of `dotfiles-sync`, or an
  untracked new ecosystem file, fails silently — post-edit check 6's exact mode.
- **Description convention, now an editing-discipline rule with a cap.** A `description:` states
  *what + when*, **never how**, at **~25 words / two sentences**; mechanism there is an abstract of
  the body that owns the rule, free to drift, and the operator reads it in the `/` menu. Two things
  survive the cut: the **nearest-neighbour** discriminator and any **caller instruction** ("one plan
  at a time", "read-only"). All eleven descriptions rewritten (7 agents, 4 skills + `dotfiles-sync`).
  *Deliberate deletion:* "persistent — resumed each round" left both reviewer descriptions; it was a
  fourth copy of a protocol already owned by feature-plan Phase 3, project-plan step 3, and
  `reviewer-core`, and the dispatcher is the file that already states it.
- **`## How you are invoked` on both planner skills.** p-a-d: fresh session, cwd is the project repo,
  operator hands *where the project plan lives* + *which feature* — resolve both before exploring,
  accept the operator's word for the feature ("unit" is retired in the files, not in their speech),
  and when it is ambiguous **list the briefs and ask** rather than guessing, since a wrong guess
  burns a session's context. project-plan: same shape plus the distinction that actually bites — **a
  path to an existing `docs/plan/` plan means correction mode, not a fresh plan**, because the two
  are indistinguishable at invocation and re-planning discards the decision records.

**Bare invocation + the project-state record (2026-07-28, third session).** The operator's
correction to the invocation sections written earlier the same day: they had assumed a plan path and
a feature name would be handed over, and ended with *"never plan a feature the operator did not
name."* **The intended model is the opposite — `/feature-plan` is called with no arguments at
all**, in the project repo. `docs/plan/` is a fixed convention it already knows, the project plan
carries the spine, and the project's `CLAUDE.md` carries the state, so the feature is derivable and
asking for it was the per-run friction.
- **The rule was reversed, not softened.** Now: derive the next feature from the record, **announce
  it in the first message and proceed** (Phase 4's `ExitPlanMode` already gates the choice, so a
  blocking question buys nothing an announcement doesn't), and stop to ask in exactly two cases —
  `CLAUDE.md` and the project plan **disagree**, or a feature is recorded **in progress** (resuming a
  half-built feature and starting a fresh one are different jobs). An operator-named feature still
  overrides, in whatever words they use.
- **The blocking gap this exposed.** `CLAUDE.md` was written **once**, at Phase 4, describing the
  *planned* work; `commit-plan-implementer` touches it only incidentally; **Phase 6 had no
  `CLAUDE.md` step at all.** Nothing recorded that a feature *landed*, so a halt at commit 3 of 6
  left a record indistinguishable from a clean finish — and a bare invocation would have walked past
  a half-built feature into the next one. Deriving is only safe once the record is bracketed.
- **The run is now bracketed in a pipeline-state block:** Phase 4 opens the feature (in progress +
  commit count), **Phase 5's halt path records where it stopped**, Phase 6 flips it to landed and
  names the next; `project-plan` step 4 seeds the block for a fresh project, since p-a-d reads a
  missing block as a broken record. The planner commits these itself as docs-only commits —
  `CLAUDE.md` is already in `pre-commit`'s exemption set. *The halt write is the one to defend in
  any future compaction:* it fires unattended, and it is the only thing separating a half-built
  feature from a finished one.
- **`project-plan` leads with the convention** rather than with what it was handed: the plan lives at
  `docs/plan/`, and **what is on disk picks the mode** — a plan already there means correction mode.
  Same rationale as before (the two modes are indistinguishable at invocation and re-planning
  discards decision records); only the trigger moved from *a path you were given* to *what you find*.
- **New coupling — the project-state record**, spanning five places (project-plan step 4, p-a-d
  Phases 4/5/6, p-a-d's invocation) plus `pre-commit`'s exemption. Its failure mode is not an error
  but a plausible wrong feature. The **session boundary** coupling was updated to say what crosses
  it is written, not spoken.

**Visual map added (2026-07-25).** `~/.claude/PIPELINE.md` — Mermaid diagrams (end-to-end lifecycle
with both human gates and the session boundary; the implementer's inner loop as a sequence diagram;
the guard's branch logic; the improvement loop) plus the altitude-contract table, the artifact-path
table, a file index (model/effort/reads/dispatches), and a symptom→owning-file troubleshooting
table. Written because orientation is the one thing 13 agent-facing files could not provide: each is
prose for an agent about to act, so the *shape* of the whole — who dispatches whom, where the two
human gates sit — was legible nowhere. Markdown+Mermaid chosen over an HTML artifact so it lives
beside the files it documents, rides the dotfiles repo, and stays greppable. **Constraint that makes
it safe: pointer-only.** It names the owning file for every rule and states none itself; nothing may
be recorded only there, since a rule in a file that governs nothing is still read and obeyed and then
drifts. Registered as a coupling ("the visual map") in the maintenance skill's graph and in post-edit
checklist #7, because a mirror with no authority goes stale silently and a stale diagram is worse
than none — it is trusted at a glance.

**FOSS-survey items shipped (2026-07-28, second session that day).** Three of the five
`APPROVAL-GATED` inbox items from the 2026-07-25 survey were approved and built; two the operator
deferred (behavioural regression tests via `promptfoo`; a Semgrep pass beside the code review —
note Semgrep is not believed to support Julia, so that one needs a fact checked before reopening).

- **Feature-altitude brownfield delta** — completes the item whose commit-altitude half shipped
  earlier the same day. project-plan's brief gains field 8 **Delta** (`none — new ground` when it
  only adds, so an absent line cannot read as "nobody considered it"), `project-plan-reviewer` gains
  a **Declared deltas** objective, and feature-plan Phase 2 gains **carry a brief's delta down
  into the set**. Two bounds keep it from reaching down a rung: a brief **names modules, never
  signatures**, and it must **name every shipped guarantee it intends to break** — that break is
  exactly what the commit-altitude "existing test-set stays green *unmodified*" guarantee cannot
  cover, so it needs its own declared migration step. *Why the bounds and not just the field:*
  without them the brief re-specifies the replaced surface and becomes the competing source of
  truth the altitude contract exists to prevent.
- **`skills/handoff-core/SKILL.md` — the third preloaded core.** Owns all four agent-to-agent
  bundle field sets (code-review, commit-doc, feature-README, retrospective) plus a two-part
  protocol: the **sender writes every field including `none`**, the **receiver names any gap in its
  handback and proceeds** (never stalls — same principle as the implementer's *never return in a
  waiting state*). The two halves are a matched pair: without explicit `none` the receiver cannot
  tell a dropped field from a genuine nothing, so the check has nothing to bite on. *Why a core
  rather than a required-fields list in each agreement (the original proposal):* enforcement at
  both ends means both ends need the list, and a list in two files is the drifting-restatement
  defect. The sending and receiving agreements now only **name** a bundle. Boundary held
  deliberately: the core says what must *reach* an agent, never what its artifact contains — the
  **superset rule** stays with the doc-style contract. Harness constraint found and verified
  against the published field tables: **`skills:` is a subagent-only frontmatter key**, so
  `feature-plan` (a skill) cannot preload the core and invokes it via the `Skill` tool at
  Phase 6 instead. Writing it exposed a live drift that vindicated the item: `pipeline-retrospector`
  claimed the improvement-inbox path "is in your bundle" while the planner's list never carried it
  — now a declared field.
- **`skills/pipeline-maintenance/validate-config.sh` (new, POSIX sh).** The mechanical half of
  post-edit check 6. Checks frontmatter keys against the published field tables, that every
  preloaded `skills:` entry resolves and does not set `disable-model-invocation` (which would block
  its own preload), that each agent's `name` matches its filename, and that `settings.json`
  Subagent matchers and command paths still resolve. **Unknown key ⇒ warning; unresolvable
  reference ⇒ error (exit 1)** — because the field lists are transcribed from docs that move, so
  the validator can be the stale party. Verified against a fixture carrying all five historical
  failure modes. Two triggers, no background automation: post-edit check 6 (drift you introduce)
  and **feature-plan Phase 1** (drift the *harness* introduced with nobody editing a file —
  the `reasoning_effort` mode). *Rejected alt:* a `SessionStart` hook — it fires in every unrelated
  repo, and a warning seen 40 times a week stops being a warning. It cannot check whether a named
  capability is still *invocable*; that half of check 6 stays human.
- New couplings registered in the maintenance skill: **the handoff bundles** and **the config
  validator**; the delta/consolidation coupling now explicitly spans the feature altitude too.

**Measurement, tier split, per-session dispatch, ladder rename (2026-08-05).** Triggered by operator
asks about cost, pacing and naming; reframed by one finding that made most of them answerable.

- **Every cost figure the ecosystem had ever produced was wrong by ~170×.** The only number an agent
  can see is `totalTokens` on an Agent tool result, which **excludes cache reads** — and cache reads
  are 60–95% of a run. `07-sde-bridge`'s six implementer dispatches reported 1.31M; the transcripts
  say 222M. Measured truth: `06-fbm` 122.5M/$114, `07-sde-bridge` 478.8M/$445. Every prior
  retrospective, and the tuning done from them, argued against fiction. Fixed by
  **`skills/pipeline-maintenance/pipeline-stats.py`** (reads `projects/<slug>/<session>.jsonl` plus
  the `<session>/subagents/` tree, which carries `agentType`/`parentAgentId`/`spawnDepth` and full
  per-turn usage) plus the new [[pipeline-metrics]] memory. The bundle now carries **session ids, not
  token counts** — deliberately, so a wrong number cannot travel by narration. *Registered as the
  **measurement loop** coupling, spanning five places.*
- **Cost scales as ~turns^1.56** (R²=0.948, n=7), not linearly — so turn count is the lever and model
  tier the smaller one. Spend also concentrates hard: 2 of 8 commits were 60% of the implementer
  tier, the cheapest 3%. Both facts are why the tier decision below is *per commit*.
- **Implementer split by commit weight:** frontmatter `model: sonnet`, `effort: xhigh`, with the
  planner marking `model: opus` on commits carrying load-bearing mathematics (template §0). *Why
  xhigh:* `effort: high` was a **Sonnet-era holdover** — the 2026-07-28 Opus promotion changed
  `model:` and never revisited `effort:`. *Empirical anchor:* `06-fbm` ran the implementer on
  Sonnet 5 at 93 turns/commit and 35% of run cost; `07-sde-bridge` on Opus 5 at 217 turns/commit and
  60% — confounded by feature size, but it rules out the worry that Sonnet needs more turns.
  *Break-even:* Sonnet stops paying only past **+39% turns**. **Found and fixed while doing it:** §0
  had offered a per-commit **effort** override since 2026-07-24 — the Agent tool takes `model` only,
  so that half had never been deliverable.
- **Dispatch is now one commit per session.** Phases 1–4 run once; Phase 5 runs per session and
  stops. *Why:* the unattended chain accumulated 346 coordinator turns and 20% of `07-sde-bridge`'s
  cost, and a usage limit hitting mid-chain interrupted the run at an arbitrary point. The state
  block gains a **plan-set path** field — without it a fresh session can name the right commit and
  still not find its plan. "A feature is in progress" flips from a stop-and-ask to *the* resume path;
  the remaining stop-and-ask is *in progress but the plan set is missing*. Guard untouched: the
  implementer is still a subagent, so both `settings.json` matchers still fire.
- **Opus-5 re-baseline of the implementer.** The agreements were written for Opus 4.8. Deleted the
  verification scaffolding the current models perform unprompted (it is a *delete*, not a rewrite —
  telling these models to verify causes over-verification with no capability gain); capped review
  re-dispatch at **one**; added the **marginal-gate protocol** (diagnose the mechanism before
  touching a number — enlarging an ensemble makes a *biased* gate worse, and one feature's three
  marginal gates each needed a different response); added a scope bound against unrequested helpers
  and abstractions.
- **Ladder rename:** `master-plan` → `project-plan`, `plan-and-dispatch` → `feature-plan`,
  `master-plan-reviewer` → `project-plan-reviewer`, and this memory → `pipeline-ecosystem`. The
  *agents* were already systematic (`<rung>-<artifact>-<role>`); only the skills were inconsistent.
  **`commit-plan-implementer` deliberately keeps its name** — the git guard's two matchers key on it
  and it appears in shipped `docs/commits/` files, so renaming would break the record for no
  operator-facing gain. Timing chosen because the roadmap had just closed: no run in flight, no new
  artifact carrying a retired name.
- **The improvement-inbox loop had broken.** `07-sde-bridge`'s retrospector filed six well-argued
  proposals to a **project-local** memory file the maintainer never reads. Fixed with an absolute
  fallback path and an explicit "never create a second inbox"; the six items were merged into the
  global file and shipped.
- **Deduplicated the generated-artifact bar**, which was stated four times (implementer,
  `commit-code-reviewer`, `writer-core`, [[figure-legibility-requirements]]). The implementer owns it
  because it owns the generating; the others name it and add only their own act. *Registered as a
  coupling.*
- **Considered and rejected (2026-08-05, first session):** turning the two doc writers into skills invoked by the implementer
  (the operator's token-saving hypothesis). Measured the opposite — a writer subagent runs at
  1.3–3.7M cache-read against the implementer's 250–350k context, so inlining the same work would
  cost ~3.5× more *and* lose the fresh-context read of the diff. Also rejected: a new specialist
  agent (nothing a generic agent does is expensive enough to justify the preload + coupling —
  `Explore` just needed routing to Sonnet), and having the implementer write memories (one per
  commit is the war-story failure mode again). **Condensation was measured, not assumed:** the
  implementer's agreement is ~2% of its own dispatch cost, so condensation buys precision, not
  tokens — it was scoped to the dedup above rather than a global squeeze.

**Foreground dispatch — the stall machinery was treating a symptom (2026-08-05, second session).**
Triggered by an operator ask about two verification articles plus a sweep of recent Claude Code
releases. The articles taught little; the harness sweep found the root cause of a defect the
ecosystem had been patching for two features.

- **The finding.** Since **Claude Code v2.1.198** subagents **run in the background by default**; a
  background result arrives as a completion notification in a *later* turn, so a dispatching agent's
  turn can end while its child still works, and the result surfaces to whoever is listening. **No
  agreement in the ecosystem mentioned this.** Evidence from the actual transcripts (166 `Agent`
  dispatches in the `pavliotis` project): the main session dispatched the implementer in the
  foreground **40 of 41** times, but the implementer — one level down, where the agreements were
  silent — backgrounded **9 of 22** `commit-code-reviewer` dispatches, plus doc- and README-writer
  calls. The dates settle it: the three `rib=UNSET` nested dispatches are **2026-07-26** (`06-fbm`)
  and the eleven `rib=true` ones are **2026-07-29 → 08-04** (`07-sde-bridge`) — precisely the two
  features whose retrospectives produced *never return in a waiting state* (2026-07-28) and the
  late/misrouted-result merge rules (2026-08-05). The pipeline had written recovery machinery for
  the documented behaviour of a parameter nobody was setting.
- **The fix, stated once.** `handoff-core` gains a **sender: dispatch in the foreground** rule
  (`run_in_background: false`) as the first half of its protocol — it is squarely "what must *reach*
  an agent", and every handoff in the pipeline is sequential and dependent, so the default buys
  nothing. `commit-plan-implementer` and `feature-plan` Phase 5 beat 1 only **name** it; the planner
  needs its own copy because `skills:` is subagent-only and a skill cannot preload a core.
  **The recovery machinery was deliberately kept** — a background dispatch can still slip through,
  and the rules cost little. *Generalizable lesson:* the symptom ("a child that never reports") was
  diagnosed twice from inside the run, where the cause is invisible; it was only visible by grepping
  the `Agent` tool inputs in the transcripts. Prefer the transcripts over the agreements when a
  dispatch misbehaves.
- **Nesting depth registered as a dependency.** The pipeline requires depth ≥ 2 (session →
  implementer → reviewer/writers). The default was **1** until **v2.1.219** raised it to 3, and
  `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` can restore it. At the limit the harness **withholds the
  `Agent` tool** rather than erroring, so the failure mode is an implementer that quietly writes its
  own commit doc and skips its independent review. `validate-config.sh` cannot see this.
- **Both of the above are now one coupling** in `pipeline-maintenance` — *the dispatch shape* — and
  two `PIPELINE.md` troubleshooting rows.
- **The articles.** The *agentmarketcap* post (Opus 4.7, April 2026, third-party) claims models now
  self-verify — which is what the Opus-5 re-baseline above already concluded when it **deleted** the
  verification scaffolding. It confirms a decision rather than proposing one; its one unadopted idea
  ("capture uncertainty signals before completion") was declined as ceremony, since declined findings
  and plan deviations already ride the handback. Anthropic's *verification loops as skills* post
  reframes the `APPROVAL-GATED` deterministic-checks inbox item — **the loop is the skill, not the
  tool**, which dissolves the Semgrep/Julia blocker. Left gated at the operator's instruction, with
  the reframe and its altitude question annotated in [[pipeline-improvement-inbox]].
- **Harness sweep, checked and rejected:** `fallbackModel` (a silent downgrade on a load-bearing-math
  commit is worse than a visible halt); dynamic workflows (rejected for the same reason as agent
  teams — this work is strictly sequential); `/goal` (fights one-commit-per-session); Artifacts for
  `PIPELINE.md` (the markdown-beside-the-files rationale stands); `Agent(model:opus)`-style
  permission rules (the git layer catches a push by *any* route, a tool matcher only through Bash —
  unchanged since 2026-07-25); `/usage` per-subagent attribution (`pipeline-stats.py` measures
  better). `validate-config.sh` was **not** stale — its field lists already carried `background`,
  `context` and `isolation`. Noted for the operator: 2.1.221/222 exist and fix subagent `model:`
  override handling.
