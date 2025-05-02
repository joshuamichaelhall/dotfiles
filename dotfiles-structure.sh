#!/bin/bash
# Dotfiles Structure Repair Script
# Fixes symlink issues and converts symlinks to actual files
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

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Function to fix a repository file if it's a symlink
fix_repo_file() {
  local file_path="$1"
  local full_path="$DOTFILES_DIR/$file_path"
  
  # Skip if file doesn't exist
  if [ ! -e "$full_path" ] && [ ! -L "$full_path" ]; then
    print_message "File doesn't exist: $full_path (skipping)" "$YELLOW"
    return 0
  fi
  
  # Check if it's a symlink
  if [ -L "$full_path" ]; then
    print_message "Found symlink: $full_path" "$BLUE"
    
    # Check if backup file exists
    local backup_file="${full_path}~Updated upstream"
    if [ -f "$backup_file" ]; then
      # Backup the symlink itself (just in case)
      cp -P "$full_path" "$BACKUP_DIR/$(basename "$full_path").symlink"
      
      # Remove the symlink
      rm "$full_path"
      
      # Copy the backup file to the original location
      cp "$backup_file" "$full_path"
      print_message "Fixed: $full_path (using backup)" "$GREEN"
    else
      # Try to resolve the symlink
      local real_file=$(readlink -f "$full_path")
      if [ -f "$real_file" ]; then
        # Backup the symlink itself
        cp -P "$full_path" "$BACKUP_DIR/$(basename "$full_path").symlink"
        
        # Remove the symlink
        rm "$full_path"
        
        # Copy the real file
        cp "$real_file" "$full_path"
        print_message "Fixed: $full_path (using resolved target)" "$GREEN"
      else
        print_message "Cannot fix symlink: $full_path (no backup, unresolvable target)" "$RED"
      fi
    fi
  else
    print_message "Not a symlink: $full_path (skipping)" "$YELLOW"
  fi
  
  return 0
}

# Function to fix a home dotfile if it's a broken symlink
fix_home_file() {
  local rel_path="$1"
  local full_path="$HOME/$rel_path"
  
  # Skip if file doesn't exist
  if [ ! -e "$full_path" ] && [ ! -L "$full_path" ]; then
    print_message "File doesn't exist: $full_path (skipping)" "$YELLOW"
    return 0
  fi
  
  # Check if it's a symlink
  if [ -L "$full_path" ]; then
    print_message "Found symlink: $full_path" "$BLUE"
    
    # Check if it's broken
    if [ ! -e "$full_path" ]; then
      print_message "Broken symlink detected: $full_path" "$RED"
      
      # Remove the broken symlink
      rm "$full_path"
      print_message "Removed broken symlink: $full_path" "$YELLOW"
    else
      print_message "Working symlink: $full_path (skipping)" "$YELLOW"
    fi
  else
    print_message "Not a symlink: $full_path (skipping)" "$YELLOW"
  fi
  
  return 0
}

# Process .dotfiles file and fix entries
process_dotfiles_file() {
  # Check for .dotfiles file
  if [ -f "$DOTFILES_DIR/.dotfiles" ]; then
    print_message "Processing repository files..." "$BLUE"
    
    while IFS= read -r file; do
      # Skip comments and empty lines
      [[ "$file" =~ ^#.*$ || -z "$file" ]] && continue
      
      # Fix the file in the repository
      fix_repo_file "$file"
      
      # Also fix the corresponding home file
      rel_path="${file#*/}"  # Remove the platform prefix
      fix_home_file "$rel_path"
      
    done < "$DOTFILES_DIR/.dotfiles"
  else
    print_message "Error: .dotfiles file not found!" "$RED"
    exit 1
  fi
}

# Main repair process
print_message "Repairing dotfiles repository structure..." "$GREEN"

# Process files from .dotfiles
process_dotfiles_file

# Fix common problematic files even if they're not in .dotfiles
print_message "Checking for common problematic files..." "$BLUE"

common_files=(
  "shared/.gitconfig"
  "shared/.tmux.conf"
  "shared/.bashrc"
  "shared/.vimrc"
  "shared/.config/nvim/init.lua"
  "macos/.zshrc"
  "macos/.zprofile"
  "macos/.bash_profile"
)

for file in "${common_files[@]}"; do
  fix_repo_file "$file"
  rel_path="${file#*/}"  # Remove the platform prefix
  fix_home_file "$rel_path"
done

print_message "Repair process complete!" "$GREEN"
print_message "A backup of the original symlinks was created at: $BACKUP_DIR" "$YELLOW"
print_message "Now run the install script to properly set up your dotfiles." "$BLUE"
