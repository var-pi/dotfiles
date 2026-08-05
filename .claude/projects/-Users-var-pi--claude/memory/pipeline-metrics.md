---
name: pipeline-metrics
description: "Rolling per-feature cost/turn/review measurements for the planning pipeline — appended by pipeline-retrospector at feature close, read by pipeline-maintenance to tell whether an ecosystem change actually landed"
metadata: 
  node_type: memory
  type: project
  originSessionId: 62ef5686-d2bf-4021-a940-22275557ab60
  modified: 2026-08-05T16:44:43.260Z
---

One row per finished feature, appended by `pipeline-retrospector` at close (its output #1) from
`python3 ~/.claude/skills/pipeline-maintenance/pipeline-stats.py <project> --sessions <ids>`.

**Why this file exists.** A single run's cost means nothing on its own. `/pipeline-maintenance`
changes rules that govern every future run and previously had no way to tell whether a change helped,
hurt, or did nothing — it argued from recollection. This is the series that makes the improvement
loop empirical. Part of the ecosystem recorded in [[pipeline-ecosystem]]; proposals live in
[[pipeline-improvement-inbox]].

**Record the model each tier ran on.** A tier's cost is not comparable across features that ran it
on different tiers, and the two seed rows below differ in exactly that way.

**Never hand-estimate a row.** The figure an agent can see (`totalTokens` on an Agent tool result)
**excludes cache reads**, which are 60–95% of a run — it understates by ~170×. Run the script.

## Rows

| feature | date | commits | total tokens | cost | implementer tier | turns/commit | reviews/commit | peak ctx |
|---|---|---|---|---|---|---|---|---|
| `06-fbm` | 2026-07-26 | 6 | 122.5M | $113.68 | Sonnet 5 | 93 | 1.0 | 208k |
| `07-sde-bridge` | 2026-07-29 → 08-04 | 8 | 478.8M | $445.24 | Opus 5 | 217 | 1.6 | 385k |

### Notes on the seed rows

Both were measured retroactively on 2026-08-05, from transcripts, during the maintenance session
that wrote this file — they are the baseline every later change is judged against.

- **Cost is concentrated and super-linear in turns.** Fitting `07-sde-bridge`'s seven execution
  dispatches gives `cache_read ∝ turns^1.56` (R²=0.948, n=7). Two of its eight commits were 60% of
  the implementer tier; the cheapest was 3%. Turn count is the lever; model tier is the smaller,
  linear one.
- **The tier split shifted between the two rows.** `06-fbm` ran the implementer on Sonnet 5 at 35%
  of run cost; `07-sde-bridge` ran it on Opus 5 at 60%. The Opus run used **2.3× more turns per
  commit** — but the feature was also much larger, so this is *not* clean evidence that the tier
  caused it. What it does rule out is the worry that Sonnet needs materially more turns: it did not.
- **The coordinator is not free.** 20% of `07-sde-bridge` ($90) went to the main session — 346 turns
  and 60M cache-read accumulated across a five-day unattended chain. This is the cost that
  one-commit-per-session dispatch is meant to reset.
- **Context is not yet binding, but the old note is stale.** Peaks of 208k → 385k sit at 21–39% of
  the 1M window, so nothing compacted. The retired claim worth not resurrecting is the 2026-07-24
  "context is not the bottleneck" framing measured against a 200k window — the *headroom* is what
  changed, not the conclusion.
