---
name: dotfiles-sync
description: Review, commit, and push changes in the ~/.dotfiles bare repo (the "dotfiles" alias, git --git-dir=~/.dotfiles --work-tree=~). Surveys modified tracked files, lets the user opt new paths into tracking, bundles changes into logically-grouped descriptive commits, and pushes to origin. Use when the user asks to sync/commit/push their dotfiles, or update the dotfiles repo.
---

# Dotfiles sync

Drives the bare-repo dotfiles workflow end to end: survey → add → commit → push.

## The repo

A bare repo at `~/.dotfiles` with work-tree `~`, aliased in `.zshrc` as:

```
alias dotfiles="git --git-dir=$HOME/.dotfiles --work-tree=$HOME"
```

**Always spell out the full `git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" ...` form in
commands you run** rather than the `dotfiles` alias — alias expansion in non-interactive shells
is unreliable, and the explicit form always works.

**Critical hazard**: the work-tree is the *entire home directory*. `~/.gitignore` contains a
blanket `*` rule (the standard bare-repo-dotfiles trick) so `status`/`diff` stay quiet and
nothing new is ever staged by accident — but it means:
- Every path is ignored by default. Adding a genuinely new file requires `-f` (see Step 2).
- `$HOME` also holds real credentials (`.ssh`, `.aws`, `.netrc`, session tokens, `.env` files).
  The blanket ignore is the main safety net, but **never** run `git add -A`, `git add .`, or any
  glob add regardless — only ever `git add` an exact path the user explicitly named.

## Step 1 — Survey changes to already-tracked files

```
git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" status --short --untracked-files=no
git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" diff
```

This shows modifications/deletions to files the repo already tracks, with none of the
home-directory noise. Read the diff — you'll need it in Step 3 to write commit messages that
say *why*, not just *what*.

## Step 2 — Offer to track new paths

Ask the user whether there's anything new they want the dotfiles repo to start tracking. Don't
go hunting through the untracked-file flood yourself and don't suggest speculative additions —
this is opt-in, one path at a time.

For each path the user names:
1. Resolve it to an absolute path under `$HOME` and confirm it exists.
2. Refuse (and say why) anything that looks like a secret: `.ssh`, `.aws`, `.netrc`, `id_rsa*`,
   `*token*`, `*credential*`, `.env`, or similar. If genuinely unsure, ask before adding.
3. `git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" add -f "<exact path>"` — one path per
   invocation, never a glob or a directory add unless the user named that exact directory. `-f`
   is required because `~/.gitignore` ignores everything by default; it's still an explicit,
   one-path-at-a-time add, not a bypass of the care above.

## Step 3 — Group into logical commits

Don't squash everything into one commit. Cluster the changed/staged files by logical concern
(e.g. all nvim config together, all Julia environment files together, an unrelated README edit
on its own) and commit each cluster separately:

```
git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" add <files in this cluster>
git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" commit -m "$(cat <<'EOF'
<what changed and why, one cluster's worth>

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

Write the message from the diff content, not the filename — say what changed and why it
matters, matching this harness's normal commit-message conventions.

## Step 4 — Confirm, then push

Pushing is the one step here that touches shared state and is harder to walk back, so pause for
a quick go-ahead first. Show what's about to go out:

```
git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" log --oneline origin/main..HEAD
```

Once confirmed:

```
git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" push
```

Never use `--force`, `reset --hard`, or other destructive flags here.
