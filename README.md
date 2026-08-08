# dotfiles

> A declarative Apple-Silicon workstation — a local Julia LLM inside my editor, and a
> versioned agent pipeline that plans and writes the code.

My `$HOME`, under version control. There are no symlinks and no bootstrap script —
the whole home directory *is* the work tree of a bare git repository, and a
[`nix-darwin`](https://github.com/nix-darwin/nix-darwin) flake declares the machine
around it. The host is called `vortex`, and it's built for one thing: implementing
solvers for **Scientific Machine Learning in Julia**.

## Highlights

- **The whole macOS system is a flake.** Packages, Touch ID `sudo`, and even the
  Claude Code binary are declared in `.config/nix-darwin/flake.nix` and rebuilt with a
  single command. The machine is reproducible from a lockfile.
- **A private LLM lives in my editor.** A domain-specialized model — the *Julia
  Master* — runs on-device via [MLX](https://github.com/ml-explore/mlx) and answers
  questions about a visual selection without a single byte leaving the laptop.
- **Single 9B model, quantized KV cache.** The Master runs a 5-bit ~9B model with an
  8-bit KV cache and a 16k context window entirely on-device — no draft model, thinking
  disabled, so answers stream straight through.
- **Reproducible Julia.** Pinned environments with committed `Manifest.toml`s, `Revise`
  wired into `startup.jl`, and a format-add-commit-push shortcut for a tight loop.
- **A whole planning pipeline, versioned.** Three Claude Code skills, six subagents and a
  marker-gated git guard run a project → feature → commit ladder — tracked right alongside
  the shell config, and steered by its own retrospectives.

## The Julia Master

The centerpiece. Instead of pasting code into a cloud chatbot, I select a region in
Neovim and press `am` — *Ask Master*. The selection is streamed to a local server and
the answer streams back, token by token, into a fresh markdown split.

```
  Neovim ──[ visual select + `am` ]──▶ curl ──▶ FastAPI  @ 127.0.0.1:8080
    ▲                                                │
    │                                                ▼
    │                                        MLX  ·  Qwen3.5-9B
    │                                        5-bit, single model
    │                                        (thinking off,
    │                                         8-bit KV, 16k context)
    │                                                │
    └────────────  streamed tokens (SSE)  ◀──────────┘
```

The server (`scripts/mlx-cli/julia-master-serve.py`) exposes an **OpenAI-compatible**
`/v1/chat/completions` streaming endpoint, which keeps the Neovim side
(`.config/nvim/lua/mlx.lua`) a thin `curl` + `jobstart` client — no plugin, no SDK.
The system prompt casts the model as an expert in the **numerical analysis of
stochastic processes and computational probability in Julia**, writing for a
mathematically mature applied mathematician who wants to implement and verify
solvers and estimators rather than consume APIs. Its declared scope is covariance
operators and their factorizations (Cholesky and other square roots, spectral/Bochner,
Karhunen–Loève / Mercer), Gaussian-process sampling, Monte-Carlo convergence rates,
quadrature, and the FFT. The output rules are strict: explain why the code exists
rather than what it does, name the mathematical object behind it — which operator,
which square root, which convergence rate — one insight per sentence, nothing obvious,
all structured as Summary / Background / Details.

Everything runs locally. It's private, offline-capable, and free to interrupt.

## The planning pipeline

The other half of the repo is a Claude Code ecosystem that plans and writes code on this
machine. It runs a **project → feature → commit** ladder, and the human steps are
deliberately few:

```
  a brief or source text
    │
    ▼
  /project-plan  ⇄ project-plan-reviewer  ──[ HUMAN GATE ]──▶  docs/plan/
    │                                                          plan + one brief per feature
    ▼
  /feature-plan  ⇄ feature-plan-reviewer  ──[ HUMAN GATE ]──▶  one plan file per commit
    │
    ▼  one session per commit, until the feature lands
  commit-plan-implementer ──▶ commit-code-reviewer ──▶ one local commit
                                                            │
                                                            ▼
                                                    I review and push, by hand
```

Two `ExitPlanMode` approvals, one session per commit, and the push. The review rounds, the
test-first implementation, and the *N of M landed* bookkeeping run without me — state
travels in `docs/plan/` and a `CLAUDE.md` block, never a live session, so an interruption
lands *between* commits rather than inside one.

What holds it together is an **altitude contract**: each rung owns exactly one thing and
copies nothing from the rung above. A plan says what a test must *discriminate*; it never
carries a code body, a test expression, or a tolerance. Those belong to the implementer,
derived theory-first at the moment the code is written — so there is only ever one source
of truth to drift.

A **git guard** enforces the last boundary. `SubagentStart`/`SubagentStop` hooks arm a
marker for exactly the window a dispatched implementer is touching the repo, and while it's
armed `pre-push` rejects unconditionally. An agent can commit; only I can push.

It also improves itself: at feature close a retrospector measures what the run actually
cost — tokens, turns, peak context, per tier — and files proposals to an inbox that
`/pipeline-maintenance` works through with me present, never unattended, because those files
govern every future run. `.claude/PIPELINE.md` is the map.

## The stack

| Layer | Choice | Why |
| --- | --- | --- |
| System | `nix-darwin` flake (`vortex`) | Declarative, reproducible macOS from a lockfile |
| Editor | Neovim, Lua config | `blink.cmp`, telescope, treesitter, LSP for Julia/Lua/Nix/LaTeX |
| Language | Julia (LTS + a `1.12` shim) | `Revise`, pinned envs, committed manifests |
| AI | MLX server + Claude Code | On-device Julia model; a versioned project → feature → commit pipeline |
| Terminal | kitty + JetBrains Mono | — |
| Shell | zsh | The bare-repo `dotfiles` alias and a few sharp helpers |

A few shell helpers do the heavy lifting: `drs` rebuilds the system
(`darwin-rebuild switch`), `ucc` bumps just the Claude Code flake input, `jms` brings the
Julia Master up, and `gpp` formats, commits, and pushes a Julia project in one step.

## The bare-repo trick

There's no `stow`, no symlink farm. A single alias does it all:

```sh
alias dotfiles="git --git-dir=$HOME/.dotfiles --work-tree=$HOME"
```

The git directory lives at `~/.dotfiles`, but the *work tree* is `$HOME` itself, so
tracked files sit exactly where they belong. `dotfiles status`, `dotfiles add`,
`dotfiles commit` — ordinary git, aimed at home.

## Layout

```
~
├── .zshrc                              # aliases, helpers, the dotfiles trick
├── .config/
│   ├── nix-darwin/flake.nix            # the whole machine, declared
│   ├── nvim/                           # Lua config; lua/mlx.lua drives "Ask Master"
│   └── kitty/                          # terminal + JetBrains Mono
├── .julia/
│   ├── config/startup.jl               # Revise on interactive start
│   └── environments/                   # pinned, manifest-locked envs
├── .claude/
│   ├── PIPELINE.md                     # the map: who dispatches whom, where the gates are
│   ├── skills/                         # project-plan, feature-plan, maintenance, dotfiles-sync
│   ├── agents/                         # the plan reviewers, implementer, code reviewer, …
│   └── hooks/                          # the marker-gated git guard
└── scripts/mlx-cli/                    # the on-device Julia Master server
```
