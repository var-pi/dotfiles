---
name: plan-and-dispatch-ecosystem
description: The three-altitude planning pipeline (3 skills + 2 preloaded cores + 7 subagents + git-guard hooks) and its design intent
metadata: 
  node_type: memory
  type: project
  originSessionId: 685a0512-e644-4ce1-b0c2-2b309b52e7f9
  modified: 2026-07-25T18:44:31.220Z
---

A planning/execution pipeline on the ladder **project → feature → commit** lives in
interconnected files under `~/.claude/`, each read by a different model:

- `skills/master-plan/SKILL.md` — the **master planner** (Opus 4.8). Top altitude: through-line,
  decomposition into features, repo architecture, risk register. Emits one **feature brief** per
  feature. Added 2026-07-17.
- `agents/master-plan-reviewer.md` — its **reviewer** subagent (Opus, xhigh). Persistent;
  resumed with its full transcript (its prior reviews) intact each round.
- `skills/plan-and-dispatch/SKILL.md` — the lead **planner** (Opus 4.8). Decomposes a feature
  into one commit plan per file — the contract surface, decisions, and test intent — reviewed as
  one set. (Was "two tiers"; collapsed 2026-07-22, see below.)
- `agents/feature-plan-reviewer.md` — the **reviewer** subagent (Opus, xhigh). Persistent
  session, resumed each round over the whole set until the architecture converges.
- `agents/commit-plan-implementer.md` — the **implementer** subagent (Sonnet, high). Executes
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
another: master-plan owns philosophy/decomposition and must contain **no signatures, no stubs,
no tolerances**; plan-and-dispatch Tier 1 owns contracts; the implementer owns code; Tier 2
owns measured numbers. A copy upstream is not a head start — it is a competing source of truth
that drifts once the real one is decided. The motivating artifact was
`~/repo/pavliotis/.../pavliotis_ch1_project_plan_3.tex`, which reached down two altitudes (a
450-line Julia stub appendix + per-feature signature tables + invented tolerances).

**The master-plan → plan-and-dispatch handoff crosses a session boundary**, deliberately.
master-plan names the next feature and *stops*; the human starts each feature in a fresh
top-level session. Two reasons: (1) `ExitPlanMode` doesn't exist for subagents, so dispatching
plan-and-dispatch as one would silently delete the pipeline's only human gate; (2) a whole
project doesn't fit one context window, and an *in-session* gate doesn't help — it gates the
start without refilling the budget. The persisted plan in `docs/plan/`, not a live session,
carries state across the boundary. This is why a feature brief must be self-sufficient for a
cold reader.

Vocabulary collision to respect: a **feature brief** (master-plan's per-feature entry) is not a
**feature plan** (plan-and-dispatch's Tier 1 set of commit stubs). "Unit" is retired.

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
- **Single verification owner (model a).** plan-and-dispatch Phase 5 gates on the implementer's own
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
- **Phase 6 retrospective + improvement-inbox loop.** plan-and-dispatch emits an operator-facing
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
- **`agents/pipeline-retrospector.md` (new, Opus).** plan-and-dispatch Phase 6 no longer writes its
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
  commit-code-reviewer ↔ plan-and-dispatch ↔ feature-plan-reviewer) and the **doc-style contract**
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
  bound to a `commit-plan-implementer` dispatch via two `settings.json` wirings. plan-and-dispatch
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
