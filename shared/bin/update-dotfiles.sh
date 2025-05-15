#!/bin/bash
# Update dotfiles repository and reinstall configurations
# Pulls latest changes and reinstalls dotfiles

set -e

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

# Get the path to the dotfiles directory
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

print_message "Updating dotfiles repository..." "$BLUE"

# Check if it's a git repository
if [ -d "$DOTFILES_DIR/.git" ]; then
  # Navigate to dotfiles directory
  cd "$DOTFILES_DIR"
  
  # Backup any local changes first
  if [[ -n $(git status --porcelain) ]]; then
    print_message "Local changes detected. Creating backup branch..." "$YELLOW"
    BACKUP_BRANCH="backup/$(date +%Y%m%d_%H%M%S)"
    git checkout -b "$BACKUP_BRANCH"
    git add -A
    git commit -m "Automatic backup before update"
    print_message "Changes saved to branch: $BACKUP_BRANCH" "$GREEN"
    git checkout main
  fi
  
  # Pull latest changes
  print_message "Pulling latest changes..." "$YELLOW"
  git pull origin main
  if [ $? -ne 0 ]; then
    print_message "Failed to pull latest changes. Please resolve conflicts manually." "$RED"
    exit 1
  fi
else
  print_message "Not a git repository. Skipping update." "$YELLOW"
fi

# Run the installation script
print_message "Running installation script..." "$BLUE"
"$DOTFILES_DIR/install.sh"

print_message "Dotfiles successfully updated and installed!" "$GREEN"