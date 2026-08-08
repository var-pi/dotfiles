#!/bin/sh
# validate-config.sh — schema and cross-reference check over the ~/.claude pipeline files.
#
# Exists because agent frontmatter and settings.json parse LOOSE: an unknown key is dropped, never
# flagged, so config that has quietly stopped working looks identical to config that works.
# `reasoning_effort:` sat in all seven agents for months (the real field is `effort:`), so two
# agents declared "xhigh" and ran at the session default with no warning anywhere.
#
# ERROR  -> a reference that cannot resolve. Exit 1.
# WARN   -> a key not in the published field table. Usually a typo; occasionally the docs moved
#           and this script is the stale one, so it never fails the run on its own.
#
# The field lists below are transcribed from the published tables at code.claude.com/docs/en
# ({sub-agents,skills}#frontmatter). Re-check them when a check-6 sweep says the harness moved.

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
AGENTS="$CLAUDE_DIR/agents"
SKILLS="$CLAUDE_DIR/skills"
SETTINGS="$CLAUDE_DIR/settings.json"

AGENT_FIELDS="name description tools disallowedTools model permissionMode maxTurns skills mcpServers hooks memory background effort isolation color initialPrompt"
SKILL_FIELDS="name description when_to_use argument-hint arguments disable-model-invocation user-invocable allowed-tools disallowed-tools model effort context agent background hooks paths shell metadata license compatibility"

errors=0
warns=0

err()  { printf 'ERROR  %s\n' "$1" >&2; errors=$((errors + 1)); }
warn() { printf 'WARN   %s\n' "$1" >&2; warns=$((warns + 1)); }

# Print the top-level frontmatter keys of a Markdown file, one per line.
fm_keys() {
    awk '
        NR == 1 && $0 != "---" { exit }
        NR == 1 { infm = 1; next }
        infm && $0 == "---" { exit }
        infm && /^[A-Za-z_][A-Za-z0-9_-]*:/ { sub(/:.*/, ""); print }
    ' "$1"
}

# Print the scalar value of a top-level frontmatter key ($2) in file $1, or nothing.
fm_value() {
    awk -v key="$2" '
        NR == 1 && $0 != "---" { exit }
        NR == 1 { infm = 1; next }
        infm && $0 == "---" { exit }
        infm && index($0, key ":") == 1 {
            sub(/^[^:]*:[ \t]*/, "")
            gsub(/^["'"'"']|["'"'"']$/, "")
            print; exit
        }
    ' "$1"
}

# Print the entries of the frontmatter list under key $2 in file $1, one per line.
fm_list() {
    awk -v key="$2" '
        NR == 1 && $0 != "---" { exit }
        NR == 1 { infm = 1; next }
        infm && $0 == "---" { exit }
        !infm { next }
        index($0, key ":") == 1 { inlist = 1; next }
        inlist && /^[ \t]+-[ \t]*/ { sub(/^[ \t]+-[ \t]*/, ""); print; next }
        inlist && /^[A-Za-z_]/ { inlist = 0 }
    ' "$1"
}

in_list() {
    for _item in $2; do
        [ "$_item" = "$1" ] && return 0
    done
    return 1
}

# ---------------------------------------------------------------- agents

for f in "$AGENTS"/*.md; do
    [ -e "$f" ] || continue
    base=$(basename "$f" .md)

    for k in $(fm_keys "$f"); do
        in_list "$k" "$AGENT_FIELDS" || warn "$base: unknown agent frontmatter key '$k' (dropped silently by the parser)"
    done

    name=$(fm_value "$f" name)
    [ -n "$name" ] || err "$base: no 'name' field (required)"
    [ -n "$(fm_value "$f" description)" ] || err "$base: no 'description' field (required)"
    if [ -n "$name" ] && [ "$name" != "$base" ]; then
        err "$base: frontmatter name '$name' does not match the filename; settings.json matchers and Agent(subagent_type:) both key on the name"
    fi

    # Preloaded skills must resolve, and must not block their own preload.
    for s in $(fm_list "$f" skills); do
        target="$SKILLS/$s/SKILL.md"
        if [ ! -f "$target" ]; then
            err "$base: preloads skill '$s', but $target does not exist (a missing core is skipped with only a debug-log warning)"
        elif [ "$(fm_value "$target" disable-model-invocation)" = "true" ]; then
            err "$base: preloads '$s', which sets disable-model-invocation: true — that also blocks preloading; use 'user-invocable: false' to keep a core out of the / menu"
        fi
    done
done

# ---------------------------------------------------------------- skills

for f in "$SKILLS"/*/SKILL.md; do
    [ -e "$f" ] || continue
    dir=$(basename "$(dirname "$f")")

    for k in $(fm_keys "$f"); do
        # 'skills:' is subagent-only. In a SKILL.md it parses, is dropped, and the skill runs
        # uncalibrated with nothing reporting it -- the reasoning_effort failure mode, and a mistake
        # this ecosystem has actually made. Loud, not a warning.
        if [ "$k" = "skills" ]; then
            err "$dir: 'skills:' is a subagent-only frontmatter field and is dropped silently here; a skill cannot preload another. Invoke it with the Skill tool instead (see feature-plan Phase 1)"
            continue
        fi
        in_list "$k" "$SKILL_FIELDS" || warn "$dir: unknown skill frontmatter key '$k' (dropped silently by the parser)"
    done

    name=$(fm_value "$f" name)
    if [ -n "$name" ] && [ "$name" != "$dir" ]; then
        warn "$dir: frontmatter name '$name' differs from the directory name; the invoked command stays /$dir"
    fi
done

# ---------------------------------------------------------------- settings.json

if [ ! -f "$SETTINGS" ]; then
    err "no $SETTINGS"
else
    # Matchers under SubagentStart/SubagentStop name an agent type; that agent must exist, or the
    # hook silently stops firing and every commit in a run goes unguarded. Both loops below run in
    # subshells (they are pipeline stages), so they report through a file rather than $errors.
    findings=$(mktemp)

    awk '
        /"(PreToolUse|PostToolUse|Notification|UserPromptSubmit|Stop|SubagentStart|SubagentStop|PreCompact|SessionStart|SessionEnd)"[ \t]*:/ {
            event = $0
            sub(/^[^"]*"/, "", event); sub(/".*/, "", event)
        }
        (event == "SubagentStart" || event == "SubagentStop") && /"matcher"[ \t]*:/ {
            v = $0
            sub(/^[^:]*:[ \t]*"/, "", v); sub(/".*/, "", v)
            print v
        }
    ' "$SETTINGS" | while IFS= read -r m; do
        agent=$(printf '%s' "$m" | sed 's/^\^//; s/\$$//')
        case "$agent" in
            *[\|\(\)\[\]\*\+\?]*) continue ;;   # a real regex, not a plain agent name
        esac
        [ -f "$AGENTS/$agent.md" ] ||
            printf 'settings.json: Subagent hook matcher "%s" names no agent in %s; the hook will never fire\n' "$m" "$AGENTS" >>"$findings"
    done

    # Every absolute command path a hook or the status line invokes must exist. It must also be
    # executable when invoked directly — but not when an interpreter runs it ("bash /path/x.sh"),
    # where the exec bit is irrelevant and demanding it is a false alarm.
    grep -o '"command"[ \t]*:[ \t]*"[^"]*"' "$SETTINGS" \
        | sed 's/^"command"[ \t]*:[ \t]*"//; s/"$//' \
        | while IFS= read -r cmd; do
            script=$(printf '%s' "$cmd" | awk '{for (i = 1; i <= NF; i++) if (substr($i, 1, 1) == "/") { print $i; exit }}')
            [ -n "$script" ] || continue
            direct=$(printf '%s' "$cmd" | awk '{print ($1 == "" || substr($1, 1, 1) == "/") ? "yes" : "no"}')
            if [ ! -f "$script" ]; then
                printf 'settings.json: command references %s, which does not exist\n' "$script" >>"$findings"
            elif [ "$direct" = "yes" ] && [ ! -x "$script" ]; then
                printf 'settings.json: %s is invoked directly but is not executable\n' "$script" >>"$findings"
            fi
        done

    while IFS= read -r line; do
        [ -n "$line" ] && err "$line"
    done <"$findings"
    rm -f "$findings"
fi

# ---------------------------------------------------------------- verdict

if [ "$errors" -gt 0 ]; then
    printf '\nFAIL: %s error(s), %s warning(s)\n' "$errors" "$warns" >&2
    exit 1
fi
printf 'OK: pipeline config resolves (%s warning(s))\n' "$warns"
exit 0
