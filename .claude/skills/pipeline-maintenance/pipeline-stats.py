#!/usr/bin/env python3
"""What a pipeline run actually cost, read from the transcripts on disk.

Exists because the only cost figure an agent can see is `totalTokens` on an Agent tool
result, and that number EXCLUDES CACHE READS -- which are 60-75% of a run's tokens. On
the 07-sde-bridge feature it reported 1.31M across six implementer dispatches where the
transcripts say 222M, a 170x understatement. Every retrospective written against the
visible number was wrong by two orders of magnitude, so this reads the transcripts.

Usage:
    pipeline-stats.py <project-path-or-slug>                # roster: pick a run
    pipeline-stats.py <project> --sessions ID[,ID...]       # full report
    pipeline-stats.py <project> --since 2026-07-29          # full report
    pipeline-stats.py <project> --sessions ID --json        # machine-readable

A feature usually spans several top-level sessions (planning, then one per commit once
dispatch is per-session), so pass every session the feature touched -- the roster with no
filter lists them newest-first with dates.
"""

import argparse
import json
import os
import sys
from collections import defaultdict

# --- Prices, USD per million tokens -------------------------------------------------
# TRANSCRIBED from published pricing, so this table -- not the pipeline -- is the thing
# most likely to be the stale party. Cache multipliers are contractual: read 0.1x input,
# 5-minute write 1.25x input. Verify against the pricing page before trusting a delta of
# less than ~20%; the shape of a run (which tier burned the tokens) survives price drift,
# the dollar total does not.
PRICES = {
    # No pipeline node runs on Fable (see [[pipeline-ecosystem]], 2026-08-07). The row exists
    # anyway: DEFAULT is Opus-priced, so a hand-run Fable dispatch landing in a transcript would
    # otherwise be costed at half its real rate with nothing reporting the error.
    "claude-fable-5":      {"in": 10.00, "out": 50.00, "window": 1_000_000},
    "claude-opus-5":       {"in": 5.00, "out": 25.00, "window": 1_000_000},
    "claude-opus-4-8":     {"in": 5.00, "out": 25.00, "window": 1_000_000},
    "claude-sonnet-5":     {"in": 3.00, "out": 15.00, "window": 1_000_000},
    "claude-sonnet-4-6":   {"in": 3.00, "out": 15.00, "window": 1_000_000},
    "claude-haiku-4-5":    {"in": 1.00, "out":  5.00, "window":   200_000},
}
DEFAULT = {"in": 5.00, "out": 25.00, "window": 1_000_000}
CACHE_READ_MULT = 0.10
CACHE_WRITE_MULT = 1.25

# Agent names are read from the transcripts, never hardcoded, so this script keeps
# working across a rename. Only the ordering below is cosmetic. `commit-doc-writer` was retired
# on 2026-08-08 and is kept here on purpose: features measured before that date have a real tier
# under that name, and dropping it would sort those rows to the end of every historical report.
TIER_ORDER = ["commit-plan-implementer", "commit-code-reviewer", "commit-doc-writer",
              "feature-readme-writer", "feature-plan-reviewer", "project-plan-reviewer",
              "pipeline-retrospector", "Explore"]


def price(model):
    return PRICES.get(model or "", DEFAULT)


def cost_of(model, out, cr, cw, inp):
    p = price(model)
    return (inp / 1e6 * p["in"] + out / 1e6 * p["out"]
            + cr / 1e6 * p["in"] * CACHE_READ_MULT
            + cw / 1e6 * p["in"] * CACHE_WRITE_MULT)


def read_transcript(path):
    """Sum one transcript. Cache reads dominate, so they are counted per assistant turn."""
    acc = {"turns": 0, "inp": 0, "out": 0, "cr": 0, "cw": 0,
           "peak": 0, "model": None, "t0": None, "t1": None, "tools": 0}
    try:
        fh = open(path, encoding="utf-8")
    except OSError:
        return acc
    with fh:
        for line in fh:
            try:
                d = json.loads(line)
            except ValueError:
                continue
            ts = d.get("timestamp")
            if ts:
                if acc["t0"] is None or ts < acc["t0"]:
                    acc["t0"] = ts
                if acc["t1"] is None or ts > acc["t1"]:
                    acc["t1"] = ts
            if d.get("type") != "assistant":
                continue
            msg = d.get("message", {})
            u = msg.get("usage", {}) or {}
            model = msg.get("model")
            if model and not model.startswith("<"):
                acc["model"] = model
            acc["turns"] += 1
            acc["inp"] += u.get("input_tokens", 0)
            acc["out"] += u.get("output_tokens", 0)
            acc["cr"] += u.get("cache_read_input_tokens", 0)
            acc["cw"] += u.get("cache_creation_input_tokens", 0)
            ctx = (u.get("input_tokens", 0) + u.get("cache_read_input_tokens", 0)
                   + u.get("cache_creation_input_tokens", 0))
            acc["peak"] = max(acc["peak"], ctx)
            for blk in msg.get("content", []) or []:
                if isinstance(blk, dict) and blk.get("type") == "tool_use":
                    acc["tools"] += 1
    return acc


def load_session(session_dir_root, sid):
    """One top-level session: its own transcript plus every subagent beneath it."""
    main = read_transcript(os.path.join(session_dir_root, sid + ".jsonl"))
    subs = []
    sub_dir = os.path.join(session_dir_root, sid, "subagents")
    if os.path.isdir(sub_dir):
        for entry in sorted(os.listdir(sub_dir)):
            if not entry.endswith(".meta.json"):
                continue
            meta_path = os.path.join(sub_dir, entry)
            jsonl_path = meta_path[: -len(".meta.json")] + ".jsonl"
            if not os.path.exists(jsonl_path):
                continue
            try:
                meta = json.load(open(meta_path, encoding="utf-8"))
            except (OSError, ValueError):
                continue
            rec = read_transcript(jsonl_path)
            rec["agent"] = meta.get("agentType", "?")
            rec["desc"] = meta.get("description", "")
            rec["depth"] = meta.get("spawnDepth", 1)
            rec["parent"] = meta.get("parentAgentId")
            rec["id"] = os.path.basename(jsonl_path)[len("agent-"):-len(".jsonl")]
            subs.append(rec)
    subs.sort(key=lambda r: r["t0"] or "")
    return main, subs


def resolve_project(arg):
    root = os.path.expanduser("~/.claude/projects")
    # Order matters: a project's own repo path is a real directory too, so the transcript
    # lookup has to win over it. Only a directory that actually holds transcripts counts.
    for cand in (os.path.join(root, arg),
                 os.path.join(root, os.path.abspath(os.path.expanduser(arg)).replace("/", "-")),
                 arg):
        if os.path.isdir(cand) and any(f.endswith(".jsonl") for f in os.listdir(cand)):
            return cand
    sys.exit("no transcript directory for %r under %s" % (arg, root))


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("project", help="project path, or the slug under ~/.claude/projects")
    ap.add_argument("--sessions", help="comma-separated session ids to include")
    ap.add_argument("--since", help="include sessions whose last activity is >= YYYY-MM-DD")
    ap.add_argument("--json", action="store_true", help="emit JSON instead of a table")
    args = ap.parse_args()

    proj = resolve_project(args.project)
    all_ids = sorted(f[:-6] for f in os.listdir(proj) if f.endswith(".jsonl"))

    picked = None
    if args.sessions:
        picked = [s.strip() for s in args.sessions.split(",") if s.strip()]
    loaded = {}
    for sid in all_ids:
        if picked is not None and not any(sid.startswith(p) for p in picked):
            continue
        main_acc, subs = load_session(proj, sid)
        if main_acc["turns"] == 0 and not subs:
            continue
        if args.since and (main_acc["t1"] or "") < args.since:
            continue
        loaded[sid] = (main_acc, subs)

    if not loaded:
        sys.exit("no sessions matched")

    # ---- roster mode: no explicit selection, just show what is there ----------------
    if picked is None and not args.since:
        print("PIPELINE SESSIONS in %s" % os.path.basename(proj))
        print("  re-run with --sessions <id,...> or --since <date> for the full report\n")
        print("  %-12s %-17s %6s %9s  %s" % ("session", "last activity", "agents", "cost", "agent types"))
        rows = []
        for sid, (m, subs) in loaded.items():
            c = cost_of(m["model"], m["out"], m["cr"], m["cw"], m["inp"])
            for r in subs:
                c += cost_of(r["model"], r["out"], r["cr"], r["cw"], r["inp"])
            kinds = sorted({r["agent"] for r in subs})
            rows.append(((m["t1"] or ""), sid, len(subs), c, kinds))
        for t1, sid, n, c, kinds in sorted(rows, reverse=True):
            label = ", ".join(k for k in kinds[:3]) + (" +%d" % (len(kinds) - 3) if len(kinds) > 3 else "")
            print("  %-12s %-17s %6d %8.2f  %s" % (sid[:12], t1[:16], n, c, label or "-"))
        return

    # ---- full report ---------------------------------------------------------------
    by_agent = defaultdict(lambda: defaultdict(int))
    dispatches = []
    coord = {"turns": 0, "out": 0, "cr": 0, "cw": 0, "inp": 0, "peak": 0, "model": None}
    span = [None, None]
    for sid, (m, subs) in sorted(loaded.items()):
        for k in ("turns", "out", "cr", "cw", "inp"):
            coord[k] += m[k]
        coord["peak"] = max(coord["peak"], m["peak"])
        coord["model"] = coord["model"] or m["model"]
        for bound, key, cmp_ in ((0, "t0", min), (1, "t1", max)):
            if m[key]:
                span[bound] = m[key] if span[bound] is None else cmp_(span[bound], m[key])
        for r in subs:
            a = by_agent[r["agent"]]
            a["n"] += 1
            for k in ("turns", "out", "cr", "cw", "inp", "tools"):
                a[k] += r[k]
            a["peak"] = max(a["peak"], r["peak"])
            dispatches.append(r)

    def tot(d):
        return d["out"] + d["cr"] + d["cw"] + d["inp"]

    sub_cost = sum(cost_of(r["model"], r["out"], r["cr"], r["cw"], r["inp"]) for r in dispatches)
    coord_cost = cost_of(coord["model"], coord["out"], coord["cr"], coord["cw"], coord["inp"])
    grand_tokens = tot(coord) + sum(tot(r) for r in dispatches)
    grand_cost = sub_cost + coord_cost

    if args.json:
        print(json.dumps({
            "project": os.path.basename(proj),
            "sessions": sorted(loaded),
            "span": span,
            "total_tokens": grand_tokens,
            "total_cost_usd": round(grand_cost, 2),
            "coordinator": {**{k: coord[k] for k in ("turns", "out", "cr", "cw", "inp", "peak")},
                            "cost_usd": round(coord_cost, 2)},
            "by_agent": {a: {**{k: v for k, v in d.items()},
                             "cost_usd": round(sum(
                                 cost_of(r["model"], r["out"], r["cr"], r["cw"], r["inp"])
                                 for r in dispatches if r["agent"] == a), 2)}
                         for a, d in by_agent.items()},
            "dispatches": [{"agent": r["agent"], "desc": r["desc"], "depth": r["depth"],
                            "model": r["model"], "turns": r["turns"], "tools": r["tools"],
                            "tokens": tot(r), "cache_read": r["cr"], "peak_ctx": r["peak"],
                            "cost_usd": round(cost_of(r["model"], r["out"], r["cr"],
                                                      r["cw"], r["inp"]), 2),
                            "start": r["t0"], "end": r["t1"]} for r in dispatches],
        }, indent=2))
        return

    print("=" * 78)
    print("PIPELINE RUN  %s" % os.path.basename(proj))
    print("  sessions : %s" % ", ".join(s[:8] for s in sorted(loaded)))
    print("  span     : %s -> %s" % ((span[0] or "?")[:16], (span[1] or "?")[:16]))
    print("=" * 78)

    print("\nBY TIER   (cache-read is the dominant term; it is what the Agent tool hides)")
    print("  %-26s %3s %6s %10s %12s %9s %6s" %
          ("agent", "n", "turns", "output", "cache-read", "cost", "%"))
    ordered = sorted(by_agent.items(),
                     key=lambda kv: (TIER_ORDER.index(kv[0]) if kv[0] in TIER_ORDER else 99, kv[0]))
    for agent, d in ordered:
        c = sum(cost_of(r["model"], r["out"], r["cr"], r["cw"], r["inp"])
                for r in dispatches if r["agent"] == agent)
        print("  %-26s %3d %6d %10s %12s %9s %5.0f%%" %
              (agent, d["n"], d["turns"], "{:,}".format(d["out"]), "{:,}".format(d["cr"]),
               "${:,.2f}".format(c), 100 * c / grand_cost if grand_cost else 0))
    print("  %-26s %3s %6d %10s %12s %9s %5.0f%%" %
          ("coordinator (main session)", "-", coord["turns"], "{:,}".format(coord["out"]),
           "{:,}".format(coord["cr"]), "${:,.2f}".format(coord_cost),
           100 * coord_cost / grand_cost if grand_cost else 0))
    print("  " + "-" * 74)
    print("  %-26s %3s %6s %10s %12s %9s" %
          ("TOTAL", "", "", "", "{:,}".format(grand_tokens), "${:,.2f}".format(grand_cost)))

    # Review rounds: children of each implementer, keyed by parentAgentId.
    kids = defaultdict(list)
    for r in dispatches:
        if r["parent"]:
            kids[r["parent"]].append(r)
    impls = [r for r in dispatches if r["agent"] == "commit-plan-implementer"]
    if impls:
        print("\nPER COMMIT   (review rounds = independent reviews the implementer dispatched)")
        print("  %-34s %6s %6s %12s %9s %8s" %
              ("commit", "turns", "review", "cache-read", "cost", "peak ctx"))
        for r in sorted(impls, key=lambda x: x["t0"] or ""):
            children = kids.get(r["id"], [])
            rounds = sum(1 for k in children if k["agent"] == "commit-code-reviewer")
            c = cost_of(r["model"], r["out"], r["cr"], r["cw"], r["inp"])
            c += sum(cost_of(k["model"], k["out"], k["cr"], k["cw"], k["inp"]) for k in children)
            print("  %-34s %6d %6d %12s %9s %8s" %
                  ((r["desc"] or "?")[:34], r["turns"], rounds, "{:,}".format(r["cr"]),
                   "${:,.2f}".format(c), "{:,}".format(r["peak"])))

    print("\nPEAK CONTEXT   (a peak above the window means compaction fired mid-dispatch)")
    worst = sorted(dispatches + [dict(coord, agent="coordinator", desc="main session")],
                   key=lambda r: -r["peak"])[:5]
    for r in worst:
        win = price(r["model"])["window"]
        print("  %-34s %9s  %3.0f%% of %s window" %
              ((r.get("desc") or r["agent"])[:34], "{:,}".format(r["peak"]),
               100 * r["peak"] / win, r["model"] or "?"))

    print("\nNOTE  Prices are transcribed into this file and drift; the tier SHAPE is the")
    print("      durable signal. Reviewer findings are not counted here -- classifying them")
    print("      by severity needs a reading of the review, which is the retrospector's job.")


if __name__ == "__main__":
    main()
