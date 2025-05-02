#!/bin/bash
# Improved Dotfiles Manager
# A more robust dotfiles management system that uses direct file copying instead of symlinks
# Version: 1.0.0

set -e  # Exit on error

# Configuration
DOTFILES_REPO="$HOME/dotfiles"
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
  if [ ! -d "$DOTFILES_REPO" ] || [ ! -d "$DOTFILES_REPO/.git" ]; then
    print_message "Dotfiles repository not found at $DOTFILES_REPO" "$YELLOW"
    print_message "Would you like to clone it from GitHub? (y/n)" "$YELLOW"
    read -r answer
    
    if [[ $answer =~ ^[Yy]$ ]]; then
      # Backup existing directory if it exists but is not a git repo
      if [ -d "$DOTFILES_REPO" ]; then
        mv "$DOTFILES_REPO" "${DOTFILES_REPO}_backup_$(date +%Y%m%d_%H%M%S)"
        print_message "Moved existing directory to ${DOTFILES_REPO}_backup_$(date +%Y%m%d_%H%M%S)" "$YELLOW"
      fi
      
      # Clone the repository
      git clone "$GITHUB_REPO" "$DOTFILES_REPO"
      
      if [ $? -ne 0 ]; then
        print_message "Failed to clone repository. Please check the URL and your internet connection." "$RED"
        exit 1
      fi
      
      print_message "Successfully cloned repository to $DOTFILES_REPO" "$GREEN"
    else
      print_message "Please set up your dotfiles repository first and run this script again." "$RED"
      exit 1
    fi
  fi
  
  return 0
}

# Function to verify file integrity
verify_file() {
  local source_file="$1"
  local target_file="$2"
  
  if [[ ! -f "$source_file" ]]; then
    print_message "Source file doesn't exist: $source_file" "$RED"
    return 1
  fi
  
  if [[ -L "$target_file" ]]; then
    print_message "Target is a symlink, removing: $target_file" "$YELLOW"
    rm "$target_file"
  fi
  
  return 0
}

# Function to backup a file before modifying it
backup_file() {
  local file="$1"
  local relative_path="${file#$HOME/}"
  
  if [[ -f "$file" && ! -L "$file" ]]; then
    local backup_path="$BACKUP_DIR/$relative_path"
    local backup_dir=$(dirname "$backup_path")
    
    mkdir -p "$backup_dir"
    cp -f "$file" "$backup_path"
    print_message "Backed up $file to $backup_path" "$BLUE"
    return 0
  elif [[ -L "$file" ]]; then
    print_message "Skipping backup of symlink: $file" "$YELLOW"
    return 0
  elif [[ ! -f "$file" ]]; then
    print_message "No existing file to backup: $file" "$YELLOW"
    return 0
  fi
  
  return 1
}

# Function to install a dotfile
install_file() {
  local source_file="$1"
  local target_file="$2"
  
  # Verify files
  verify_file "$source_file" "$target_file" || return 1
  
  # Backup existing file
  backup_file "$target_file"
  
  # Create target directory if it doesn't exist
  mkdir -p "$(dirname "$target_file")"
  
  # Copy the file instead of symlinking
  cp -f "$source_file" "$target_file"
  print_message "Installed: $source_file -> $target_file" "$GREEN"
  
  return 0
}

# Process dotfiles based on OS
process_dotfiles() {
  local action="$1"  # install or sync
  
  # Ensure .dotfiles file exists
  if [ ! -f "$DOTFILES_REPO/.dotfiles" ]; then
    print_message "Error: .dotfiles file not found. Cannot determine which files to manage." "$RED"
    return 1
  fi
  
  print_message "Processing dotfiles for $SYSTEM_OS..." "$BLUE"
  mkdir -p "$BACKUP_DIR"
  
  # Process each file in .dotfiles
  while IFS= read -r line; do
    # Skip comments and empty lines
    [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
    
    # Check if the line is for the current OS or shared
    if [[ "$line" == "$SYSTEM_OS"/* ]] || [[ "$line" == "shared"/* ]]; then
      # Get source and target paths
      local source_file="$DOTFILES_REPO/$line"
      # Extract the path without the platform prefix for the target file
      local rel_path="${line#*/}"
      local target_file="$HOME/$rel_path"
      
      if [[ "$action" == "install" ]]; then
        # Installing from repo to home
        if [[ -f "$source_file" ]]; then
          install_file "$source_file" "$target_file"
        elif [[ -f "${source_file}~Updated upstream" ]]; then
          # Try the backup copy if the main file is missing
          install_file "${source_file}~Updated upstream" "$target_file"
        else
          print_message "Source file not found: $source_file" "$RED"
        fi
      elif [[ "$action" == "sync" ]]; then
        # Syncing from home to repo
        if [[ -f "$target_file" && ! -L "$target_file" ]]; then
          # Create directory structure in repo if needed
          mkdir -p "$(dirname "$source_file")"
          # Copy from home to repo
          cp -f "$target_file" "$source_file"
          print_message "Synced: $target_file -> $source_file" "$GREEN"
        else
          print_message "Home file not found or is a symlink: $target_file" "$YELLOW"
        fi
      fi
    fi
  done < "$DOTFILES_REPO/.dotfiles"
  
  return 0
}

# Generate or update architecture-aware configuration files
update_arch_aware_configs() {
  print_message "Updating architecture-aware configuration files..." "$BLUE"
  
  # Update .zprofile for macOS with architecture detection
  if [[ "$SYSTEM_OS" == "macos" ]]; then
    local zprofile_path="$DOTFILES_REPO/macos/.zprofile"
    
    # Create or update .zprofile
    cat > "$zprofile_path" << EOF
# Auto-detect Mac architecture and use appropriate Homebrew path
if [[ \$(uname -m) == 'arm64' ]]; then
  # Apple Silicon path
  [[ -f /opt/homebrew/bin/brew ]] && eval "\$(/opt/homebrew/bin/brew shellenv)"
else
  # Intel path
  [[ -f /usr/local/bin/brew ]] && eval "\$(/usr/local/bin/brew shellenv)"
fi

# Ensure common brew paths are in PATH regardless of architecture
export PATH="/opt/homebrew/bin:/usr/local/bin:\$PATH"

# Added by \`rbenv init\`
command -v rbenv >/dev/null && eval "\$(rbenv init - --no-rehash zsh)"
EOF
    
    print_message "Updated architecture-aware .zprofile" "$GREEN"
  fi
  
  return 0
}

# Fix any broken symlinks in the repository
fix_repo_symlinks() {
  print_message "Fixing repository symlinks..." "$BLUE"
  
  # Read dotfiles file
  while IFS= read -r line; do
    # Skip comments and empty lines
    [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
    
    local source_file="$DOTFILES_REPO/$line"
    
    # Check if it's a broken symlink
    if [[ -L "$source_file" && ! -e "$source_file" ]]; then
      print_message "Found broken symlink: $source_file" "$YELLOW"
      
      # Check if there's a backup file
      if [[ -f "${source_file}~Updated upstream" ]]; then
        # Remove the symlink
        rm "$source_file"
        
        # Copy the backup file
        cp "${source_file}~Updated upstream" "$source_file"
        print_message "Fixed: ${source_file} (using backup)" "$GREEN"
      else
        print_message "No backup file found for ${source_file}" "$RED"
      fi
    fi
  done < "$DOTFILES_REPO/.dotfiles"
  
  return 0
}

# Handle git operations (status, commit, push)
git_operations() {
  cd "$DOTFILES_REPO" || return 1
  
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

# Main menu function
main_menu() {
  clear
  print_message "\n${BOLD}==== IMPROVED DOTFILES MANAGER ====${NC}" "$GREEN"
  print_message "System: $SYSTEM_OS on $SYSTEM_ARCH" "$BLUE"
  print_message "Repository: $DOTFILES_REPO" "$BLUE"
  echo
  print_message "1. Install dotfiles (repo → home)" "$YELLOW"
  print_message "2. Sync dotfiles (home → repo)" "$YELLOW"
  print_message "3. Fix broken repository files" "$YELLOW"
  print_message "4. Git operations (status/commit/push)" "$YELLOW"
  print_message "5. Edit .dotfiles file" "$YELLOW"
  print_message "6. Exit" "$YELLOW"
  print_message "\nEnter choice [1-6]:" "$GREEN"
  
  read -r choice
  
  case $choice in
    1)
      # Install dotfiles from repository to home
      detect_system
      update_arch_aware_configs
      process_dotfiles "install"
      print_message "\nDotfiles installation complete!" "$GREEN"
      print_message "A backup of your original files was created at: $BACKUP_DIR" "$BLUE"
      print_message "Press Enter to continue..." "$YELLOW"
      read -r
      main_menu
      ;;
    2)
      # Sync dotfiles from home to repository
      detect_system
      process_dotfiles "sync"
      print_message "\nDotfiles synced to repository!" "$GREEN"
      print_message "Press Enter to continue..." "$YELLOW"
      read -r
      main_menu
      ;;
    3)
      # Fix broken repository files
      fix_repo_symlinks
      print_message "\nRepository files fixed!" "$GREEN"
      print_message "Press Enter to continue..." "$YELLOW"
      read -r
      main_menu
      ;;
    4)
      # Git operations
      git_operations
      print_message "Press Enter to continue..." "$YELLOW"
      read -r
      main_menu
      ;;
    5)
      # Edit .dotfiles file
      if [ -n "$EDITOR" ]; then
        $EDITOR "$DOTFILES_REPO/.dotfiles"
      elif command -v vim &> /dev/null; then
        vim "$DOTFILES_REPO/.dotfiles"
      elif command -v nano &> /dev/null; then
        nano "$DOTFILES_REPO/.dotfiles"
      else
        print_message "No suitable editor found" "$RED"
      fi
      print_message "Press Enter to continue..." "$YELLOW"
      read -r
      main_menu
      ;;
    6)
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

# Check if we're in the repository or need to ensure it exists
if [[ "$0" == "$DOTFILES_REPO"/* ]]; then
  # Script is being run from within the repository
  cd "$DOTFILES_REPO" || exit 1
else
  # Ensure repository exists
  ensure_repo
fi

# Detect system
detect_system

# Start the main menu
main_menu
