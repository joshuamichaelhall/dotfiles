#!/bin/bash
# ~/dotfiles/update.sh - Script to update dotfiles repository organization

set -e
echo "==== Dotfiles Repository Update ===="

DOTFILES_DIR="$HOME/dotfiles"
cd "$DOTFILES_DIR"

# Create platform and shared directories if they don't exist
mkdir -p macos ubuntu shared

# Define color codes for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
  echo -e "${2:-$NC}$1${NC}"
}

# Function to move files to the appropriate directories
move_to_platform_dir() {
  local file=$1
  local platform=$2
  
  # Skip if file doesn't exist in repo root
  if [ ! -f "$DOTFILES_DIR/$file" ]; then
    return
  fi
  
  # Create directory structure in destination
  local dir_path=$(dirname "$file")
  if [ "$dir_path" != "." ]; then
    mkdir -p "$DOTFILES_DIR/$platform/$dir_path"
  fi
  
  # Move the file
  git mv "$DOTFILES_DIR/$file" "$DOTFILES_DIR/$platform/$file"
  print_message "Moved $file to $platform directory" "$GREEN"
}

# Files that should go to platform-specific directories
MACOS_FILES=(
  ".zshrc"
  ".zprofile"
  ".bash_profile"
)

UBUNTU_FILES=(
  # Empty for now, will be populated as you add Ubuntu-specific files
)

SHARED_FILES=(
  ".gitconfig"
  ".tmux.conf"
  ".bashrc"
)

# Move files to their respective directories
print_message "Reorganizing files into platform-specific directories..." "$GREEN"

# Move macOS files
for file in "${MACOS_FILES[@]}"; do
  move_to_platform_dir "$file" "macos"
done

# Move Ubuntu files
for file in "${UBUNTU_FILES[@]}"; do
  move_to_platform_dir "$file" "ubuntu"
done

# Move shared files
for file in "${SHARED_FILES[@]}"; do
  move_to_platform_dir "$file" "shared"
done

# Handle .config directory specially
if [ -d "$DOTFILES_DIR/.config" ]; then
  mkdir -p "$DOTFILES_DIR/shared/.config"
  cp -R "$DOTFILES_DIR/.config/"* "$DOTFILES_DIR/shared/.config/"
  rm -rf "$DOTFILES_DIR/.config"
  print_message "Moved .config directory contents to shared/.config" "$GREEN"
fi

# Update .dotfiles file to use the new structure
print_message "Updating .dotfiles file with new paths..." "$GREEN"
cat > "$DOTFILES_DIR/.dotfiles" << 'EOF'
# macOS specific files
macos/.zshrc
macos/.zprofile
macos/.bash_profile

# Ubuntu specific files
# Add your Ubuntu-specific files here

# Shared files
shared/.gitconfig
shared/.tmux.conf
shared/.bashrc
shared/.config/nvim/init.lua
EOF

# Update the symlink script to work with the new directory structure
print_message "Updating install.sh to handle the new directory structure..." "$GREEN"

cat > "$DOTFILES_DIR/install.sh" << 'EOF'
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

print_message "Dotfiles installation complete!" "$GREEN"
print_message "A backup of your original files was created at: $BACKUP_DIR" "$YELLOW"
EOF

chmod +x "$DOTFILES_DIR/install.sh"

# Update README.md with the new structure information
print_message "Updating README.md with new structure information..." "$GREEN"

# We'll only update the Structure section, keeping the rest of your README intact
sed -i.bak '/## Structure/,/##/{
  /## Structure/,/##/{
    /## Structure/{
      p
      c\
## Structure\
\
- `macos/`: macOS-specific configuration files\
- `ubuntu/`: Ubuntu-specific configuration files\
- `shared/`: Configuration files shared between systems\
- `scripts/`: Setup and utility scripts\
\
File symlinks are created based on your OS type (macOS or Ubuntu), automatically\
selecting the appropriate dotfiles.
    }
    /##/p
  }
  d
}' "$DOTFILES_DIR/README.md"

# Update dotfiles.sh to work with the new structure
print_message "Updating dotfiles.sh to handle the new directory structure..." "$GREEN"

# Add scripts directory if it doesn't exist
mkdir -p "$DOTFILES_DIR/scripts"

# Update the main dotfiles.sh script (this is a simplified update focused on the core changes)
sed -i.bak 's/copy_dotfiles_to_repo() {/copy_dotfiles_to_repo() {\n  # Determine OS\n  if [[ "$OSTYPE" == "darwin"* ]]; then\n    DOTFILES_OS="macos"\n  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then\n    DOTFILES_OS="ubuntu"\n  else\n    print_message "Unsupported operating system" "$RED"\n    return\n  fi\n\n  print_message "Detected OS: $DOTFILES_OS" "$GREEN"/' "$DOTFILES_DIR/dotfiles.sh"

# Modify the target directory logic in copy_dotfiles_to_repo
sed -i.bak 's/target_dir="$DOTFILES_REPO\/$(dirname "$file")"/# Determine if file should go to OS-specific or shared directory\n    if [[ " ${SHARED_FILES[@]} " =~ " $file " ]]; then\n      target_dir="$DOTFILES_REPO\/shared\/$(dirname "$file")"\n      target_file="$DOTFILES_REPO\/shared\/$file"\n    else\n      target_dir="$DOTFILES_REPO\/$DOTFILES_OS\/$(dirname "$file")"\n      target_file="$DOTFILES_REPO\/$DOTFILES_OS\/$file"\n    fi/' "$DOTFILES_DIR/dotfiles.sh"

# Clean up backups
rm "$DOTFILES_DIR/README.md.bak"
rm "$DOTFILES_DIR/dotfiles.sh.bak"

# Commit changes
git add .
git commit -m "Reorganize dotfiles into platform-specific directories"

print_message "==== Update Complete ====" "$GREEN"
print_message "Your dotfiles repository has been updated with the following changes:" "$GREEN"
print_message "1. Files are now organized into macos/, ubuntu/, and shared/ directories" "$GREEN"
print_message "2. Installation scripts have been updated to use the new structure" "$GREEN"
print_message "3. README has been updated with the new information" "$GREEN"
print_message "\nNext steps:" "$YELLOW"
print_message "1. Review the changes: git diff HEAD~1" "$YELLOW"
print_message "2. Push changes to GitHub: git push" "$YELLOW"
print_message "3. Run the updated install script to create symlinks: ./install.sh" "$YELLOW"
