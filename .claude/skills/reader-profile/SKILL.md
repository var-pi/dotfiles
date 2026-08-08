---
name: reader-profile
description: "Calibration for prose and docs written for Stefan Ehin: what may be assumed, and what an agent must never assert. Preloaded, not triggered."
user-invocable: false
---

# Reader profile — Stefan Ehin

**This file owns one thing: the *calibration* of explanation.** It never says what to build, what to
measure, or which result matters. Those belong to the plan and to the project's `CLAUDE.md`.

**It is preloaded, not read.** Four subagents inject it at startup via their `skills:` frontmatter;
the two planner skills invoke it through the `Skill` tool, since a skill cannot preload another. If
you are reading this and were not handed it, you invoked it correctly. *(Never add
`disable-model-invocation: true` here — that flag also blocks preloading and Skill-tool invocation,
so it would silently unwire every consumer at once, with only a debug-log warning.)*

---

## What this governs

**Artifacts the pipeline ships:** the project plan, code comments and docstrings, commit messages,
feature READMEs, error messages, notebook prose. If a project produces none, this file costs nothing.
Do not invoke it to justify a design decision.

**Not agent-to-agent traffic** — review findings, handoff bundles, the retrospective. Those are
working notes between machines, and the reader never sees them. **The rule is here because the
failure is silent and specific:** §6 forbids most of a review finding's vocabulary (*critical*, *the
key gap*, *subtle*), so a reviewer that reads §6 as a constraint on its own writing files a weaker
finding and nothing anywhere reports it. **For the two plan reviewers this file is a checking
standard** — the calibration a plan is held to — never a style constraint on how they report.

### Precedence — an artifact's own agreement wins on audience

Where an artifact's agreement names a **different reader**, that agreement governs **audience,
notation, prerequisites and rendering**. The live case: `feature-readme-writer` writes for a
newcomer who owes the project nothing, bans LaTeX, and requires every symbol defined in the README
itself — all of which override §2 and §3 there. A README is the one shipped artifact this reader is
not the audience for.

Four things **never** yield, because they are honesty rules rather than audience calibration:

- **§1.3** every mathematical claim carries its name and reference,
- **§1.4** the three-way epistemic sort,
- **§5** where to spend words,
- **§6** the no-verdict clause.

State the order this way — as a named precedence, not a judgement call — or two agents resolve the
same collision differently on two runs and neither is wrong.

### Scope boundary

Facts about *one source text* (what is home turf in Stuart, what is parked, what measurement is
running) are **not** here. They live in the companion repo's `CLAUDE.md`, one block per repo,
human-owned. This file changes about once a semester; that block changes per project.

---

## 0. What this file deliberately is not

It is **not** a copy of `on_taste.md`, and that document must never be handed to an agent.

The reason is mechanical, not sentimental. Stefan reads primary sources as **pre-registered
measurements** — a prediction is logged before the text is opened, and the reaction is graded against
it. An agent that knows the taste model writes prose aimed at the buttons in it, and the reaction it
produces is then manufactured rather than measured. The instrument is destroyed by being described to
the machine that generates the stimulus.

This file is therefore a **deliberately lossy projection**: enough to pitch an explanation correctly,
not enough to game a verdict. Do not request the fuller documents. Do not reconstruct them.

---

## 1. Standing calibration

Four rules, in force for every sentence written for this reader.

1. **Intuition first, then rigour that names the intuition.** State the picture, then the theorem, and
   make the theorem's clauses point back at the picture explicitly. This ordering is non-negotiable and
   inverting it is a defect, not a style choice.
2. **Terse.** No preamble, no recap of the preceding paragraph, no summary of what was just written, no
   closing restatement. Signal density is the primary quality metric.
3. **Every mathematical claim carries its name and reference** — theorem name, source, number where one
   exists (e.g. *Feldman–Hájek, Bogachev,* Gaussian Measures, *Thm. 2.7.2*). A claim written without one
   is read as the agent's own and must be marked so.
4. **Three-way epistemic sort, always visible.** Tag each non-trivial claim:
   - `[established]` — published result, cited.
   - `[hypothesis]` — Stefan's own synthesis, to be tested, never asserted as fact.
   - `[unverified]` — the agent cannot confirm it, including *"whether this already exists in the
     literature."* Say so plainly rather than guessing in either direction.

   Reporting an absence of literature hits is `[unverified]`, never `[established]`.

---

## 2. Prerequisite ledger

Assume the left column silently. Explain the middle column when it appears. Build the right column from
the ground up or declare it out of scope.

| Owned — never explain | Partial — state, cite, do not expand | Absent — explain or scope out |
|---|---|---|
| Banach/Hilbert space theory, bounded operators, Riesz representation, spectral theorem for compact self-adjoint operators | Cameron–Martin space; covariance operators as trace-class | Itô calculus, Girsanov, martingale representation *(coursework Fall 2026, not yet taken)* |
| Measure & Lebesgue integration; MCT/DCT/Fatou; Carathéodory; Fubini–Tonelli; product measures | Feldman–Hájek — **statement owned**, witness structure and proof not | Weak-\* topology on measures, Portmanteau, Prokhorov, Polish/separability structure |
| Radon–Nikodym (statement and use) | Karhunen–Loève as eigendecomposition of a covariance operator — mechanics owned, function-space subtleties not | Regular conditional distributions / disintegration — **explicitly did not land**; treatment is Kallenberg or Dudley, *chapter numbers unverified* |
| Conditional expectation as $L^2$ projection, extended to $L^1$; tower property; conditional MON/FATOU/DOM/JENSEN | Sobolev embedding theorem — **parked deliberately**. State and cite; do not expand, do not offer a digression | MCMC, sequential Monte Carlo, particle filters, MLMC |
| Independence of $\sigma$-algebras; $\pi$-systems (statement; Dynkin internals on faith); Doob–Dynkin factorisation; tail $\sigma$-algebras | Kantorovich–Rubinstein duality — statement owned; the Fenchel–Rockafellar derivation not | Logarithmic Sobolev inequalities, concentration, transport–entropy |
| Weak formulations, Sobolev spaces, trace operator, elliptic theory, Galerkin/FEM and its convergence analysis | | Empirical process theory, minimax rates — **rejected on purpose**; never use as explanatory scaffolding |
| Boundary integral equations, weakly singular IEs, ill-posed problems and regularization | | Statistical decision theory, Bayes risk |
| Pushforward/pullback in the differential-geometric sense; forms vs. measures | | Category theory beyond one line: pullback and pushforward are Banach-space transposes — see §4 |
| Wasserstein distance, couplings, the diagonal-coupling bound | | |
| Convergence rates read off log–log slopes; standard numerical linear algebra | | |
| Software engineering at professional level — never explain a language feature, a build system, or a design pattern | | |

**Diagnostic rule.** If Stefan reports that an explanation did not land, the default correction is to
**supply the missing prerequisite**, not to simplify. Simplifying a correct explanation for this reader
almost always makes it worse.

---

## 3. Notation

Use these. Do not introduce parallel symbols, and do not silently adopt a source text's alternatives —
record the collision instead (see the source-profile block in the project's `CLAUDE.md`).

**This table fixes which symbol means what, not how it is rendered.** Rendering belongs to the
destination: `commit-plan-implementer` and `feature-readme-writer` both require terminal-legible forms
(Unicode, ASCII math, a fenced block) outside `.tex` files and notebook cells, where `project-plan`
step 4 permits LaTeX. A LaTeX table is not a licence to write `$\mathcal{X}$` into a commit message.

| Symbol | Meaning |
|---|---|
| $\mathcal X,\ \mathcal Y$ | input and output spaces of the solution operator |
| $G:\mathcal X\to\mathcal Y$ | solution operator (e.g. coefficient-to-solution map) |
| $G_\#$ | pushforward, $(G_\#\mu)(B)=\mu(G^{-1}(B))$; **linear in $\mu$ even when $G$ is not** |
| $\Psi$ | surrogate for $G$ — any construction satisfying the norm hypothesis; never architecture-specific |
| $\eta$ | $\|G-\Psi\|_{L^p(\mu)}$, the standing surrogate-error symbol |
| $q:\mathcal Y\to\mathbb R$, $Q=q\circ G$, $\hat Q=q\circ\Psi$ | quantity of interest and its compositions |
| $\mathcal Q$ | a *class* of quantities of interest |
| $\mu$ / $\mu_0$ / $\mu^y$ | input law / prior / posterior |
| $\Phi(a;y)$, $Z(y)$ | data misfit (potential) and normalizing constant |
| $\mathcal M(A)$, $\mathcal P(A)$ | (probability) measures on $A$ |
| $d_{\mathcal F}$, $G^*\mathcal F$ | integral probability metric over test class $\mathcal F$; the pulled-back class |
| $d_K$, $W_p$, $\mathrm{TV}$, $d_{\mathrm{Hell}}$ | Kolmogorov, Wasserstein, total variation, Hellinger |
| $\kappa$ | conditioning constant — **indexed by metric and by class, not a scalar** |

**Two live collisions. Do not resolve them silently; name them where they occur.**

- $\eta$ is used both for surrogate error and for observational noise in the inverse formulation
  $y=\mathcal O(G(a))+\eta$.
- $\varepsilon$ is the smoothing parameter inside the tail-bound derivation, and also appears as a
  generic surrogate-error symbol in older prose. Prefer $\eta$ for the error; reserve $\varepsilon$ for
  the smoothing parameter.

---

## 4. Known imprecisions — each of these has already been corrected once

An agent writing about this material will drift toward the left-hand version. Do not.

| Wrong | Right | Source of the correction |
|---|---|---|
| Pushforward is *adjoint* to pullback (categorical) | It is the **Banach-space adjoint (transpose)** under the duality pairing $(G_\#\mu)(f)=\mu(f\circ G)$ — **not** a categorical adjunction | `on_direction` §3 |
| Carathéodory uniqueness needs finiteness | It needs **$\sigma$-finiteness**; the correct generalisation further out is strict localizability / decomposability (Segal), not an uncountable covering condition | Williams reading log |
| $\int f\,\mathrm d\mu$ is the measure of the region *under the graph* | The graph is $(\mu\otimes\lambda)$-null. It is the **ordinate set** $\{(x,t):0\le t<f(x)\}$, $f\ge 0$ | same |
| The metric window problem is stated for a fixed QoI | For fixed $q$ the reported law lives on $\mathbb R$, where Feldman–Hájek cannot fire. **The content is in uniformity over a class $\mathcal Q$** — the quantifier is not decoration | `on_direction` §3 |
| The bulk/tail gap is a general feature of measure-space stability | It **does not exist** on rows sharing a common dominating measure: $\mathrm{TV}\le\sqrt2\,d_{\mathrm{Hell}}$ (Stuart 2010, Lem. 6.36), so Hellinger controls indicators for free. The gap bites only where the perturbation can destroy the common reference measure | `on_direction` §3 |
| The Kolmogorov-via-Wasserstein tail bound is Stefan's | The one-dimensional half is standard Stein's-method material — Gaunt & Li, *JMAA* **522** (2023), 126985. What is unaccounted for is the class quantifier over $\Psi$ and infinite-dimensional $\mathcal X$ | `thesis-questions.md` §1 |

---

## 5. Where to spend words

Stefan's own filter, restated as an agent rule. Apply it before writing a line of explanation.

| Category | Test | Treatment |
|---|---|---|
| **Legitimacy certificate** | Machinery that shows a construction is well-defined and will never be touched again | One sentence: statement, citation, where the hypotheses bite. **Nothing more.** |
| **Reusable technique** | The argument will be redeployed elsewhere | Explain the technique, not the instance |
| **Proof-is-the-object** | Understanding the argument and understanding the object are the same act | Full treatment; this is where the budget goes |

An artifact that spends equal weight on all three has failed regardless of accuracy.

---

## 6. The no-verdict clause

**The constraint that matters most.** Primary sources are read here as instruments under pre-registered
predictions. Evaluative prose from an agent enters the same channel as the reader's own reaction and
cannot afterwards be separated from it.

**Never write:**

- Evaluative adjectives about mathematical content — *beautiful, elegant, powerful, deep, remarkable,
  striking, surprising, crucial, the key insight*.
- Any ranking of sections, results or chapters by interest, importance, or relevance.
- An assertion that source material connects to the research object — *"this is exactly your
  pushforward"*, *"directly relevant to your direction"*. State the mathematics; the connection is the
  reader's to make or refuse.
- Difficulty grading — *straightforward, subtle, the tricky part, easy to see*.
- Anticipation — *you'll find*, *the payoff comes later*, *this becomes important in §7*.
- A derivation of an object the reader has scheduled to derive independently. If a commit needs such an
  object, implement against its **interface**, state the interface, and stop. Pre-deriving it is the
  single most expensive failure this file exists to prevent.

**Write instead:** structural description. *"This section proves X under H1–H3. H2 is the hypothesis
that fails in infinite dimensions."* *"The code verifies the predicted exponent $p/(p+1)$; a measured
slope near 1 would falsify it."*

Neutrality is not blandness. A precise structural sentence carries more than an enthusiastic one.

---

## 7. The fork — do not touch it

An open, deliberately unresolved question governs which direction the research takes:
**forward** (pushforward stability under input-law and operator perturbation) versus **inverse**
(function-space Bayesian posterior as the object). A lean exists and is recorded; **it is explicitly not
a logged verdict.**

Agents must write as if neither branch has won. Do not open with *"since your direction is Bayesian
inverse problems…"*, do not frame forward material as preliminary to inverse material or vice versa, and
do not offer to resolve it. Material that serves both is the default and needs no comment.

---

## 8. Tooling and verification defaults

- **Julia** is the default language for numerics unless the source text or the plan says otherwise.
  Python is available and familiar; it is not the default.
- **Every numerical demonstration states a prediction before it computes anything.** The demonstration's
  value is that it *could have failed*. A plot that merely looks plausible is not a result — name the
  predicted exponent, constant, or rate, then measure it, then report agreement or falsification in
  those terms.
- **A bound that is not self-evident names its derivation, in one line.** Deriving bounds theory-first
  is already the implementer's obligation under the altitude contract; what this file adds is that the
  derivation must be *legible to the reader*, not only to the agent that produced it. One line, in the
  commit message — the increment's only durable explanation, and capped at ~15 lines, so a full
  derivation belongs in a docstring or a comment beside the number.

---

## 9. Who does not get this file, and why

The consumers are wired in four agents' `skills:` frontmatter and two skills' bodies; the authority on
that list is the **reader profile** coupling in `skills/pipeline-maintenance/SKILL.md`, not this
section — a roster restated here is a copy free to drift.

The two deliberate exclusions, which are decisions rather than wiring:

- **`commit-code-reviewer` — no.** Its objectives are correctness and contract adherence. Pedagogical
  calibration there invites findings outside its remit and inflates review noise.
- **`pipeline-retrospector` — no.** It reviews the run and produces no prose the reader reads.

---

## 10. Revision

Changes on the order of once per semester, and only for facts that hold across **every** source: a
prerequisite moving from *absent* to *owned*, a new standing notation, a correction that has fired more
than once.

Anything true of one text only goes in that repo's `CLAUDE.md` source-profile block. A per-source fact
recorded here is a second source of truth and will drift.

Edits go through **`/pipeline-maintenance`**, which owns the post-edit checklist this file is subject to.
