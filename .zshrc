PROMPT="⚡️"
alias ls="ls --color"
alias dotfiles="git --git-dir=$HOME/.dotfiles --work-tree=$HOME" 
alias drs='sudo darwin-rebuild switch --flake ~/.config/nix-darwin'
nx() {
    kitty @ launch --cwd=current --keep-focus > /dev/null
    nvim "$@"
}
export JULIA_PROJECT="@."

PATH="$HOME/bin:$PATH"
fpath=($HOME/.zsh_completions $fpath)

bindkey '^[[1;3D' backward-word  # alt-left
bindkey '^[[1;3C' forward-word   # alt-right

export GH_TOKEN="$(security find-generic-password -s gh_token -a "$USER" -w)"

fpath+=~/.zfunc; autoload -Uz compinit; compinit

zstyle ':completion:*' menu select
