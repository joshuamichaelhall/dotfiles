#!/bin/bash
# Dotfiles Symlink Repair Script
# Fixes symlink issues and converts symlinks to actual files
# Version: 1.0.0

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

# Determine OS
if [[ "$OSTYPE" == "darwin"* ]]; then
  DOTFILES_OS="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  DOTFILES_OS="ubuntu"
else
  print_message "Unsupported operating system: $OSTYPE" "$RED"
  exit 1
fi

print_message "Detected OS: $DOTFILES_OS" "$BLUE"

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
      
      # Get the expected source file from our repository
      local file_prefix
      if [[ -f "$DOTFILES_DIR/$DOTFILES_OS/$rel_path" ]]; then
        file_prefix="$DOTFILES_OS"
      elif [[ -f "$DOTFILES_DIR/shared/$rel_path" ]]; then
        file_prefix="shared"
      else
        print_message "Cannot find source file for $rel_path in repository" "$RED"
        return 1
      fi
      
      local source_file="$DOTFILES_DIR/$file_prefix/$rel_path"
      
      # Check if source file exists
      if [ -f "$source_file" ]; then
        # Backup the symlink
        mkdir -p "$BACKUP_DIR/symlinks"
        cp -P "$full_path" "$BACKUP_DIR/symlinks/$(basename "$full_path").symlink"
        
        # Remove the broken symlink
        rm "$full_path"
        
        # Create parent directory if needed
        mkdir -p "$(dirname "$full_path")"
        
        # Copy file from repository
        cp "$source_file" "$full_path"
        print_message "Fixed: $full_path (replaced with file from repository)" "$GREEN"
      else
        print_message "Cannot fix: $full_path (source file not found)" "$RED"
      fi
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

# Fix any conflicts in git
fix_git_conflicts() {
  print_message "Checking for git conflicts..." "$BLUE"
  
  # Check if there are any merge conflicts
  if git -C "$DOTFILES_DIR" diff --name-only --diff-filter=U | grep -q .; then
    print_message "Found merge conflicts in these files:" "$RED"
    git -C "$DOTFILES_DIR" diff --name-only --diff-filter=U
    
    print_message "Would you like to resolve these conflicts? (y/n)" "$YELLOW"
    read -r answer
    
    if [[ $answer =~ ^[Yy]$ ]]; then
      print_message "Opening conflict resolution in your editor..." "$BLUE"
      git -C "$DOTFILES_DIR" mergetool
    else
      print_message "Please resolve conflicts manually before continuing" "$YELLOW"
    fi
  else
    print_message "No git conflicts found" "$GREEN"
  fi
}

# Main repair process
print_message "Repairing dotfiles repository structure..." "$GREEN"

# Fix git conflicts if any
fix_git_conflicts

# Fix any merge conflicts in README.md
if [ -f "$DOTFILES_DIR/README.md" ] && grep -q "<<<<<<< Updated upstream" "$DOTFILES_DIR/README.md"; then
  print_message "Merge conflict detected in README.md" "$RED"
  print_message "Backing up conflicted README.md" "$YELLOW"
  cp "$DOTFILES_DIR/README.md" "$BACKUP_DIR/README.md.conflicted"
  
  print_message "Resolving conflict in README.md" "$BLUE"
  # Choose the updated upstream version
  sed -i -e '/<<<<<<< Updated upstream/,/=======/!d' -e 's/<<<<<<< Updated upstream//' "$DOTFILES_DIR/README.md"
  sed -i -e '/=======/,/>>>>>>> Stashed changes/d' "$DOTFILES_DIR/README.md"
  print_message "Conflict in README.md resolved" "$GREEN"
fi

# Process files from .dotfiles
process_dotfiles_file

# Check common problematic files even if they're not in .dotfiles
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
print_message "Now run the install script to properly set up your dotfiles:" "$BLUE"
print_message "./install.sh" "$BOLD"
