# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc

# Git aliases
alias gtree="git log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)%C(bold blue) <%an> %Creset' --abbrev-commit"
alias g3="git log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)%C(bold blue) <%an> %Creset' --abbrev-commit"
alias gt="git log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)%C(bold blue) <%an> %Creset' --abbrev-commit"
alias gst='git status'
alias gss='git status'
alias grt='git restore'
alias grta='git reset'
alias gcm='git commit -m'
alias gcdm='git commit --amend'
alias gph='git push'
alias gpu='git pull'
alias gdd='git diff'
alias gadd='git add'
alias gb='git branch'
alias gba='git branch -a'
alias gck='git checkout'
alias gckb='git checkout -b'
alias gch='git checkout'
alias gchb='git checkout -b'
alias gfa='git fetch --all'
alias gdiff='git diff'
alias gdf='git diff'
alias grv='git remote -v'
alias gra='git remote add' 
alias gc=git-crypt
alias gg=lazygit

# Shell aliases
alias vi=hx
alias la='ls -a'
alias ll='ls -l'
alias lla='ls -la'

# PATH
. "$HOME/.cargo/env"

# fzf
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

eval "$(starship init bash)"
eval "$(zoxide init bash)"
eval "$(fzf --bash)"
