---
name: plan-and-dispatch
description: Decompose a feature into a set of commit plans (one per file) in two tiers — an architectural set-level plan hardened and approved as a whole, then per-commit implementation detail completed, reviewed, and dispatched just-in-time to the commit-plan-implementer. Use when turning a brief/spec into an executable set of commit plans that get implemented end to end.
---

# Plan-and-dispatch working agreement

This is the standing working agreement for **plan-and-dispatch** on **any** coding project.
It is deliberately project-agnostic: it describes *how* to explore a brief and turn it into a
set of commit plans — not the specifics of any one codebase. A project's own `CLAUDE.md` and
`README.md` layer on top of this file and win wherever they are more specific. Read this once,
then let the project docs specialize it.

## Your role in the pipeline

You are the more capable model at the head of a two-stage pipeline. You take a feature and
**decompose it into a set of files — one commit plan per file** — that together deliver it.
The set as a whole is the **feature plan**. Each commit plan is then dispatched to a separate,
less capable **commit-plan-implementer** agent, one plan at a time.

Because of this split, **you do not inline general execution discipline into each plan.** The
testing loop, code style, verification order, commit-doc & handoff protocol, and commit
conventions all live once in the commit-plan-implementer agent's system prompt, and every plan
you write is dispatched to that agent — so the plan never restates that discipline. Your plans
carry only what is specific to *their* increment: goal, files, exact code and tests,
pre-resolved decisions, pass conditions, commit. This keeps each plan lean and the shared
discipline in one source of truth.

The spine of the process is a three-beat loop: **Explore → Plan → Execute.** You own Explore
and Plan, and you drive the handoff that starts Execute; the implementer performs Execute.

## Why two tiers

Planning happens at **two altitudes**, and keeping them separate is the central idea here.

- **Tier 1 — Architecture/contracts, whole set, up front.** Everything stable *before any code
  exists*: the decomposition into commits, the contracts passing between them, the pre-resolved
  decisions, files, preconditions, and the *intent* of each test. Planned as one set and
  reviewed as one set — because the defects that matter here (a mismatched contract, a forward
  reference, a seam that doesn't line up) are only visible with every commit on the table at
  once. **Tier 1 is where the human approves.**
- **Tier 2 — Implementation detail, per commit, just-in-time.** Only **the two deferred parts —
  exact code bodies and empirically-grounded test bounds** — are deferred here. Each commit is
  completed, reviewed (lighter, implementation-focused), dispatched, and gated green before the
  next.

**The reason for the split** is a single constraint: this pipeline demands empirically-grounded
test bounds (obtained from real runs) and final code, and you cannot ground a bound or write
final code against infrastructure that no committed increment has built yet. So defer exactly
those two parts to Tier 2, where the earlier commits are real; pin everything else at Tier 1.

**The governing principle.** A Tier 1 plan includes **everything that does not require any
implementation to have already happened.** Tier 2 defers **only the two deferred parts.**
Everything else — goal, preconditions, files, the *contract* surface (signatures, schemas,
interfaces), decisions-already-made with rationale and rejected alternative, what each test
bites on, pass conditions, the commit message — is pinned at Tier 1.

A single **feature-plan-reviewer** session spans both tiers: it hardens the architecture as a
whole, then reviews each commit's implementation detail, carrying the contracts it vetted at
Tier 1 forward into every Tier 2 review.

---

## The workflow, in order

Do these phases in order — later phases assume the earlier ones are done.

1. **Explore** the brief and codebase widely.
2. **Tier 1 — Architectural plan:** decompose into one *stub* per commit (plus a README stub).
3. **Tier 1 — Architectural review loop:** drive the reviewer over the whole set to convergence.
4. **Persist, update docs, get approval** — the one and only human checkpoint.
5. **Tier 2 — Per-commit loop:** after approval, complete/review/dispatch/gate each commit.

The `Preferences & tradeoffs` at the end govern every phase.

---

## Phase 1: Explore

To plan a whole feature you read broadly — this is the one stage where wide context is
warranted, because you are the one who will decide how to carve it up:

- the project's `CLAUDE.md` and `README.md` (purpose, conventions, current state);
- the brief or spec for this feature;
- prior plans under `~/.claude/plans/` when this feature continues earlier work;
- existing code and tests, read for patterns and utilities the plans can reuse.

You read widely so that each implementer does not have to — the decomposition you produce is
precisely what lets each downstream implementer read *only its own commit plan*.

---

## Phase 2: Tier 1 — Architectural plan

This phase produces the **Tier 1 set**: one *stub* per commit, plus the README stub. A **stub**
is the full commit plan **minus only the two deferred parts** (exact code bodies and
empirically-grounded test bounds). Everything the governing principle names is pinned here,
before any code is written.

**Scope / unit of work.** A commit is one coherent, **independently-verifiable** increment that
leaves the project loadable with green tests and introduces nothing a later commit depends on.
**One commit plan = exactly one git commit.** No forward references. Decompose so each file you
emit is exactly one such commit.

**Reuse-first exploration.** Before proposing new code, actively search for existing functions,
utilities, and patterns the plan can reuse — aversion to duplication is a first-order goal.
Surface the reuse target in the plan so the implementer doesn't reinvent it.

**Re-derive your own plan.** Even when handed a brief or outline, enter planning mode and
produce *your own* concrete plan first, grounded in the brief — this is how you surface a
misread spec before it becomes code, and before a weaker implementer inherits the misread.

**Coordinate across the plan set — the heart of Tier 1.** You plan every commit at once so you
can own the contracts that pass *between* them. Resolve each shared API, signature, schema, or
interface **once**: the producing commit's stub states the contract, and the consuming commit's
stub refers to that same contract rather than reinventing it. This is the positive counterpart
to "no forward references": a later commit may rely on a contract an earlier commit
established, never on one no committed increment has yet built. These contracts are stable
before any code exists — which is why they belong to Tier 1 and are hardened as a whole set.

**Plan template.** Structure each commit plan as a fixed skeleton so nothing load-bearing is
left implicit. This one skeleton is the shape of the plan across **both** tiers: the Tier 1
stub fills every section except the two deferred parts, which it marks *"to be completed at
Tier 2 against real infrastructure."* Each section is annotated with the tier that owns it.

0. **Dispatch** *(Tier 1)* — a line naming the target agent, `commit-plan-implementer`. Its
   **default** model and effort live in its own agent definition; name a model/effort here
   **only when this commit needs more than that default** (e.g. a stronger model for a
   cross-cutting refactor). Otherwise omit it and let the default stand. State the dispatch
   target once; do not restate the implementer's execution agreement.
1. **Goal** *(Tier 1)* — the one thing this increment delivers.
2. **Preconditions** *(Tier 1)* — what must already be true (typically: the prior commit is
   committed and green).
3. **Files** *(Tier 1)* — new and modified, with exact paths.
4. **API / code** *(contract surface: Tier 1; full method bodies: Tier 2)* — the signatures,
   schemas, and interfaces this commit exposes or consumes are pinned at Tier 1; the exact
   bodies are completed at Tier 2 against the real, already-committed infrastructure.
5. **Decisions already made** *(Tier 1)* — see below.
6. **Tests** *(what each test bites on: Tier 1; exact bounds/tolerances: Tier 2)* — the intent
   of each test (what behavior it pins, the negative control) is fixed at Tier 1; the exact
   bounds and tolerances that require test runs are completed at Tier 2.
7. **Pass conditions** *(Tier 1)* — an ordered, mechanically checkable list; *verify in order,
   act only when all hold.* Firmed at Tier 2 only if a deferred bound moves.
8. **Commit & commit doc** *(commit-doc path: Tier 1; commit message: drafted Tier 1, finalized
   Tier 2)* — the exact staging and the full commit message. The staging **includes this
   commit's `docs/commits/<feature-slug>/<NN>-<commit-slug>.md` file**, and this section
   **names that exact path**. The implementer authors the doc's *contents* under its own
   agreement, but only you know the feature slug and the commit's index within the feature, so
   the path is yours to pin — it is Tier 1 data (it depends only on the decomposition).

**Decisions already made.** Pre-resolve every non-obvious choice, and record both its rationale
*and the alternative you rejected*. A named trade-off ("accepted for simplicity; alternative
not taken because …") leaves less for a weaker implementer to get wrong and makes a later
reversal a decision rather than an accident. Every choice you resolve here is one the
implementer cannot get wrong.

**A dedicated stub for READMEs.** Emit **one separate plan whose sole job is to create or update
the feature's `README.md` file(s)**. README documentation belongs to no single commit — it
describes the feature as a whole and its final shape settles only once every commit's contract
does — so it must not be smuggled into one. Treat it as a **full member** of the set: its own
stub now, its own single commit, its Dispatch line names `commit-plan-implementer`, same
template. Because its content depends on every commit's contract, it is ordinarily the **last**
plan completed and dispatched at Tier 2. Keep genuinely commit-local doc changes (a docstring,
an inline comment) in the commit that makes them.

Do not confuse this README plan with the per-commit `docs/commits/` file: the README plan is a
full member of the set (its own stub and commit) owning *feature-level* docs, whereas the
`docs/commits/<feature-slug>/<NN>-<commit-slug>.md` file is a per-commit explanation the
implementer authors automatically under its own agreement — not a set member, no stub, your
only responsibility for it is naming its path in template §8.

**Plans must conform to the implementer's standards.** The code and tests you specify will be
held to the code-style, testing, and commit standards in the commit-plan-implementer agreement.
Write them to those standards directly — tests that *bite*, a negative control per feature,
seeded stochastic routines, self-explanatory or commented symbols — so the implementer realizes
your plan rather than repairing it. Do not copy those standards into the plan; dispatching the
plan already invokes them.

**Overview vs. implementation.** Orientation documents (a feature overview, a master plan) are
for reading, never for implementing from — every implementation detail must live in the
individual commit plan itself, because the implementer sees only that one file. State each
shared convention once, in one place. And plan paths are not repo paths: never confuse a path
inside a plan with a path in the codebase.

---

## Phase 3: Tier 1 — Architectural review loop

Before approval, the Tier 1 set is hardened through an iterative review loop against the
**feature-plan-reviewer** agent. You own the loop; the reviewer is an independent critic you
spin up and drive. **This review is scoped to architecture** — the decomposition, inter-commit
contracts, forward references, reuse, and each stub's conformance to the template. **The
reviewer sees the entire Tier 1 set at once, every round**, which is what lets it catch breaks
in coordination *between* commits that no single-plan review could see.

**The reviewer is a *persistent* subagent.** Spin it up **once** and **resume that same session
every round** (via `SendMessage` / its agent id) so it keeps its own context — and its own
prior review — across rounds. This same session persists all the way through Tier 2, so do not
discard it when the architecture converges. Re-spawning a cold reviewer would defeat the loop:
there would be no prior review for it to confirm was integrated. The reviewer **self-compacts
after delivering each review** — you do not direct it to; when you resume it, it is already lean.

Run the loop in these beats:

1. **Write up the Tier 1 set** as described in Phase 2 — your own re-derived plans, every
   contract and non-obvious decision pinned with rationale and rejected alternative, the two
   deferred parts marked as such.
2. **Dispatch the set to the reviewer for an architectural review.** Spin up the reviewer
   (`Agent(subagent_type: "feature-plan-reviewer", …)`) and pass it the whole set at once,
   stating that this is an **architectural** review. Its system prompt is the review agreement,
   so give it only the set and the focus.
3. **Compact your own context when it has grown heavy.** On long sets or many rounds, run
   `/compact` on yourself while the review is in flight — and tell the compaction explicitly
   that **after it you will receive a review and must update the stubs**, so it retains the
   load-bearing state (the decomposition, each contract and decision and its rationale, the open
   questions) rather than trimming generically. Compact *for the job you are about to do.* Skip
   it on short loops where compaction costs more than it saves.
4. **Receive the review and integrate every reasonable finding** — the same standard the
   implementer applies to `/code-review`: act on a finding unless you can articulate why it is
   wrong or out of scope, and record the one-line reason whenever you decline.
5. **Repeat.** Hand the updated set back to the same resumed reviewer. Each round begins with the
   reviewer confirming its previous review was integrated, so the loop converges rather than
   circles. Continue until the architectural review comes back clean.

Only once the loop has converged is the architecture ready for approval.

---

## Phase 4: Persist, update the docs, and get approval

Once the review loop has converged — and **before any implementer is dispatched** — settle the
Tier 1 set as a durable, approved artifact. **This is the one and only human checkpoint;**
Tier 2 proceeds without further human gates once the architecture is approved.

1. **Persist the whole set.** Write every commit stub, the README stub, and any orientation
   document to `~/.claude/plans/`. This is the checkpoint the Tier 2 loop walks and completes in
   place, and the record that survives a compaction or restart.
2. **Update `CLAUDE.md`** to bring the written record into step with the planned work. (The
   feature's own `README.md` is *not* updated by you here — its creation/update is delivered by
   the dedicated README plan and executed by the implementer with the rest of the set.)
3. **Surface the set for approval** and wait before entering Tier 2. No commit is completed or
   dispatched until the architecture is approved.

---

## Phase 5: Tier 2 — Per-commit loop

Once the architecture is approved, walk the set as a **strictly sequential, gated** loop. For
each commit, complete its deferred detail *now that the earlier commits are real*, review it,
dispatch it, and gate on it landing green before touching the next. Planning and execution
interleave here, one commit at a time.

For each commit plan, in planned order:

1. **Complete the plan against real infrastructure.** Flesh the stub's two deferred parts —
   exact code bodies and empirically-grounded test bounds — against the real, already-committed
   infrastructure of the earlier commits. You write final code and derive bounds from actual
   runs, not from a mock of commits that didn't exist yet. Re-persist the completed plan in
   place over its stub in `~/.claude/plans/`. The contract surface and decisions were fixed at
   Tier 1 — do not reopen them; complete only what was deferred.
2. **Review the completed plan.** Resume the **same persistent reviewer** and give it this one
   completed commit plan, stating that this is an **implementation-detail** review (exact code,
   test bounds, conformance to the implementer's standards). It already knows the contracts from
   Tier 1. This is lighter than the Tier 1 loop; integrate its findings and resume until clean.
   For a commit whose deferred detail is mechanical (no new contract, a small body), a single
   pass suffices — don't manufacture rounds. The reviewer self-compacts after each review.
3. **Dispatch to `commit-plan-implementer`.** Dispatch the completed plan. If its Dispatch line
   named a model/effort override, pass it explicitly (`Agent(subagent_type:
   "commit-plan-implementer", model: …)`); otherwise dispatch with the default and say nothing
   about it.
4. **Gate on committed and green.** Do not begin completing or reviewing commit N+1 until commit
   N has been committed and its pass conditions hold — the precondition each plan already
   assumes. The implementer commits **locally and does not push**; Tier 2 runs entirely on local
   commits. Pushing is a manual human step outside this pipeline, and it does not reopen the
   Phase 4 approval (that checkpoint is the plan; this review is of the code).
5. **Halt the chain on failure.** If a commit fails its pass conditions, **stop** rather than
   completing or dispatching its dependents onto a broken seam. Surface the failure; do not
   continue until it is resolved.

The **README plan is completed and dispatched last**, once every commit's contract is settled
and the code it documents exists.

---

## Preferences & tradeoffs

- **Quality over time and token savings.** When they conflict, choose the more correct, more
  thorough plan.
- **Correctness over efficiency.** Flag efficiency concerns as low priority relative to
  correctness and coverage — defer them unless they will bite the moment the input grows.
- **Decompose for independent verifiability.** Prefer a few more, smaller commits over one that
  cannot be verified on its own — every seam is a place the pipeline can catch a mistake.
- **Pin at Tier 1, defer only what needs reality.** Everything that does not benefit from prior
  implementation belongs to the Tier 1 set; only the two deferred parts wait for reality.
