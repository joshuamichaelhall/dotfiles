#!/bin/bash
# ~/dotfiles/enhance.sh - Comprehensive dotfiles enhancement script

set -e
echo "==== Dotfiles Repository Enhancement ===="

DOTFILES_DIR="$HOME/dotfiles"
cd "$DOTFILES_DIR"

# Create platform and shared directories if they don't exist
mkdir -p macos ubuntu shared scripts

# Define color codes for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
  echo -e "${2:-$NC}$1${NC}"
}

# Function to backup and move files to the appropriate directories
process_file() {
  local file=$1
  local platform=$2
  local source_location=$3  # "repo" or "home"
  
  if [ "$source_location" = "repo" ]; then
    # Source is in the repo
    if [ ! -e "$DOTFILES_DIR/$file" ]; then
      print_message "File not found in repo: $file (skipping)" "$YELLOW"
      return
    fi
    
    # Create directory structure in destination
    local dir_path=$(dirname "$file")
    if [ "$dir_path" != "." ]; then
      mkdir -p "$DOTFILES_DIR/$platform/$dir_path"
    fi
    
    # Move the file using git
    git mv "$DOTFILES_DIR/$file" "$DOTFILES_DIR/$platform/$file" 2>/dev/null || \
    cp -R "$DOTFILES_DIR/$file" "$DOTFILES_DIR/$platform/$file"
    print_message "Moved $file to $platform directory" "$GREEN"
    
  elif [ "$source_location" = "home" ]; then
    # Source is in the home directory
    if [ ! -e "$HOME/$file" ]; then
      print_message "File not found in home: $file (skipping)" "$YELLOW"
      return
    fi
    
    # Create directory structure in destination
    local dir_path=$(dirname "$file")
    if [ "$dir_path" != "." ]; then
      mkdir -p "$DOTFILES_DIR/$platform/$dir_path"
    fi
    
    # Copy the file from home to repo
    cp -R "$HOME/$file" "$DOTFILES_DIR/$platform/$file"
    print_message "Copied $file from home to $platform directory" "$GREEN"
  fi
}

# Define dotfiles to track
MACOS_FILES=(
  ".zshrc"
  ".zprofile"
  ".zshenv"
  ".bash_profile"
  ".p10k.zsh"
)

UBUNTU_FILES=(
  # Empty for now, will be populated as you add Ubuntu-specific files
)

SHARED_FILES=(
  ".gitconfig"
  ".gitignore_global"
  ".tmux.conf"
  ".bashrc"
  ".vimrc"
)

CONFIG_FILES=(
  ".config/nvim/init.lua"
)

# Create a function to check if the file exists in repo or home
find_file_location() {
  local file=$1
  
  if [ -e "$DOTFILES_DIR/$file" ]; then
    echo "repo"
  elif [ -e "$HOME/$file" ]; then
    echo "home"
  else
    echo "none"
  fi
}

# Process all files
print_message "Organizing files into platform-specific directories..." "$GREEN"

# Process macOS files
for file in "${MACOS_FILES[@]}"; do
  location=$(find_file_location "$file")
  if [ "$location" != "none" ]; then
    process_file "$file" "macos" "$location"
  fi
done

# Process Ubuntu files
for file in "${UBUNTU_FILES[@]}"; do
  location=$(find_file_location "$file")
  if [ "$location" != "none" ]; then
    process_file "$file" "ubuntu" "$location"
  fi
done

# Process shared files
for file in "${SHARED_FILES[@]}"; do
  location=$(find_file_location "$file")
  if [ "$location" != "none" ]; then
    process_file "$file" "shared" "$location"
  fi
done

# Handle .config directory specially
for file in "${CONFIG_FILES[@]}"; do
  # Check if file exists in home
  if [ -e "$HOME/$file" ]; then
    # Create directory structure
    mkdir -p "$DOTFILES_DIR/shared/$(dirname "$file")"
    
    # Copy file from home to repo
    cp -R "$HOME/$file" "$DOTFILES_DIR/shared/$file"
    print_message "Copied $file from home to shared directory" "$GREEN"
  # Check if file exists in repo root/.config
  elif [ -e "$DOTFILES_DIR/.config/$(basename "$file")" ]; then
    # Create directory structure
    mkdir -p "$DOTFILES_DIR/shared/$(dirname "$file")"
    
    # Move file
    mv "$DOTFILES_DIR/.config/$(basename "$file")" "$DOTFILES_DIR/shared/$file"
    print_message "Moved .config/$(basename "$file") to shared/$file" "$GREEN"
  fi
done

# Clean up empty .config directory if it exists
if [ -d "$DOTFILES_DIR/.config" ] && [ -z "$(ls -A "$DOTFILES_DIR/.config")" ]; then
  rmdir "$DOTFILES_DIR/.config"
  print_message "Removed empty .config directory" "$YELLOW"
fi

# Update .dotfiles file to use the new structure
print_message "Updating .dotfiles file with new paths..." "$GREEN"
cat > "$DOTFILES_DIR/.dotfiles" << 'EOF'
# macOS specific files
macos/.zshrc
macos/.zprofile
macos/.zshenv
macos/.bash_profile
macos/.p10k.zsh

# Ubuntu specific files
# Add your Ubuntu-specific files here

# Shared files
shared/.gitconfig
shared/.gitignore_global
shared/.tmux.conf
shared/.bashrc
shared/.vimrc
shared/.config/nvim/init.lua
EOF

# Create updated install.sh
print_message "Creating improved install.sh script..." "$GREEN"

cat > "$DOTFILES_DIR/install.sh" << 'EOF'
#!/bin/bash
# Dotfiles installation script

set -e

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
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  DOTFILES_OS="ubuntu"
else
  print_message "Unsupported operating system: $OSTYPE" "$RED"
  exit 1
fi

print_message "Detected OS: $DOTFILES_OS" "$GREEN"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Function to backup and symlink files
setup_symlink() {
  local file_path=$1
  local source_file="$DOTFILES_DIR/$file_path"
  
  # Extract the path without the platform prefix (macos/ or ubuntu/ or shared/)
  local rel_path="${file_path#*/}"
  local target_file="$HOME/$rel_path"
  
  # Check if the source file/directory exists in the repo
  if [ ! -e "$source_file" ]; then
    print_message "Source doesn't exist: $source_file (skipping)" "$YELLOW"
    return
  fi
  
  # Create target directory if it doesn't exist
  mkdir -p "$(dirname "$target_file")"
  
  # Backup existing file/directory if it exists and is not a symlink
  if [ -e "$target_file" ] && [ ! -L "$target_file" ]; then
    print_message "Backing up $target_file to $BACKUP_DIR/$rel_path" "$YELLOW"
    mkdir -p "$(dirname "$BACKUP_DIR/$rel_path")"
    cp -R "$target_file" "$BACKUP_DIR/$rel_path"
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

print_message "Dotfiles installation complete!" "$GREEN"
print_message "A backup of your original files was created at: $BACKUP_DIR" "$YELLOW"
print_message "Please restart your terminal for changes to take effect." "$GREEN"
EOF

chmod +x "$DOTFILES_DIR/install.sh"

# Create an improved management script
print_message "Creating improved management script..." "$GREEN"

cat > "$DOTFILES_DIR/scripts/dotfiles-manager.sh" << 'EOF'
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
EOF

chmod +x "$DOTFILES_DIR/scripts/dotfiles-manager.sh"

# Create a symlink to the manager script
ln -sf "$DOTFILES_DIR/scripts/dotfiles-manager.sh" "$DOTFILES_DIR/manage"
chmod +x "$DOTFILES_DIR/manage"

# Update README.md with new information
print_message "Updating README.md with new information..." "$GREEN"

cat > "$DOTFILES_DIR/README.md" << 'EOF'
# Dotfiles

A comprehensive dotfiles management system for maintaining consistent development environments across multiple machines (macOS and Ubuntu).

## What's Inside

- Terminal configuration (Zsh, Bash)
- Neovim setup
- tmux configuration
- Git configuration
- OS-specific settings

## Quick Start

### Initial Setup on a New Machine

```bash
# Clone the repository
git clone https://github.com/joshuamichaelhall/dotfiles.git ~/dotfiles

# Navigate to the repository
cd ~/dotfiles

# Run the installation script
./install.sh
