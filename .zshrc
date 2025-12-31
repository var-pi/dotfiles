# ---------------------
# Aliases
# ---------------------
alias ls="ls --color"
alias dotfiles="git --git-dir=$HOME/.dotfiles --work-tree=$HOME"
alias drs='sudo darwin-rebuild switch --flake ~/.config/nix-darwin'
alias sciml-master='~/scripts/mlx-cli/sciml-master.sh'

# ---------------------
# Environment Variables
# ---------------------
export PROMPT="⚡️"
export JULIA_PROJECT="@."
export GH_TOKEN="$(security find-generic-password -s gh_token -a "$USER" -w)"
export HF_TOKEN="$(security find-generic-password -s hf_token -a "$USER" -w)"
export OLLAMA_FLASH_ATTENTION=1
export OLLAMA_KV_CACHE_TYPE=q8_0

# ---------------------
# PATH
# ---------------------
export PATH="$HOME/bin:$PATH"

# ---------------------
# Autocompletion
# ---------------------
fpath+=($HOME/.zsh_completions)
fpath+=($HOME/.zfunc)
autoload -Uz compinit
compinit

# ---------------------
# History Search
# ---------------------
autoload -U history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^[[A" history-beginning-search-backward-end
bindkey "^[[B" history-beginning-search-forward-end

# ---------------------
# Word Jump
# ---------------------
bindkey ";3D" backward-word
bindkey ";3C" forward-word

# ---------------------
# Completion Menu
# ---------------------
zstyle ':completion:*' menu select

