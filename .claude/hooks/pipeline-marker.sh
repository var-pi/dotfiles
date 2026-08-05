#!/bin/sh
# Arms and disarms the pipeline guard for exactly as long as a commit-plan-implementer is running.
#
# Wired in ~/.claude/settings.json as a SubagentStart hook (`arm`) and a SubagentStop hook
# (`disarm`), both matching ^commit-plan-implementer$. Claude Code hooks fire on subagent
# lifecycle events, so the marker's lifetime can be bound to the dispatch itself — which is why
# feature-plan no longer arms or disarms it by hand, and why a halted run cannot strand an
# armed marker that blocks the operator's manual push.
#
# The marker is what activates hooks/pre-commit, hooks/pre-push and hooks/commit-msg; all three
# are inert without it. See ~/.claude/PIPELINE.md §5.
#
# Usage: pipeline-marker.sh arm|disarm   (hook JSON on stdin is not read)
set -u
action="${1:-}"
hooks_dir="$HOME/.claude/hooks"

cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
git_dir=$(git rev-parse --git-dir 2>/dev/null) || exit 0
marker="$git_dir/CLAUDE_PIPELINE_ACTIVE"

case "$action" in
    arm)
        # Point the repo at the shared hooks, but never overwrite a hooksPath the repo chose
        # itself — silently redirecting a project's own hooks would be worse than not guarding.
        configured=$(git config --local --get core.hooksPath 2>/dev/null || true)
        if [ -z "$configured" ]; then
            git config --local core.hooksPath "$hooks_dir" || exit 0
        elif [ "$configured" != "$hooks_dir" ]; then
            echo "pipeline-marker: this repo sets core.hooksPath=$configured, so the pipeline guard is NOT enforcing this dispatch. Arm it by hand if you want the guard." >&2
            exit 2  # SubagentStart cannot block; exit 2 only surfaces this warning to the operator.
        fi
        touch "$marker"
        ;;
    disarm)
        # Never exit 2 here: on SubagentStop that would block the subagent from finishing.
        rm -f "$marker"
        ;;
esac
exit 0
