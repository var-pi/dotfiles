---
name: pipeline-improvement-inbox
description: "Rolling queue of pipeline-improvement suggestions from plan-and-dispatch feature-close retrospectives, consumed and reconciled by pipeline-maintenance"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: b5754bbc-be30-4fea-9c42-56f330fe29c6
  modified: 2026-07-25T14:42:11.842Z
---

Rolling inbox of **pipeline-improvement suggestions**. The `pipeline-retrospector` subagent files
here at feature close (dispatched by `plan-and-dispatch` Phase 6); `pipeline-maintenance` reads this
first (its Intake step), acts on what it can, then **reconciles** — deletes an implemented item,
annotates a deferred one with the reason. An item left here resurfaces next cycle; that is
intentional. Part of the improvement-inbox loop recorded in [[plan-and-dispatch-ecosystem]].

**How to file (retrospector):** add a bullet under a `## <date> — <feature-slug>` heading carrying
the **principle** (the rule that should exist, generalized — never the incident verbatim), the
**evidence** (one line), the **owning file**, and the **cost of not doing it**. Filing nothing is a
fine outcome. Link related design records with [[…]].

**How to reconcile (maintainer):** on implementing a suggestion, delete its bullet (the change is
now recorded in [[plan-and-dispatch-ecosystem]]); on deferring, append `— deferred: <reason>`.

---

## 2026-07-24 — deferred candidates (evaluated during the 05-bm-scaling-limit tune-up)

- Standalone **API-doc artifacts** so an agent needn't scan whole implementation files — deferred:
  the plan's pinned **contract surface** already serves this for the implementer; build only if a
  future run shows implementation-file reads are a real token sink (context is not the bottleneck).
- Route **Explore** onto a cheaper model than the session's Opus — deferred: Explore was ~35k
  (right-sized), and its model is harness-controlled (inherits the session, capped at Opus), so
  there is nothing cheap to change in our files.
- A dedicated **planner context-offload subagent** — still deferred *as context relief* (planner
  context peaked at ~33%; context is not the bottleneck). Partly overtaken 2026-07-25: Phase 6's
  retrospective moved to the new `pipeline-retrospector` subagent — but for **independence**, not
  context, since the planner reviewing its own run is the author's account.
