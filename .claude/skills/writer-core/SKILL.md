---
name: writer-core
description: Shared doc craft for the planning pipeline's doc writers — the rushed-team-lead reader, layering and folding, signal hierarchy, the cut list, the stand-alone evidence bar. Preloaded into commit-doc-writer and feature-readme-writer; not a standalone workflow.
user-invocable: false
---

# Writer core

Shared working agreement for the pipeline's **doc writers** — `commit-doc-writer` (the
maintainer-facing `docs/commits/` file for one increment) and `feature-readme-writer` (the
outward-facing feature `README.md`). Each writer's own agreement carries its audience, its
sources, and its section shape; this file carries what they both do the same way. It is
**preloaded into your context at startup** (the writers' `skills:` frontmatter), so it is already
here — you need not go read it. If you are a writer and this text is *absent* from your context,
the preload failed: read `~/.claude/skills/writer-core/SKILL.md` before writing.

---

## Who you are writing for, and what that costs

**Write for a team lead who is in a rush — not for a peer who is happy to nerd out.** They are
technically capable but time-poor: they will skim, and they will decide within seconds whether a
section is worth their attention. Every rule below follows from that one fact.

The consequence most writers get backwards: **a doc that must be read linearly to be understood
has already failed**, however good its content is. Your reader arrives with a question ("what did
this change?", "why this approach?", "is the evidence real?") and needs to land on the answer
without reading the parts that answer some other question.

**Spend your own effort freely to save theirs.** Reading these docs is the single largest consumer
of the operator's time in this workflow, and their time is far more expensive than your tokens. So
an extra pass to halve a section's length, restructure it, or find the one sentence that replaces a
paragraph is **always** a good trade — write it long if that is how you find the content, then cut
it hard before you hand it back. Length is not thoroughness; **signal-to-noise is.**

> **The failure this prevents —** information overload causes *skipping*, and a reader who skips
> lands on the important part as often as the padding. Background that pushed the key point off the
> screen was not merely useless; it was **harmful**.

---

## Layer the doc — scannable surface, opt-in depth

Serve the skimmer and the deep reader at once, without making either pay the other's cost.

- **Front-load.** The first screen states what this is and why it matters. Nothing above it —
  no preamble, no setup, no throat-clearing.
- **Put depth behind a fold.** Use `<details><summary>…</summary>` for anything a rushed reader can
  legitimately skip: a long derivation, a parameter dump, raw run output, an extended narrative.
  Depth becomes **opt-in** instead of a wall the reader must scroll past. Reach for a fold whenever
  a passage is valuable-but-not-load-bearing; that is most long passages.
- **Write the `<summary>` as a real title — under ~8 words.** Short, specific, honest about what is
  inside, so the reader can decide without opening it. "The threshold that budgeted the wrong
  quantity" is a summary; "More details" is not; and neither is "Two ways a deterministic result like
  this can quietly lie, and what rules each one out" — a sentence in the title slot is not a title.
- **A fold buys opt-in, not exemption.** Everything inside `<details>` obeys every rule outside it:
  the cut list, the denser form, the structural-break cap below. Folded content that runs long needs
  its **own subheadings** — a fold is not a place to put an unstructured wall you did not want to
  edit. If the material is not worth structuring, it is not worth keeping.
- **Never hide anything essential behind a fold.** Some Markdown previews render `<details>`
  pre-expanded as plain text (still readable), and a skimmer will not open it. If the reader must
  know it, it goes above the fold.
- **Short, descriptive headings and subheadings** so the heading list alone works as a table of
  contents — a reader should be able to navigate by headings and skip what they don't need now.
- **One section, one object.** A passage covering two distinct named things gets **split**, with each
  named in its own heading. Headings are the navigation surface: a name a reader might scan or search
  for — a gate id, a function, a parameter — belongs in one, not buried in the fourth sentence of a
  shared paragraph.

---

## Make the important parts stand out

If every sentence is styled the same, everything reads as equally important and the reader's focus
spreads evenly over content that is not evenly valuable. Create a visible hierarchy:

- **Bold the load-bearing term** where it is introduced or where the point turns.
- **A blockquote callout led by a bold label** for the one or two things a reader must not miss:

  > **Key insight —** the estimator is unbiased *only* because the control variate reuses the same
  > seeded draw; decouple them and the variance blows up 40×.

- Use these **sparingly — one or two per document.** A callout on every paragraph is noise, and the
  reader stops seeing them. Same for bold: bolding half a paragraph bolds nothing.
- **Lead with the point** in every section and every list item; the elaboration comes after.

---

## Choose the denser form

Prose is the *most* expensive form for a skimmer. Use it only for reasoning that genuinely flows;
otherwise reach for:

- **tables** — anything comparative or enumerable (options, component→role, before/after,
  parameters, API surface);
- **lists** — steps, guarantees, highlights, the checks a test makes;
- **short fenced code blocks** — inline the small snippet the text discusses, so the reader stays in
  one place rather than opening the diff. Code fencing also *signals* "this is code or math" at a
  glance, which is worth having;
- **a mermaid diagram** — where a paragraph of "A feeds B feeds C" would otherwise be dense.

**Vary the rhythm — and treat it as a cap, not a taste.** Never run more than about **five
consecutive prose sentences** without a structural break: a heading, a table, a figure, a list, a
code block, a callout, or a fold. A multi-sentence bullet counts as prose, so a list of paragraphs
does not break anything. A wall of uniform prose reads as heavy no matter how good the content is,
and it is simply not read.

When a passage is long *and* genuinely insightful, that is not an exemption — it is the case the fold
exists for. Put it behind a titled `<summary>` and give it subheadings.

---

## Be ruthless about what you cut

One principle governs: **delete anything that adds no information the reader lacks.** Concretely,
cut on sight —

- **Restatements of the obvious.** Explaining that two test inputs are different numbers; narrating
  what a reader infers from the code in a second.
- **Defensive/"watch out" commentary about the code's mechanics.** "A transpose here would silently
  estimate the wrong matrix" belongs in a **code comment**, where the trap actually lives — not in
  the doc, where it is bulk. (The implementer is separately required to comment traps in code; do
  not duplicate that here.)
- **Negative space.** An inventory of what the change did *not* do. A single punchy scope line
  ("No library changes") is welcome; a catalogue is not. Keep a negative only when it answers a
  question a reader would genuinely raise — a deliberately narrow scope, a tempting generalization
  declined on purpose.
- **The antithesis tic — at most one per document.** "X, not Y" / "X rather than Y" / "X is A, but
  it is really B" is a rhetorical cadence that reads as insight and usually carries none. **The tell:
  was Y ever actually on the table?** "The nugget is reported rather than assumed" says nothing —
  nobody proposed assuming it. Use the construction once, where the contrast is the genuine point
  and the reader might really have expected Y; everywhere else, delete the negated half and state
  what is true.
- **Narration of the artifact's own structure.** "The body is deliberately the whole implementation:
  no re-derived FFT, no re-mirroring"; "the docstring carries the `r` convention and the raw-value
  contract". The reader wants the thing or what it does, never a tour of where it is written down.
- **Throat-clearing and filler transitions.** No "in this section we will", no motivational framing.

---

## Evidence must stand alone — figures, tables, display blocks

Embed the figures the work already produced, by relative path, **where you discuss them**
(`![caption](relative/path)`), so the evidence sits in the reader's line of sight instead of in a
directory they must go hunting through. Write a caption that says what the figure shows.

**Every embedded figure must carry its meaning on its own** — a title, labeled axes with units, a
legend where more than one series is drawn, and any annotation (scale, threshold, what a marker
encodes, and *what the plotted quantity actually is*: an aggregate over replicates reads very
differently from a single realization) that a reader would otherwise have to guess. **You do not
generate or fix figures.** If one fails that bar, **flag it in your handoff** rather than embedding
something the reader cannot read.

**The same bar applies to every block a reader can land on out of order** — a table, a fenced display
block, a quoted log. Column headers alone are not a caption: a table whose first column is `H` and
whose next two are `n = 1024` and `n = 4096` does not say *what is being tabulated*. Give each one a
lead-in or caption naming the quantity and its units, in the same sentence-or-less budget a figure
caption gets. A skimmer's eye lands on tables and code blocks first, which is exactly why an
unlabeled one costs more than an unlabeled paragraph.

## Never claim more than the evidence supports

Match the strength of every claim to the strength of what backs it, and **keep that calibration
consistent across the whole document.** A doc that says "shown numerically, not proved" in its
limitations and then asserts the same result as established mechanism elsewhere ("that is the
cancellation driving `D* → 0`") has contradicted itself, and the reader cannot tell which sentence to
believe. When you hedge a result once, carry the hedge everywhere it appears — or drop the hedge
because it was never warranted. Pick one.

---

## Style constraints

- **Avoid LaTeX.** It renders inconsistently — in a terminal or plain Markdown viewer, and even on
  GitHub, `$…$` / `\(…\)` can show up as raw source. Use Unicode symbols (`≤`, `σ`, `√`, `∑`,
  sub/superscripts), plain ASCII math (`x^2`, `sqrt(x)`, `sum_i`), or a fenced code block for
  anything multi-line.
- **No unexplained symbols or jargon.** Every symbol and term is either self-evident or defined
  where it first appears. A reader who is *not* well-versed in the topic should be able to catch up
  from the doc itself, without tabbing away — but give them that background **compactly and behind a
  fold when it runs long**, never as a wall in front of the point.
- **Match the project's house voice** where `CLAUDE.md` or an existing `README.md` establishes one.
  You are extending a style, not imposing a new one.

---

## Calibrate to weight

Size the document to the weight of what it describes. A trivial increment or a small utility gets a
tight doc that still nails the essentials; a load-bearing one earns real depth — **placed behind
folds** so its bulk never taxes the skimmer. **Never pad a small thing to look thorough, and never
compress a rich one to look tidy.** Any line counts your own agreement gives are **guardrails, not
targets.**

---

## Handoff

- **Write to the exact path(s) in your context bundle**, creating folders as needed. (Your own
  agreement states where that path comes from, and why you neither stage nor commit.)
- **Hand back one line:** the path(s) you wrote, plus any real defect, broken claim, or unreadable
  figure you noticed that the implementer should act on. A confirmation, not a re-explanation — the
  full content lives in the file.
