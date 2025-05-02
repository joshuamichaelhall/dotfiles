#!/bin/bash
# Dotfiles Installation Script
# Uses direct file copying for maximum reliability
# Version: 1.1.0

set -e  # Exit on error

DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

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

# Determine OS and architecture
if [[ "$OSTYPE" == "darwin"* ]]; then
  DOTFILES_OS="macos"
  if [[ $(uname -m) == 'arm64' ]]; then
    MAC_ARCH="apple_silicon"
    print_message "Detected: macOS on Apple Silicon" "$BLUE"
  else
    MAC_ARCH="intel"
    print_message "Detected: macOS on Intel" "$BLUE"
  fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  DOTFILES_OS="ubuntu"
  print_message "Detected: Ubuntu Linux" "$BLUE"
else
  print_message "Unsupported operating system: $OSTYPE" "$RED"
  exit 1
fi

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Function to install a dotfile using direct copy
install_file() {
  local source_file="$1"
  local target_file="$2"
  
  # Check if the source file exists
  if [ ! -e "$source_file" ]; then
    print_message "Source file doesn't exist: $source_file (skipping)" "$YELLOW"
    return 1
  fi
  
  # Create target directory if it doesn't exist
  mkdir -p "$(dirname "$target_file")"
  
  # Backup existing file if it exists (skip symlinks)
  if [ -e "$target_file" ] && [ ! -L "$target_file" ]; then
    # Create backup path
    local relative_path="${target_file#$HOME/}"
    local backup_path="$BACKUP_DIR/$relative_path"
    mkdir -p "$(dirname "$backup_path")"
    
    # Backup the file
    cp -R "$target_file" "$backup_path"
    print_message "Backed up $target_file to $backup_path" "$YELLOW"
  fi
  
  # Remove existing file or symlink
  if [ -e "$target_file" ] || [ -L "$target_file" ]; then
    rm -rf "$target_file"
  fi
  
  # Copy file
  cp -R "$source_file" "$target_file"
  print_message "Installed $source_file to $target_file" "$GREEN"
  
  return 0
}

# Process each file from .dotfiles
process_dotfiles() {
  # Read dotfiles from the .dotfiles file
  if [ -f "$DOTFILES_DIR/.dotfiles" ]; then
    while IFS= read -r file; do
      # Skip comments and empty lines
      [[ "$file" =~ ^#.*$ || -z "$file" ]] && continue
      
      # Check if file belongs to current OS or shared
      if [[ "$file" == "$DOTFILES_OS"/* ]] || [[ "$file" == "shared"/* ]]; then
        # Get source file
        source_file="$DOTFILES_DIR/$file"
        
        # Extract the path without the platform prefix for the target file
        rel_path="${file#*/}"
        target_file="$HOME/$rel_path"
        
        # Install the file
        install_file "$source_file" "$target_file"
      fi
    done < "$DOTFILES_DIR/.dotfiles"
  else
    print_message "Error: .dotfiles file not found. Please create it with a list of dotfiles to install." "$RED"
    exit 1
  fi
}

# Special case: Generate architecture-aware .zprofile for macOS
if [[ "$DOTFILES_OS" == "macos" ]]; then
  print_message "Generating architecture-aware .zprofile..." "$BLUE"
  
  # Create a dynamic .zprofile
  cat > "$DOTFILES_DIR/macos/.zprofile" << 'EOF'
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
EOF
fi

# Main installation process
print_message "Installing dotfiles for $DOTFILES_OS..." "$GREEN"

# Process all dotfiles
process_dotfiles

# Verify essential tools (macOS only)
if [[ "$DOTFILES_OS" == "macos" ]]; then
  print_message "\nVerifying essential tools..." "$BLUE"
  
  # Source the new .zprofile to get updated paths
  if [ -f "$HOME/.zprofile" ]; then
    source "$HOME/.zprofile"
  fi
  
  # Check Homebrew
  if command -v brew >/dev/null; then
    print_message "✅ Homebrew is properly configured" "$GREEN"
  else
    print_message "❌ Homebrew may not be properly configured. You might want to install it." "$YELLOW"
    print_message "   Visit https://brew.sh for installation instructions." "$YELLOW"
  fi
  
  # Check for tmux
  if command -v tmux >/dev/null; then
    print_message "✅ tmux is installed" "$GREEN"
  else
    print_message "❌ tmux is not installed. You might want to install it with 'brew install tmux'" "$YELLOW"
  fi
fi

print_message "\nDotfiles installation complete!" "$GREEN"
print_message "A backup of your original files was created at: $BACKUP_DIR" "$YELLOW"
print_message "Please restart your terminal for changes to take effect." "$BLUE"
