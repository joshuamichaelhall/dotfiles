# Auto-detect Mac architecture and use appropriate Homebrew path
if [[ $(uname -m) == 'arm64' ]]; then
  # Apple Silicon path
  [[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
else
  # Intel path
  [[ -f /usr/local/bin/brew ]] && eval "$(/usr/local/bin/brew shellenv)"
fi

# Ensure common brew paths are in PATH regardless of architecture
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# Added by `rbenv init`
command -v rbenv >/dev/null && eval "$(rbenv init - --no-rehash zsh)"