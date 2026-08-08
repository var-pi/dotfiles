---
name: handoff-core
description: Shared bundle contract for the planning pipeline's agent-to-agent handoffs. Preloaded into the implementer and the three receiving agents; not a standalone workflow.
user-invocable: false
---

# Handoff core

The pipeline's three agent-to-agent **handoff bundles** — what one agent must hand the next when it
dispatches it, and what the receiver checks on arrival. This file is the single source for those
field sets: the sending agreement names the bundle, the receiving agreement names the bundle, and
neither restates its fields, so the two ends cannot drift apart.

It is **preloaded into your context at startup** (via the `skills:` frontmatter of
`commit-plan-implementer`, `commit-code-reviewer`, `feature-readme-writer`, and
`pipeline-retrospector`), so it is already here — you need not go read it. If you are one of
those agents and this text is *absent* from your context, the preload failed: read
`~/.claude/skills/handoff-core/SKILL.md` before dispatching or before starting work.

**`feature-plan` cannot preload this file** — `skills:` is a subagent-only frontmatter field,
and the planner is a skill. It invokes `handoff-core` through the `Skill` tool when it reaches the
retrospective bundle at Phase 6.

## Why a bundle has a fixed shape

A bundle is composed at dispatch time, so its completeness used to depend on the dispatching agent
remembering the list. **A dropped field fails silently**: the receiver has no way to tell a field
that was omitted from one there was nothing to say about, so it produces a plausible artifact with
a hole in it and nobody learns which field went missing. Fixing the shape is what converts that
into a signal.

## The protocol — both ends

**Sender: dispatch in the foreground.** Pass `run_in_background: false` on the `Agent` call, every
time. Since Claude Code v2.1.198 a subagent dispatched without it **runs in the background by
default**, and a background result arrives as a completion notification in a *later* turn — so your
own dispatch can end while the child is still working, and its result then surfaces to whoever is
listening, which may not be you. Every handoff in this file is **sequential and dependent** — you
cannot fix a review you have not read, stage a doc that is not written, or gate a commit that has
not landed — so there is nothing to overlap and the default buys the pipeline nothing.

*This is not hypothetical.* The two features that recorded stalled dispatches, children that never
reported, and results "addressed to someone else" are exactly the two whose nested dispatches went
out backgrounded. The recovery rules those incidents produced still stand — re-dispatch once, merge
a late result rather than discarding it — but they are the net, not the fix.

**Sender: every field appears, even when empty.** A field with nothing to report is written
explicitly as `none` (`deviations from plan: none`). Omitting it is not the same message, and
this is the half that makes the receiver's check mean anything — without it, a gap and a genuine
nothing look identical on arrival.

**Receiver: name the gap, then proceed.** On arrival, check the bundle against your field list
below. If a field is missing — not `none`, but absent — **say so in your handback** ("the bundle
carried no test list; I read the diff for it") and get on with the work using what you can
recover yourself. Do **not** stall, and do **not** hand back asking for the missing field: a
handoff that returns without its work done costs the run a manual recovery, which is the same
principle as `commit-plan-implementer`'s *never return in a waiting state*.

**The field list is a floor, not a specification of your output.** It says what must reach you,
never what your artifact contains — that is your own agreement's business, and for the README
writer the bundle is deliberately a **superset** it selects from. A sender that starts
prescribing content has stopped filling a bundle and started competing with the receiving
agreement.

## The three bundles

### Code-review bundle — `commit-plan-implementer` → `commit-code-reviewer`

- the increment's **goal**;
- its **contract surface** and **pre-resolved decisions**;
- the **test intent**;
- **where the change lives** (paths).

### Feature-README bundle — `commit-plan-implementer` → `feature-readme-writer`

- the exact **README path(s)** from the plan;
- the **feature slug** and the **set of commits** that make up the feature, with the
  through-line/intent;
- the **commit range** the feature spans, so the writer can read each increment's own explanation
  out of `git log`;
- any **deviation from the plan** worth surfacing to a reader.

### Retrospective bundle — `feature-plan` → `pipeline-retrospector`

- the **feature slug** and its through-line, and **where the plans were persisted**
  (`~/.claude/plans/`);
- the **two memory paths** it may write — the improvement inbox and the metrics record — since it
  cannot be expected to locate the operator's memory directory by guessing;
- the **commit range** the feature spans and the **README path**;
- the **project slug and every session id the feature ran across**, so the retrospector can run
  `pipeline-stats.py` over the whole run. Dispatch is one commit per session, so the feature spans
  several sessions and no single transcript holds it; this list is the only thing that cannot be
  recovered from disk afterwards. *Token counts are deliberately **not** a field:* the number the
  planner can see excludes cache reads and understates by ~170×, so passing it forward would launder
  a wrong figure into the record. The retrospector measures instead.
- every point where the **operator intervened**, a **commit was re-dispatched**, or a **gate went
  marginal**.

## Changing a bundle

Add or remove a field **here**, then check that the sending and receiving agreements still only
*name* the bundle rather than listing it. A field list that reappears inline in either agreement
is the drift this file exists to prevent.
