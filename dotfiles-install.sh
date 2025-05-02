#!/bin/bash
# Simplified Direct Install Script for Dotfiles
# Uses direct file copying instead of symlinks for maximum compatibility
# Version: 1.0.1 - Fixed local variable bug

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
        # Get source file - try regular file first, then fallback to backup if needed
        source_file="$DOTFILES_DIR/$file"
        backup_file="${source_file}~Updated upstream"
        
        # Extract the path without the platform prefix for the target file
        rel_path="${file#*/}"
        target_file="$HOME/$rel_path"
        
        if [ -f "$source_file" ] && [ ! -L "$source_file" ]; then
          # Use the regular file if it exists and is not a symlink
          install_file "$source_file" "$target_file"
        elif [ -f "$backup_file" ]; then
          # Use the backup file if main file doesn't exist or is a symlink
          print_message "Using backup file for $file" "$YELLOW"
          install_file "$backup_file" "$target_file"
        elif [ -L "$source_file" ] && [ -f "$source_file" ]; then
          # If it's a working symlink, resolve it and copy the actual file
          real_file=$(readlink -f "$source_file")
          if [ -f "$real_file" ]; then
            install_file "$real_file" "$target_file"
          else
            print_message "Cannot resolve symlink: $source_file" "$RED"
          fi
        else
          print_message "No file found for $file" "$RED"
        fi
      fi
    done < "$DOTFILES_DIR/.dotfiles"
  else
    print_message "Error: .dotfiles file not found. Please create it with a list of dotfiles to install." "$RED"
    exit 1
  fi
}

# Main installation process
print_message "Installing dotfiles for $DOTFILES_OS..." "$GREEN"

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

# Process all dotfiles
process_dotfiles

print_message "Dotfiles installation complete!" "$GREEN"
print_message "A backup of your original files was created at: $BACKUP_DIR" "$YELLOW"
print_message "Please restart your terminal for changes to take effect." "$BLUE"
