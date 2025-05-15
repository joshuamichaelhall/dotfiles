#!/bin/bash
# Environment backup script
# Creates a comprehensive backup of your development environment

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

# Create backup directory with timestamp
BACKUP_DIR="$HOME/.env_backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
print_message "Creating backup at $BACKUP_DIR" "$BLUE"

# Backup shell configurations
print_message "Backing up shell configurations..." "$YELLOW"
SHELL_BACKUP_DIR="$BACKUP_DIR/shell"
mkdir -p "$SHELL_BACKUP_DIR"

# Backup zsh files
if [ -f "$HOME/.zshrc" ]; then
  cp "$HOME/.zshrc" "$SHELL_BACKUP_DIR/"
fi
if [ -f "$HOME/.zprofile" ]; then
  cp "$HOME/.zprofile" "$SHELL_BACKUP_DIR/"
fi
if [ -f "$HOME/.zsh_history" ]; then
  cp "$HOME/.zsh_history" "$SHELL_BACKUP_DIR/"
fi

# Backup bash files
if [ -f "$HOME/.bashrc" ]; then
  cp "$HOME/.bashrc" "$SHELL_BACKUP_DIR/"
fi
if [ -f "$HOME/.bash_profile" ]; then
  cp "$HOME/.bash_profile" "$SHELL_BACKUP_DIR/"
fi
if [ -f "$HOME/.bash_history" ]; then
  cp "$HOME/.bash_history" "$SHELL_BACKUP_DIR/"
fi

# Backup common files
if [ -f "$HOME/.aliases" ]; then
  cp "$HOME/.aliases" "$SHELL_BACKUP_DIR/"
fi
if [ -f "$HOME/.functions" ]; then
  cp "$HOME/.functions" "$SHELL_BACKUP_DIR/"
fi

# Backup Git configurations
print_message "Backing up Git configurations..." "$YELLOW"
GIT_BACKUP_DIR="$BACKUP_DIR/git"
mkdir -p "$GIT_BACKUP_DIR"
if [ -f "$HOME/.gitconfig" ]; then
  cp "$HOME/.gitconfig" "$GIT_BACKUP_DIR/"
fi
if [ -f "$HOME/.gitignore_global" ]; then
  cp "$HOME/.gitignore_global" "$GIT_BACKUP_DIR/"
fi

# Backup SSH configurations
print_message "Backing up SSH configurations..." "$YELLOW"
SSH_BACKUP_DIR="$BACKUP_DIR/ssh"
mkdir -p "$SSH_BACKUP_DIR"
if [ -d "$HOME/.ssh" ]; then
  # Only backup config files, not keys
  if [ -f "$HOME/.ssh/config" ]; then
    cp "$HOME/.ssh/config" "$SSH_BACKUP_DIR/"
  fi
  if [ -f "$HOME/.ssh/known_hosts" ]; then
    cp "$HOME/.ssh/known_hosts" "$SSH_BACKUP_DIR/"
  fi
fi

# Backup Vim configurations
print_message "Backing up Vim configurations..." "$YELLOW"
VIM_BACKUP_DIR="$BACKUP_DIR/vim"
mkdir -p "$VIM_BACKUP_DIR"
if [ -f "$HOME/.vimrc" ]; then
  cp "$HOME/.vimrc" "$VIM_BACKUP_DIR/"
fi

# Backup Tmux configurations
print_message "Backing up Tmux configurations..." "$YELLOW"
TMUX_BACKUP_DIR="$BACKUP_DIR/tmux"
mkdir -p "$TMUX_BACKUP_DIR"
if [ -f "$HOME/.tmux.conf" ]; then
  cp "$HOME/.tmux.conf" "$TMUX_BACKUP_DIR/"
fi

# Backup AWS configurations (without credentials)
print_message "Backing up AWS configurations..." "$YELLOW"
AWS_BACKUP_DIR="$BACKUP_DIR/aws"
mkdir -p "$AWS_BACKUP_DIR"
if [ -f "$HOME/.aws/config" ]; then
  cp "$HOME/.aws/config" "$AWS_BACKUP_DIR/"
fi

# Backup Terraform configurations
print_message "Backing up Terraform configurations..." "$YELLOW"
TERRAFORM_BACKUP_DIR="$BACKUP_DIR/terraform"
mkdir -p "$TERRAFORM_BACKUP_DIR"
if [ -f "$HOME/.terraformrc" ]; then
  cp "$HOME/.terraformrc" "$TERRAFORM_BACKUP_DIR/"
fi

# Backup Docker configurations
print_message "Backing up Docker configurations..." "$YELLOW"
DOCKER_BACKUP_DIR="$BACKUP_DIR/docker"
mkdir -p "$DOCKER_BACKUP_DIR"
if [ -f "$HOME/.docker/config.json" ]; then
  # Remove any auth tokens before backup
  jq 'del(.auths)' "$HOME/.docker/config.json" > "$DOCKER_BACKUP_DIR/config.json" 2>/dev/null || cp "$HOME/.docker/config.json" "$DOCKER_BACKUP_DIR/config.json"
fi
if [ -f "$HOME/.dockerignore" ]; then
  cp "$HOME/.dockerignore" "$DOCKER_BACKUP_DIR/"
fi

# macOS specific backups
if [[ "$OSTYPE" == "darwin"* ]]; then
  print_message "Backing up macOS specific configurations..." "$YELLOW"
  MACOS_BACKUP_DIR="$BACKUP_DIR/macos"
  mkdir -p "$MACOS_BACKUP_DIR"
  
  # Backup Homebrew packages
  if command -v brew &>/dev/null; then
    brew list --formula > "$MACOS_BACKUP_DIR/brew-formulas.txt"
    brew list --cask > "$MACOS_BACKUP_DIR/brew-casks.txt"
  fi
  
  # Backup macOS defaults
  defaults read > "$MACOS_BACKUP_DIR/defaults.txt" 2>/dev/null || true
fi

# Ubuntu specific backups
if [[ "$OSTYPE" == "linux-gnu"* ]] && [ -f "/etc/lsb-release" ] && grep -q "Ubuntu" /etc/lsb-release; then
  print_message "Backing up Ubuntu specific configurations..." "$YELLOW"
  UBUNTU_BACKUP_DIR="$BACKUP_DIR/ubuntu"
  mkdir -p "$UBUNTU_BACKUP_DIR"
  
  # Backup installed packages
  dpkg --get-selections > "$UBUNTU_BACKUP_DIR/packages.txt"
  
  # Backup sources
  if [ -d "/etc/apt/sources.list.d" ]; then
    mkdir -p "$UBUNTU_BACKUP_DIR/sources.list.d"
    sudo cp /etc/apt/sources.list "$UBUNTU_BACKUP_DIR/" 2>/dev/null || true
    sudo cp /etc/apt/sources.list.d/* "$UBUNTU_BACKUP_DIR/sources.list.d/" 2>/dev/null || true
  fi
fi

# Create a tar archive of the backup
TAR_FILE="$HOME/.env_backups/backup_$(date +%Y%m%d_%H%M%S).tar.gz"
tar -czf "$TAR_FILE" -C "$(dirname "$BACKUP_DIR")" "$(basename "$BACKUP_DIR")"
print_message "Created compressed backup at $TAR_FILE" "$GREEN"

# Cleanup uncompressed backup
rm -rf "$BACKUP_DIR"

print_message "Backup completed successfully!" "$GREEN"
print_message "Backup file: $TAR_FILE" "$BLUE"