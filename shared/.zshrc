# .zshrc - Zsh configuration

# Path to your oh-my-zsh installation (if installed)
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load
# Recommend: "robbyrussell" or "agnoster"
ZSH_THEME="robbyrussell"

# Plugins
plugins=(
  git
  docker
  terraform
  aws
  node
  npm
  python
  vscode
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# Source oh-my-zsh if installed
[[ -f $ZSH/oh-my-zsh.sh ]] && source $ZSH/oh-my-zsh.sh

# Load platform-specific zprofile (loaded automatically by zsh, but explicitly included here)
[[ -f $HOME/.zprofile ]] && source $HOME/.zprofile

# Load aliases
[[ -f $HOME/.aliases ]] && source $HOME/.aliases

# Load functions
[[ -f $HOME/.functions ]] && source $HOME/.functions

# History configuration
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

# Basic auto/tab completion
autoload -U compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
compinit

# Use vim keys in tab complete menu
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history

# Common environment variables
export EDITOR='vim'
export VISUAL='vim'
export PAGER='less'
export LANG='en_US.UTF-8'
export LC_ALL='en_US.UTF-8'

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='vim'
fi

# Rust - Source cargo environment if installed
[[ -f $HOME/.cargo/env ]] && source $HOME/.cargo/env

# Node Version Manager (nvm)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Python - pyenv if installed
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

# Ruby - rbenv if installed
if command -v rbenv 1>/dev/null 2>&1; then
  eval "$(rbenv init -)"
fi

# Go
[[ -d "$HOME/go/bin" ]] && export PATH="$HOME/go/bin:$PATH"

# Custom bin directory
[[ -d "$HOME/bin" ]] && export PATH="$HOME/bin:$PATH"
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"