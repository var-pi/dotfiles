# dotfiles

> A declarative Apple-Silicon workstation — a private LLM inside my editor, and an agent
> pipeline that writes the commits.

My `$HOME`, under version control. No symlinks and no bootstrap script: the home directory
*is* the work tree of a bare git repository, and a [`nix-darwin`][nix-darwin] flake declares
the machine around it. The host is called `vortex`, and it's built for one thing —
implementing and verifying **stochastic-process numerics in Julia**.

|  |  |
| --- | --- |
| **[The Julia Master](#the-julia-master)** | A 9B model on-device, answering from a Neovim selection |
| **[The planning pipeline](#the-planning-pipeline)** | Skills and subagents running a project → feature → commit ladder |
| **[The machine](#the-machine)** | One flake, one lockfile, Touch ID `sudo` |
| **[The bare-repo trick](#the-bare-repo-trick)** | Why there's no `stow` and no symlink farm |

[nix-darwin]: https://github.com/nix-darwin/nix-darwin

---

## The Julia Master

**Not a general assistant.** The system prompt casts it as an expert in the *numerical
analysis of stochastic processes and computational probability* — covariance operators and
their factorizations, Gaussian-process sampling, Monte-Carlo convergence rates, quadrature,
the FFT — writing for someone who implements and verifies estimators rather than calls APIs.

Select a region in Neovim and press `am` — *Ask Master*. The selection streams to a local
server; the answer streams back, token by token, into a fresh markdown split.

```
  Neovim ──[ visual select + `am` ]──▶ curl ──▶ FastAPI @ 127.0.0.1:8080
    ▲                                                       │
    │                                                       ▼
    │                                                MLX · Qwen3.5-9B
    │                                                       │
    └──────────────  streamed tokens (SSE)  ◀───────────────┘
```

|  |  |
| --- | --- |
| **Model** | `Qwen3.5-9B` at 5-bit — one model, no draft, thinking off |
| **Cache** | 8-bit KV, 16k context |
| **Server** | `scripts/mlx-cli/julia-master-serve.py` — FastAPI, OpenAI-compatible `/v1/chat/completions` |
| **Client** | `.config/nvim/lua/mlx.lua` — `curl` + `jobstart`. No plugin, no SDK |

<details>
<summary><b>The system prompt</b> — its scope, its reader, and the rules on how it answers</summary>

**Scope.** Covariance operators and their factorizations (Cholesky and other square roots,
spectral/Bochner, Karhunen–Loève / Mercer); Gaussian-process sampling, Monte-Carlo
estimators and their convergence rates, quadrature, and the FFT; Julia numerics
(`LinearAlgebra`, `FFTW`, `StableRNGs`) and reproducible stochastic code.

**Reader.** A mathematically mature applied mathematician, assumed strong in probability,
stochastic processes, functional analysis, spectral theory and numerical linear algebra,
whose goal is to implement and verify solvers — not to consume APIs.

**Output rules.** Explain *why* the code exists, not what it does. Name the mathematical
object behind it — which operator, which square root, which convergence rate or spectral
convention. One sentence, one insight. Never explain the obvious. Answer as
Summary / Background / Details.

</details>

> Everything runs locally. It's private, offline-capable, and free to interrupt.

---

## The planning pipeline

The other half of the repo is a Claude Code ecosystem that plans and writes code on this
machine — a **project → feature → commit** ladder, versioned right alongside the shell config.

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

**Four human steps:** two `ExitPlanMode` approvals, one session per commit, and the push.
The review rounds, the test-first implementation and the *N of M landed* bookkeeping run
without me — state travels in `docs/plan/` and a `CLAUDE.md` block, never a live session, so
an interruption lands *between* commits rather than inside one.

<details>
<summary><b>The altitude contract</b> — why a plan never contains code</summary>

Each rung owns exactly one thing and copies nothing from the rung above.

| Rung | Owns |
| --- | --- |
| `/project-plan` | The through-line, the decomposition into features, repo architecture, the risk register |
| `/feature-plan` | The decomposition into commits, the contract surface between them, what each test must *discriminate* |
| the implementer | Code bodies, all test mechanics, every numeric bound — derived theory-first — and the commit message |

So a plan carries no code body, no test expression, no tolerance. Those get decided once, at
the moment the code is written, and there is only ever one source of truth to drift.

</details>

<details>
<summary><b>The git guard</b> — an agent can commit; only I can push</summary>

`SubagentStart` / `SubagentStop` hooks arm a marker for exactly the window a dispatched
implementer is touching the repo. While it's armed, `pre-push` rejects unconditionally and
`commit-msg` rejects a degenerate message. Outside that window my own pushes are untouched,
and a halted run can't strand an armed marker.

Enforcement sits at the git layer rather than in an agent's instructions because it catches a
commit by **any** route, not only one made through a tool call.

</details>

<details>
<summary><b>How it improves itself</b> — retrospectives, into an inbox rather than into the files</summary>

At feature close a retrospector measures what the run actually cost — tokens, turns, peak
context, per tier and per commit — appends a row to a metrics memory, and files proposals to
an improvement inbox.

It **proposes only**. Those files govern every future run, and a run closes unattended, so
editing them there would change behaviour with nobody reading the diff. `/pipeline-maintenance`
works the queue with me present; an item left in the inbox resurfaces next cycle, which is
the point.

</details>

`.claude/PIPELINE.md` is the map: who dispatches whom, where the gates sit, what each
artifact path is.

---

## The machine

**Declared, not installed.** Packages, Touch ID `sudo`, and even the Claude Code binary live
in `.config/nix-darwin/flake.nix`. One command rebuilds the system; a lockfile reproduces it.

| Layer | Choice | Why |
| --- | --- | --- |
| System | `nix-darwin` flake (`vortex`) | Declarative, reproducible macOS from a lockfile |
| Editor | Neovim, Lua config | `blink.cmp`, telescope, treesitter, LSP for Julia/Lua/Nix/LaTeX |
| Language | Julia (LTS + a `1.12` shim) | `Revise` on interactive start, pinned envs, committed manifests |
| AI | MLX server + Claude Code | On-device Julia model; a versioned planning pipeline |
| Terminal | kitty + JetBrains Mono | — |
| Shell | zsh | The bare-repo alias, and four helpers that do the heavy lifting |

| Helper | Does |
| --- | --- |
| `drs` | `darwin-rebuild switch` — the whole system, from the flake |
| `ucc` | Bump just the Claude Code flake input |
| `jms` | Bring the Julia Master up |
| `gpp` | Format, add, commit and push a Julia project in one step |

---

## The bare-repo trick

No `stow`, no symlink farm. A single alias does it all:

```sh
alias dotfiles="git --git-dir=$HOME/.dotfiles --work-tree=$HOME"
```

The git directory lives at `~/.dotfiles`, but the *work tree* is `$HOME` itself, so tracked
files sit exactly where they belong. `dotfiles status`, `dotfiles add`, `dotfiles commit` —
ordinary git, aimed at home. A blanket `*` in `~/.gitignore` keeps the noise out: the whole
home directory is ignored by default, so nothing is ever tracked except on purpose, with `-f`.

<details>
<summary><b>Layout</b> — what's actually tracked</summary>

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
│   ├── skills/                         # project-plan, feature-plan, maintenance, dotfiles-sync, …
│   ├── agents/                         # the plan reviewers, implementer, code reviewer, …
│   └── hooks/                          # the marker-gated git guard
└── scripts/mlx-cli/                    # the on-device Julia Master server
```

</details>
