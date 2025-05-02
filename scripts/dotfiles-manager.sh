#!/bin/bash
# Improved Dotfiles Manager
# A comprehensive management system for dotfiles
# Version: 1.1.0

set -e  # Exit on error

DOTFILES_DIR="$HOME/dotfiles"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
GITHUB_REPO="https://github.com/joshuamichaelhall/dotfiles.git"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
  echo -e "${2:-$NC}$1${NC}"
}

# Determine OS and architecture
detect_system() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    export SYSTEM_OS="macos"
    if [[ $(uname -m) == 'arm64' ]]; then
      export SYSTEM_ARCH="apple_silicon"
      export HOMEBREW_PREFIX="/opt/homebrew"
    else
      export SYSTEM_ARCH="intel"
      export HOMEBREW_PREFIX="/usr/local"
    fi
    print_message "Detected: macOS on $SYSTEM_ARCH architecture" "$BLUE"
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    export SYSTEM_OS="ubuntu"
    export SYSTEM_ARCH="$(uname -m)"
    print_message "Detected: Ubuntu Linux on $SYSTEM_ARCH architecture" "$BLUE"
  else
    print_message "Unsupported operating system: $OSTYPE" "$RED"
    return 1
  fi
  return 0
}

# Check if the dotfiles repository exists, clone if needed
ensure_repo() {
  if [ ! -d "$DOTFILES_DIR" ] || [ ! -d "$DOTFILES_DIR/.git" ]; then
    print_message "Dotfiles repository not found at $DOTFILES_DIR" "$YELLOW"
    print_message "Would you like to clone it from GitHub? (y/n)" "$YELLOW"
    read -r answer
    
    if [[ $answer =~ ^[Yy]$ ]]; then
      # Backup existing directory if it exists but is not a git repo
      if [ -d "$DOTFILES_DIR" ]; then
        mv "$DOTFILES_DIR" "${DOTFILES_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
        print_message "Moved existing directory to ${DOTFILES_DIR}_backup_$(date +%Y%m%d_%H%M%S)" "$YELLOW"
      fi
      
      # Clone the repository
      git clone "$GITHUB_REPO" "$DOTFILES_DIR"
      
      if [ $? -ne 0 ]; then
        print_message "Failed to clone repository. Please check the URL and your internet connection." "$RED"
        exit 1
      fi
      
      print_message "Successfully cloned repository to $DOTFILES_DIR" "$GREEN"
    else
      print_message "Please set up your dotfiles repository first and run this script again." "$RED"
      exit 1
    fi
  fi
  
  return 0
}

# Function to add a new dotfile to the repository
add_dotfile() {
  local file=$1
  local platform=$2
  
  # Check if file exists
  if [ ! -e "$HOME/$file" ]; then
    print_message "File not found: $HOME/$file" "$RED"
    return 1
  fi
  
  # Determine if it should be OS-specific or shared
  if [ -z "$platform" ]; then
    print_message "Choose where to store this file:" "$YELLOW"
    print_message "1. OS-specific ($SYSTEM_OS)" "$YELLOW"
    print_message "2. Shared (all platforms)" "$YELLOW"
    read -r choice
    
    if [ "$choice" = "1" ]; then
      platform="$SYSTEM_OS"
    elif [ "$choice" = "2" ]; then
      platform="shared"
    else
      print_message "Invalid choice" "$RED"
      return 1
    fi
  fi
  
  # Create directory structure
  local dir_path=$(dirname "$file")
  if [ "$dir_path" != "." ]; then
    mkdir -p "$DOTFILES_DIR/$platform/$dir_path"
  fi
  
  # Copy file to repository
  cp -R "$HOME/$file" "$DOTFILES_DIR/$platform/$file"
  print_message "Added $file to $platform directory" "$GREEN"
  
  # Add to .dotfiles file if not already there
  if ! grep -q "^$platform/$file$" "$DOTFILES_DIR/.dotfiles"; then
    echo "$platform/$file" >> "$DOTFILES_DIR/.dotfiles"
    print_message "Added $platform/$file to .dotfiles file" "$GREEN"
  fi
  
  return 0
}

# Function to update repository from home directory
update_from_home() {
  print_message "Updating repository from home directory..." "$GREEN"
  
  # Read dotfiles from the repository
  if [ ! -f "$DOTFILES_DIR/.dotfiles" ]; then
    print_message "Error: .dotfiles file not found." "$RED"
    return 1
  fi
  
  mkdir -p "$BACKUP_DIR"
  local update_count=0
  
  # Process each file
  while IFS= read -r file; do
    # Skip comments and empty lines
    [[ "$file" =~ ^#.*$ || -z "$file" ]] && continue
    
    # Get source and target paths
    local source_file="$HOME/${file#*/}"  # Remove platform prefix
    local target_file="$DOTFILES_DIR/$file"
    
    # Skip if home file doesn't exist
    if [ ! -e "$source_file" ]; then
      print_message "Home file not found: $source_file (skipping)" "$YELLOW"
      continue
    fi
    
    # Skip if home file is a symlink (avoid circular references)
    if [ -L "$source_file" ]; then
      print_message "Home file is a symlink: $source_file (skipping)" "$YELLOW"
      continue
    fi
    
    # Create directory structure in repository if needed
    mkdir -p "$(dirname "$target_file")"
    
    # Check if file has changed
    if [ -e "$target_file" ] && diff -q "$source_file" "$target_file" >/dev/null 2>&1; then
      print_message "No changes in $file" "$BLUE"
      continue
    fi
    
    # Backup existing file in repository
    if [ -e "$target_file" ]; then
      local repo_backup_path="$BACKUP_DIR/repo/$(basename "$file")"
      mkdir -p "$(dirname "$repo_backup_path")"
      cp -R "$target_file" "$repo_backup_path"
      print_message "Backed up repository file to $repo_backup_path" "$YELLOW"
    fi
    
    # Update the file in the repository
    cp -R "$source_file" "$target_file"
    print_message "Updated $file from home directory" "$GREEN"
    update_count=$((update_count + 1))
  done < "$DOTFILES_DIR/.dotfiles"
  
  if [ $update_count -eq 0 ]; then
    print_message "No files were updated" "$YELLOW"
  else
    print_message "$update_count file(s) were updated" "$GREEN"
  fi
  
  return 0
}

# Fix any broken or nested symlinks in home directory
fix_home_symlinks() {
  print_message "Checking for broken symlinks in home directory..." "$BLUE"
  
  # Read dotfiles from the repository
  if [ ! -f "$DOTFILES_DIR/.dotfiles" ]; then
    print_message "Error: .dotfiles file not found." "$RED"
    return 1
  fi
  
  local fixed_count=0
  
  # Process each file
  while IFS= read -r file; do
    # Skip comments and empty lines
    [[ "$file" =~ ^#.*$ || -z "$file" ]] && continue
    
    # Get target path in home directory
    local rel_path="${file#*/}"
    local home_file="$HOME/$rel_path"
    
    # Skip if file doesn't exist
    if [ ! -e "$home_file" ] && [ ! -L "$home_file" ]; then
      continue
    fi
    
    # Check if it's a broken or nested symlink
    if [ -L "$home_file" ]; then
      local link_target=$(readlink "$home_file")
      
      # If broken symlink or points to another symlink or points to our repo
      if [ ! -e "$link_target" ] || [ -L "$link_target" ] || [[ "$link_target" == *"$DOTFILES_DIR"* ]]; then
        print_message "Found problematic symlink: $home_file -> $link_target" "$YELLOW"
        
        # Get the source file from our repository
        local source_file="$DOTFILES_DIR/$file"
        
        # Check if source file exists in our repo
        if [ -e "$source_file" ]; then
          # Backup the symlink
          mkdir -p "$BACKUP_DIR/symlinks"
          cp -P "$home_file" "$BACKUP_DIR/symlinks/$(basename "$home_file").symlink"
          
          # Remove the symlink
          rm "$home_file"
          
          # Copy the actual file
          cp -R "$source_file" "$home_file"
          print_message "Fixed: $home_file (replaced symlink with file copy)" "$GREEN"
          fixed_count=$((fixed_count + 1))
        else
          print_message "Cannot fix: $home_file (source file not found in repository)" "$RED"
        fi
      fi
    fi
  done < "$DOTFILES_DIR/.dotfiles"
  
  if [ $fixed_count -eq 0 ]; then
    print_message "No problematic symlinks were found" "$GREEN"
  else
    print_message "$fixed_count symlink(s) were fixed" "$GREEN"
  fi
  
  return 0
}

# Function to handle git operations
git_operations() {
  cd "$DOTFILES_DIR" || return 1
  
  # Check if there are any changes
  if ! git status --porcelain | grep -q .; then
    print_message "No changes to commit" "$YELLOW"
    return 0
  fi
  
  # Show changes
  git status
  
  # Ask for commit
  print_message "Do you want to commit these changes? (y/n)" "$YELLOW"
  read -r commit_answer
  
  if [[ ! $commit_answer =~ ^[Yy]$ ]]; then
    return 0
  fi
  
  # Ask for commit message
  print_message "Enter commit message:" "$YELLOW"
  read -r commit_message
  
  # Commit changes
  git add .
  git commit -m "$commit_message"
  
  # Ask for push
  print_message "Do you want to push to GitHub? (y/n)" "$YELLOW"
  read -r push_answer
  
  if [[ $push_answer =~ ^[Yy]$ ]]; then
    git push
    print_message "Changes pushed to GitHub" "$GREEN"
  fi
  
  return 0
}

# Function to check git conflicts
check_git_conflicts() {
  cd "$DOTFILES_DIR" || return 1
  
  if git diff --name-only --diff-filter=U | grep -q .; then
    print_message "Warning: There are unresolved merge conflicts in the repository!" "$RED"
    print_message "Please resolve these conflicts before proceeding:" "$YELLOW"
    git diff --name-only --diff-filter=U
    return 1
  fi
  
  return 0
}

# Main menu function
main_menu() {
  clear
  print_message "\n${BOLD}==== DOTFILES MANAGER ====${NC}" "$GREEN"
  print_message "System: $SYSTEM_OS on $SYSTEM_ARCH" "$BLUE"
  print_message "Repository: $DOTFILES_DIR" "$BLUE"
  echo
  print_message "1. Add new dotfile to repository" "$YELLOW"
  print_message "2. Update repository from home directory" "$YELLOW"
  print_message "3. Install dotfiles to home directory" "$YELLOW"
  print_message "4. Fix problematic symlinks in home directory" "$YELLOW"
  print_message "5. List tracked files" "$YELLOW"
  print_message "6. Git operations (status/commit/push)" "$YELLOW"
  print_message "7. Edit .dotfiles file" "$YELLOW"
  print_message "8. Exit" "$YELLOW"
  print_message "\nEnter choice [1-8]:" "$GREEN"
  
  read -r choice
  
  case $choice in
    1)
      # Add new dotfile
      print_message "Enter path to file (relative to home, e.g. .config/some-app/config):" "$YELLOW"
      read -r file_path
      add_dotfile "$file_path"
      print_message "Press Enter to continue..." "$YELLOW"
      read -r
      main_menu
      ;;
    2)
      # Update from home
      update_from_home
      print_message "Press Enter to continue..." "$YELLOW"
      read -r
      main_menu
      ;;
    3)
      # Install dotfiles
      "$DOTFILES_DIR/install.sh"
      print_message "Press Enter to continue..." "$YELLOW"
      read -r
      main_menu
      ;;
    4)
      # Fix symlinks
      fix_home_symlinks
      print_message "Press Enter to continue..." "$YELLOW"
      read -r
      main_menu
      ;;
    5)
      # List tracked files
      print_message "\nCurrently tracked files:" "$GREEN"
      cat "$DOTFILES_DIR/.dotfiles" | grep -v "^#" | sort
      print_message "\nPress Enter to continue..." "$YELLOW"
      read -r
      main_menu
      ;;
    6)
      # Git operations
      git_operations
      print_message "Press Enter to continue..." "$YELLOW"
      read -r
      main_menu
      ;;
    7)
      # Edit .dotfiles file
      if [ -n "$EDITOR" ]; then
        $EDITOR "$DOTFILES_DIR/.dotfiles"
      elif command -v nvim &> /dev/null; then
        nvim "$DOTFILES_DIR/.dotfiles"
      elif command -v vim &> /dev/null; then
        vim "$DOTFILES_DIR/.dotfiles"
      elif command -v nano &> /dev/null; then
        nano "$DOTFILES_DIR/.dotfiles"
      else
        print_message "No suitable editor found" "$RED"
      fi
      print_message "Press Enter to continue..." "$YELLOW"
      read -r
      main_menu
      ;;
    8)
      # Exit
      print_message "Exiting dotfiles manager. Goodbye!" "$GREEN"
      exit 0
      ;;
    *)
      print_message "Invalid choice. Press Enter to try again..." "$RED"
      read -r
      main_menu
      ;;
  esac
}

# ----------------
# SCRIPT EXECUTION
# ----------------

# Ensure we have a repository
ensure_repo

# Detect system
detect_system

# Check for git conflicts
check_git_conflicts

# Start the main menu
main_menu
