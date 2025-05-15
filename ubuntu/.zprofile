# Ubuntu-specific .zprofile configuration

# Set PATH
export PATH="$HOME/.local/bin:$PATH"

# Ruby via rbenv (if installed)
if [ -d "$HOME/.rbenv" ]; then
  export PATH="$HOME/.rbenv/bin:$PATH"
  eval "$(rbenv init -)"
fi

# Node Version Manager (if installed)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Python via pyenv (if installed)
if [ -d "$HOME/.pyenv" ]; then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init --path)"
fi

# Go (if installed)
if [ -d "/usr/local/go" ]; then
  export PATH="/usr/local/go/bin:$PATH"
fi
if [ -d "$HOME/go" ]; then
  export PATH="$HOME/go/bin:$PATH"
fi

# Rust via rustup (if installed)
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# Docker completion (if installed)
if [ -f "/usr/share/bash-completion/completions/docker" ]; then
  source "/usr/share/bash-completion/completions/docker"
fi

# AWS CLI completion (if installed)
if [ -f "/usr/share/bash-completion/completions/aws" ]; then
  source "/usr/share/bash-completion/completions/aws"
fi