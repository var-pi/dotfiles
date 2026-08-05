---
name: figure-legibility-requirements
description: "User's standing requirement for any generated figure/graph/chart — self-explanatory and no clipped labels"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: cd14a2f2-201c-4b07-8f70-ab067d22f3a4
  modified: 2026-08-05T16:57:02.184Z
---

Any generated figure/graph/chart must be self-explanatory from the artifact itself: title,
axis labels (with units), and legends are strictly required wherever they apply. The reader
must not have to infer meaning from surrounding context or the code.

Additionally, labels must be *actually visible* — a common failure is titles/axis labels/
legends rendering outside the figure's visible box (clipped at the edge, only a few pixels
showing). Treat a clipped label as missing.

**Why:** The user raised both points explicitly about the [[commit-plan-implementer]] agent;
they care about outputs that stand on their own.

**How to apply:** Save with fitting margins (`bbox_inches="tight"` / `tight_layout()` or an
explicit padded layout) and open the saved image to confirm every label sits fully inside the
frame — rendering the plotting code is not enough, inspect the actual output file.

**Scope:** this is a standing preference for *any* figure produced for this user, in or out of the
pipeline. Inside the pipeline it is stated operationally once, in `commit-plan-implementer` →
*Make outputs self-explanatory*, which owns the bar because it owns the generating;
`commit-code-reviewer` and `writer-core` only name it and add their own check. Keep it that way —
the requirement was briefly restated in four places and the copies had started to differ. See
[[pipeline-ecosystem]].
