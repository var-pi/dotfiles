PROMPT="⚡️"

alias ls="ls --color"
alias dotfiles="git --git-dir=$HOME/.dotfiles --work-tree=$HOME" 
alias drs='sudo darwin-rebuild switch --flake ~/.config/nix-darwin'

export JULIA_PROJECT="@."
export GH_TOKEN="$(security find-generic-password -s gh_token -a "$USER" -w)"

PATH="$HOME/bin:$PATH"
# Autocompletion for ollama.
fpath+=($HOME/.zsh_completions)
# Autocompletion for ymp.
fpath+=~/.zfunc
autoload -Uz compinit
compinit

# Search history based on input with ↑ and ↓.
autoload -U history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^[[A" history-beginning-search-backward-end
bindkey "^[[B" history-beginning-search-forward-end

# Jump words with ⌥ + ← and ⌥ + →
bindkey ";3D" backward-word
bindkey ";3C" forward-word

# For all completion contexts, automatically enter interactive menu selection whenever there are multiple completion candidates.
zstyle ':completion:*' menu select
