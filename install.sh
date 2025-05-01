#!/bin/bash
<<<<<<< Updated upstream
# Cross-Platform macOS Dotfiles Installer
# Handles both Apple Silicon and Intel Macs automatically
||||||| Stash base
=======
# Dotfiles installation script

set -e
>>>>>>> Stashed changes

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

# Determine Mac architecture
if [[ "$OSTYPE" == "darwin"* ]]; then
  DOTFILES_OS="macos"
  if [[ $(uname -m) == 'arm64' ]]; then
    print_message "Detected Apple Silicon Mac" "$GREEN"
    MAC_ARCH="apple_silicon"
    HOMEBREW_PATH="/opt/homebrew/bin"
  else
    print_message "Detected Intel Mac" "$GREEN"
    MAC_ARCH="intel"
    HOMEBREW_PATH="/usr/local/bin"
  fi
else
<<<<<<< Updated upstream
  print_message "This script is specifically for macOS. For other platforms, use the standard install.sh" "$RED"
||||||| Stash base
  print_message "Unsupported operating system" "$RED"
=======
  print_message "Unsupported operating system: $OSTYPE" "$RED"
>>>>>>> Stashed changes
  exit 1
fi

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

print_message "Installing dotfiles for $MAC_ARCH Mac..." "$GREEN"

# 1. First, let's create or update the architecture-aware .zprofile
print_message "Creating architecture-aware .zprofile..." "$GREEN"

cat > "$DOTFILES_DIR/macos/.zprofile" << EOF
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

# 2. Install the dotfiles by reading from .dotfiles file
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

<<<<<<< Updated upstream
# 3. Fix the functions.sh parsing error if it exists
if [ -f "$HOME/.local/bin/functions.sh" ]; then
  print_message "Checking functions.sh for parsing errors..." "$GREEN"
  # Make a backup
  cp "$HOME/.local/bin/functions.sh" "$BACKUP_DIR/functions.sh.bak"
  
  # Fix the common parsing issue
  sed -i '' 's/log_info "Verifying installation on $platform platform"/log_info "Verifying installation on \${platform} platform"/' "$HOME/.local/bin/functions.sh" || print_message "Could not fix functions.sh, but continuing anyway" "$YELLOW"
fi

# 4. Ensure essential tools are available
print_message "Verifying essential tools..." "$GREEN"

# Source .zprofile to apply Homebrew paths
source "$HOME/.zprofile"

# Check and install Homebrew if needed
if ! command -v brew >/dev/null; then
  print_message "Homebrew not found, installing..." "$YELLOW"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  
  # Re-source profile to get updated PATH
  source "$HOME/.zprofile"
else
  print_message "Homebrew is installed: $(which brew)" "$GREEN"
fi

# Check and install tmux if needed
if ! command -v tmux >/dev/null; then
  print_message "tmux not found, installing with Homebrew..." "$YELLOW"
  brew install tmux
else
  print_message "tmux is installed: $(which tmux)" "$GREEN"
fi

# 5. Final verification
print_message "\nPerforming final verification..." "$GREEN"

VERIFICATION_FAILED=0

# Check Homebrew
if command -v brew >/dev/null; then
  print_message "✅ Homebrew is properly configured" "$GREEN"
else
  print_message "❌ Homebrew is not available in PATH" "$RED"
  VERIFICATION_FAILED=1
fi

# Check tmux
if command -v tmux >/dev/null; then
  print_message "✅ tmux is properly installed" "$GREEN"
else
  print_message "❌ tmux is not available in PATH" "$RED"
  VERIFICATION_FAILED=1
fi

# Check rbenv (if it should be installed)
if grep -q "rbenv" "$HOME/.zprofile"; then
  if command -v rbenv >/dev/null; then
    print_message "✅ rbenv is properly installed" "$GREEN"
  else
    print_message "❌ rbenv is referenced but not installed" "$YELLOW"
    print_message "   Install with: brew install rbenv" "$YELLOW"
  fi
fi

# Final status
if [ $VERIFICATION_FAILED -eq 1 ]; then
  print_message "\n⚠️ Some verifications failed. Please check the messages above." "$YELLOW"
  print_message "You may need to restart your terminal or run 'source ~/.zprofile'" "$YELLOW"
else
  print_message "\n🎉 Dotfiles installation complete and verified!" "$GREEN"
  print_message "A backup of your original files was created at: $BACKUP_DIR" "$YELLOW"
  print_message "You should restart your terminal session for all changes to take effect." "$GREEN"
fi
||||||| Stash base
print_message "Dotfiles installation complete!" "$GREEN"
print_message "A backup of your original files was created at: $BACKUP_DIR" "$YELLOW"
=======
print_message "Dotfiles installation complete!" "$GREEN"
print_message "A backup of your original files was created at: $BACKUP_DIR" "$YELLOW"
print_message "Please restart your terminal for changes to take effect." "$GREEN"
>>>>>>> Stashed changes
