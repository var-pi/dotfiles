# dotfiles

> A declarative Apple-Silicon workstation with a local Julia LLM living inside my editor.

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
- **Single 9B model, quantized KV cache.** The Master runs a 4-bit ~9B model with an
  8-bit KV cache and a 16k context window entirely on-device — no draft model, thinking
  disabled, so answers stream straight through.
- **Reproducible Julia.** Pinned environments with committed `Manifest.toml`s, `Revise`
  wired into `startup.jl`, and a format-add-commit-push shortcut for a tight loop.
- **Agentic workflows, versioned.** A custom Claude Code `plan-and-dispatch` skill and
  its reviewer/implementer agents are tracked right alongside the shell config.

## The Julia Master

The centerpiece. Instead of pasting code into a cloud chatbot, I select a region in
Neovim and press `am` — *Ask Master*. The selection is streamed to a local server and
the answer streams back, token by token, into a fresh markdown split.

```
  Neovim ──[ visual select + `am` ]──▶ curl ──▶ FastAPI  @ 127.0.0.1:8080
    ▲                                                │
    │                                                ▼
    │                                        MLX  ·  Qwen3.5-9B
    │                                        4-bit, single model
    │                                        (thinking off,
    │                                         8-bit KV, 16k context)
    │                                                │
    └────────────  streamed tokens (SSE)  ◀──────────┘
```

The server (`scripts/mlx-cli/julia-master-serve.py`) exposes an **OpenAI-compatible**
`/v1/chat/completions` streaming endpoint, which keeps the Neovim side
(`.config/nvim/lua/mlx.lua`) a thin `curl` + `jobstart` client — no plugin, no SDK.
The system prompt tunes the model into an expert Julia compiler engineer and SciML
researcher writing for a graduate-level applied mathematician: internals-first,
implementation-over-API, one insight per sentence, structured as Summary / Background /
Details.

Everything runs locally. It's private, offline-capable, and free to interrupt.

## The stack

| Layer | Choice | Why |
| --- | --- | --- |
| System | `nix-darwin` flake (`vortex`) | Declarative, reproducible macOS from a lockfile |
| Editor | Neovim, Lua config | `blink.cmp`, telescope, treesitter, LSP for Julia/Lua/Nix/LaTeX |
| Language | Julia (LTS + a `1.12` shim) | `Revise`, pinned envs, committed manifests |
| AI | MLX server + Claude Code | On-device Julia model; versioned agent workflows |
| Terminal | kitty + JetBrains Mono | — |
| Shell | zsh | The bare-repo `dotfiles` alias and a few sharp helpers |

A few shell helpers do the heavy lifting: `drs` rebuilds the system
(`darwin-rebuild switch`), `ucc` bumps just the Claude Code flake input, and `gpp`
formats, commits, and pushes a Julia project in one step.

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
├── .claude/                            # plan-and-dispatch skill + agents
└── scripts/mlx-cli/                    # the on-device Julia Master server
```
