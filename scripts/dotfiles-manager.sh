#!/bin/bash
# Enhanced dotfiles management script

set -e

DOTFILES_DIR="$HOME/dotfiles"
GITHUB_REPO="git@github.com:joshuamichaelhall/dotfiles.git"

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
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  DOTFILES_OS="ubuntu"
else
  print_message "Unsupported operating system: $OSTYPE" "$RED"
  exit 1
fi

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
    print_message "1. OS-specific ($DOTFILES_OS)" "$YELLOW"
    print_message "2. Shared (all platforms)" "$YELLOW"
    read -r choice
    
    if [ "$choice" = "1" ]; then
      platform="$DOTFILES_OS"
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
  
  # Create symlink
  ln -sf "$DOTFILES_DIR/$platform/$file" "$HOME/$file"
  print_message "Created symlink for $file" "$GREEN"
  
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
  
  # Process each file
  while IFS= read -r file; do
    # Skip comments and empty lines
    [[ "$file" =~ ^#.*$ || -z "$file" ]] && continue
    
    # Get source and target paths
    local source_file="$HOME/${file#*/}"  # Remove platform prefix
    local target_file="$DOTFILES_DIR/$file"
    
    # Skip if home file doesn't exist or is a symlink
    if [ ! -e "$source_file" ] || [ -L "$source_file" ]; then
      continue
    fi
    
    # Check if file has changed
    if [ -e "$target_file" ] && diff -q "$source_file" "$target_file" >/dev/null 2>&1; then
      continue
    fi
    
    # Update the file in the repository
    cp -R "$source_file" "$target_file"
    print_message "Updated $file from home directory" "$GREEN"
  done < "$DOTFILES_DIR/.dotfiles"
  
  return 0
}

# Function to handle git operations
git_operations() {
  # Check if there are any changes
  if ! git -C "$DOTFILES_DIR" status --porcelain | grep -q .; then
    print_message "No changes to commit" "$YELLOW"
    return 0
  fi
  
  # Show changes
  git -C "$DOTFILES_DIR" status
  
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
  git -C "$DOTFILES_DIR" add .
  git -C "$DOTFILES_DIR" commit -m "$commit_message"
  
  # Ask for push
  print_message "Do you want to push to GitHub? (y/n)" "$YELLOW"
  read -r push_answer
  
  if [[ $push_answer =~ ^[Yy]$ ]]; then
    git -C "$DOTFILES_DIR" push
    print_message "Changes pushed to GitHub" "$GREEN"
  fi
  
  return 0
}

# Main menu function
main_menu() {
  clear
  print_message "\n==== DOTFILES MANAGEMENT MENU ====" "$GREEN"
  print_message "1. Add new dotfile to repository" "$YELLOW"
  print_message "2. Update repository from home directory" "$YELLOW"
  print_message "3. Install dotfiles to home directory" "$YELLOW"
  print_message "4. List tracked files" "$YELLOW"
  print_message "5. Git operations (status/commit/push)" "$YELLOW"
  print_message "6. Edit .dotfiles file" "$YELLOW"
  print_message "7. Exit" "$YELLOW"
  print_message "\nEnter choice [1-7]:" "$GREEN"
  
  read -r choice
  
  case $choice in
    1)
      # Add new dotfile
      print_message "Enter path to file (relative to home, e.g. .config/some-app/config):" "$YELLOW"
      read -r file_path
      add_dotfile "$file_path"
      print_message "Press Enter to continue..." "$GREEN"
      read -r
      main_menu
      ;;
    2)
      # Update from home
      update_from_home
      print_message "Press Enter to continue..." "$GREEN"
      read -r
      main_menu
      ;;
    3)
      # Install dotfiles
      "$DOTFILES_DIR/install.sh"
      print_message "Press Enter to continue..." "$GREEN"
      read -r
      main_menu
      ;;
    4)
      # List tracked files
      print_message "\nCurrently tracked files:" "$GREEN"
      cat "$DOTFILES_DIR/.dotfiles" | grep -v "^#" | sort
      print_message "\nPress Enter to continue..." "$GREEN"
      read -r
      main_menu
      ;;
    5)
      # Git operations
      git_operations
      print_message "Press Enter to continue..." "$GREEN"
      read -r
      main_menu
      ;;
    6)
      # Edit .dotfiles file
      if [ -n "$EDITOR" ]; then
        $EDITOR "$DOTFILES_DIR/.dotfiles"
      elif command -v vim &> /dev/null; then
        vim "$DOTFILES_DIR/.dotfiles"
      elif command -v nano &> /dev/null; then
        nano "$DOTFILES_DIR/.dotfiles"
      else
        print_message "No suitable editor found" "$RED"
      fi
      print_message "Press Enter to continue..." "$GREEN"
      read -r
      main_menu
      ;;
    7)
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

# Check if we're in the repository
if [ ! -d "$DOTFILES_DIR" ] || [ ! -d "$DOTFILES_DIR/.git" ]; then
  print_message "Dotfiles repository not found or not a git repository" "$RED"
  exit 1
fi

# Start the main menu
main_menu
