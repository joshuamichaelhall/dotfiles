#!/bin/bash
# Homebrew installation and package setup for macOS
# Detects architecture (Apple Silicon vs Intel) and installs appropriate packages

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
  echo -e "${2:-$NC}$1${NC}"
}

# Detect architecture
if [[ $(uname -m) == 'arm64' ]]; then
  ARCH="apple_silicon"
  print_message "Detected: macOS on Apple Silicon" "$BLUE"
  BREW_PREFIX="/opt/homebrew"
else
  ARCH="intel"
  print_message "Detected: macOS on Intel" "$BLUE"
  BREW_PREFIX="/usr/local"
fi

# Install Homebrew if not installed
if ! command -v brew >/dev/null; then
  print_message "Installing Homebrew..." "$YELLOW"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  
  # Add Homebrew to PATH based on architecture
  if [[ "$ARCH" == "apple_silicon" ]]; then
    print_message "Adding Homebrew to PATH for Apple Silicon..." "$YELLOW"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> $HOME/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
else
  print_message "Homebrew is already installed" "$GREEN"
fi

# Update Homebrew
print_message "Updating Homebrew..." "$YELLOW"
brew update

# Install command line tools
print_message "Installing command line tools..." "$YELLOW"
brew install \
  bat \
  coreutils \
  curl \
  fd \
  fzf \
  git \
  htop \
  jq \
  neovim \
  ripgrep \
  tmux \
  tree \
  wget \
  zsh \
  zsh-autosuggestions \
  zsh-syntax-highlighting

# Install development tools
print_message "Installing development tools..." "$YELLOW"
brew install \
  node \
  python \
  ruby \
  go

# Install AWS CLI
print_message "Installing AWS CLI..." "$YELLOW"
brew install awscli

# Install Terraform
print_message "Installing Terraform..." "$YELLOW"
brew install terraform

# Install Docker CLI (but not Docker Desktop)
print_message "Installing Docker CLI..." "$YELLOW"
brew install docker docker-compose

# Install cask applications
print_message "Installing applications..." "$YELLOW"
brew install --cask \
  visual-studio-code \
  iterm2 \
  rectangle \
  alfred

# Cleanup
print_message "Cleaning up..." "$YELLOW"
brew cleanup

print_message "\nHomebrew setup complete!" "$GREEN"
print_message "You may want to install Docker Desktop manually if needed" "$BLUE"