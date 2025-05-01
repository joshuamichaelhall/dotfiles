#!/bin/bash

DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
  echo -e "${2:-$NC}$1${NC}"
}

# Determine OS
if [[ "$OSTYPE" == "darwin"* ]]; then
  DOTFILES_OS="macos"
  
  # Detect Mac architecture
  if [[ $(uname -m) == 'arm64' ]]; then
    print_message "Detected Apple Silicon Mac" "$GREEN"
  else
    print_message "Detected Intel Mac" "$GREEN"
  fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  DOTFILES_OS="ubuntu"
else
  print_message "Unsupported operating system" "$RED"
  exit 1
fi

print_message "Detected OS: $DOTFILES_OS" "$GREEN"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Function to backup and symlink files
setup_symlink() {
  local file_path=$1
  local source_file="$DOTFILES_DIR/$file_path"
  local target_file="$HOME/$(basename "$file_path")"
  
  # For nested directories like .config/nvim
  if [[ "$file_path" == */* ]]; then
    # Extract the path without the platform prefix
    local rel_path="${file_path#*/}"
    target_file="$HOME/$rel_path"
  fi
  
  # Check if the source file/directory exists in the repo
  if [ ! -e "$source_file" ]; then
    print_message "Source doesn't exist: $source_file (skipping)" "$YELLOW"
    return
  fi
  
  # Create target directory if it doesn't exist
  mkdir -p "$(dirname "$target_file")"
  
  # Backup existing file/directory if it exists and is not a symlink
  if [ -e "$target_file" ] && [ ! -L "$target_file" ]; then
    print_message "Backing up $target_file to $BACKUP_DIR" "$YELLOW"
    mkdir -p "$(dirname "$BACKUP_DIR/$(basename "$file_path")")"
    cp -R "$target_file" "$BACKUP_DIR/$(basename "$file_path")"
  fi
  
  # Remove existing symlink or file
  if [ -e "$target_file" ]; then
    if [ -L "$target_file" ]; then
      print_message "Removing existing symlink: $target_file" "$YELLOW"
    else
      print_message "Removing existing file: $target_file" "$YELLOW"
    fi
    rm -rf "$target_file"
  fi
  
  # Create symlink
  ln -s "$source_file" "$target_file"
  print_message "Linked $source_file to $target_file" "$GREEN"
}

print_message "Installing dotfiles..." "$GREEN"

# Read dotfiles from the repository (stored in .dotfiles file)
if [ -f "$DOTFILES_DIR/.dotfiles" ]; then
  while IFS= read -r file; do
    # Skip comments and empty lines
    [[ "$file" =~ ^#.*$ || -z "$file" ]] && continue
    
    # Check if file belongs to current OS or shared
    if [[ "$file" == "$DOTFILES_OS"/* ]] || [[ "$file" == "shared"/* ]]; then
      setup_symlink "$file"
    fi
  done < "$DOTFILES_DIR/.dotfiles"
else
  print_message "Error: .dotfiles file not found. Please create it with a list of dotfiles to symlink." "$RED"
  exit 1
fi

# Apply immediate environment fixes
if [[ "$DOTFILES_OS" == "macos" ]]; then
  # Source zprofile to make Homebrew and other tools available immediately
  print_message "Sourcing ~/.zprofile to apply Homebrew path..." "$GREEN"
  source "$HOME/.zprofile"
  
  # Verify that key tools are available
  if command -v brew >/dev/null; then
    print_message "Homebrew successfully initialized" "$GREEN"
  else
    print_message "Warning: Homebrew not found in PATH after initialization" "$YELLOW"
    print_message "You may need to restart your terminal session" "$YELLOW"
  fi
  
  if command -v tmux >/dev/null; then
    print_message "tmux is available: $(which tmux)" "$GREEN"
  else
    print_message "Warning: tmux not found in PATH, installing..." "$YELLOW"
    brew install tmux
  fi
fi

print_message "Dotfiles installation complete!" "$GREEN"
print_message "A backup of your original files was created at: $BACKUP_DIR" "$YELLOW"
print_message "You may need to restart your terminal or run 'source ~/.zprofile'" "$YELLOW"