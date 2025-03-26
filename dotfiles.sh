#!/usr/bin/env zsh
# Dotfiles Management Script for Joshua Hall
# Provides explicit backup (save local to GitHub) and restore (get from GitHub) options

# Configuration - using existing repository location
DOTFILES_REPO="$HOME/dotfiles"
GITHUB_REPO="https://github.com/joshuamichaelhall/dotfiles.git"

# Files to include in dotfiles repo (add/remove based on what you want to manage)
DOTFILES=(
  ".zshrc"
  ".zshenv"
  ".zprofile"
  ".tmux.conf"
  ".vimrc"
  ".config/nvim/init.vim"
  ".config/nvim/init.lua"
  ".gitconfig"
  ".gitignore_global"
  ".bashrc"
  ".bash_profile"
)

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
  echo -e "${2:-$NC}$1${NC}"
}

# Check if the dotfiles repository exists
if [ ! -d "$DOTFILES_REPO" ] || [ ! -d "$DOTFILES_REPO/.git" ]; then
  print_message "Dotfiles repository not found at $DOTFILES_REPO or not a git repository" "$RED"
  print_message "Would you like to clone your repository from GitHub? (y/n)" "$YELLOW"
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

# Navigate to the repository
cd "$DOTFILES_REPO" || exit

# Create a .dotfiles file if it doesn't exist
if [ ! -f "$DOTFILES_REPO/.dotfiles" ]; then
  print_message "Creating .dotfiles file with list of files to manage" "$GREEN"
  for file in "${DOTFILES[@]}"; do
    echo "$file" >> "$DOTFILES_REPO/.dotfiles"
  done
else
  print_message ".dotfiles file already exists." "$YELLOW"
fi

# Check if install.sh exists, create if not
if [ ! -f "$DOTFILES_REPO/install.sh" ]; then
  print_message "Creating install.sh script" "$GREEN"
  
  cat > "$DOTFILES_REPO/install.sh" << 'EOF'
#!/usr/bin/env zsh

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

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Function to backup and symlink files
setup_symlink() {
  local source_file="$DOTFILES_DIR/$1"
  local target_file="$HOME/$1"
  
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
    mkdir -p "$(dirname "$BACKUP_DIR/$1")"
    cp -R "$target_file" "$BACKUP_DIR/$1"
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
    setup_symlink "$file"
  done < "$DOTFILES_DIR/.dotfiles"
else
  print_message "Error: .dotfiles file not found. Please create it with a list of dotfiles to symlink." "$RED"
  exit 1
fi

print_message "Dotfiles installation complete!" "$GREEN"
print_message "A backup of your original files was created at: $BACKUP_DIR" "$YELLOW"
EOF

  # Make the install script executable
  chmod +x "$DOTFILES_REPO/install.sh"
fi

# Function to check and copy dotfiles to repository
copy_dotfiles_to_repo() {
  print_message "Checking for new dotfiles to add to repository..." "$GREEN"
  
  for file in "${DOTFILES[@]}"; do
    source_file="$HOME/$file"
    target_dir="$DOTFILES_REPO/$(dirname "$file")"
    target_file="$DOTFILES_REPO/$file"
    
    # Check if the source file/directory exists
    if [ -e "$source_file" ] && [ ! -L "$source_file" ]; then
      # Create target directory if it doesn't exist
      mkdir -p "$target_dir"
      
      # Check if file already exists in repo and compare
      if [ -e "$target_file" ]; then
        if diff -q "$source_file" "$target_file" >/dev/null 2>&1; then
          print_message "File already in repository and up to date: $file" "$YELLOW"
        else
          print_message "File differs from repository version: $file" "$YELLOW"
          print_message "Would you like to update the repository version? (y/n)" "$YELLOW"
          read -r answer
          
          if [[ $answer =~ ^[Yy]$ ]]; then
            # Backup existing file in repo
            cp -R "$target_file" "${target_file}.bak"
            print_message "Backed up existing file to ${target_file}.bak" "$YELLOW"
            
            # Copy new version
            if [ -d "$source_file" ]; then
              cp -R "$source_file" "$target_dir"
            else
              cp "$source_file" "$target_file"
            fi
            print_message "Updated file in repository: $file" "$GREEN"
          fi
        fi
      else
        # File doesn't exist in repo, copy it
        if [ -d "$source_file" ]; then
          cp -R "$source_file" "$target_dir"
          print_message "Copied directory to repository: $file" "$GREEN"
        else
          cp "$source_file" "$target_file"
          print_message "Copied file to repository: $file" "$GREEN"
        fi
      fi
    elif [ -L "$source_file" ]; then
      print_message "Source is already a symlink: $file (skipping)" "$YELLOW"
    else
      print_message "Source file/directory not found: $file (skipping)" "$YELLOW"
    fi
  done
}

# Main menu for backup/restore options
main_menu() {
  clear
  print_message "\n==== DOTFILES MANAGEMENT MENU ====" "$GREEN"
  print_message "1. BACKUP: Save local dotfiles to repository and GitHub" "$YELLOW"
  print_message "2. RESTORE: Get dotfiles from GitHub and apply to local system" "$YELLOW"
  print_message "3. EDIT: Modify which files are tracked" "$YELLOW"
  print_message "4. QUIT: Exit the script" "$YELLOW"
  print_message "\nPlease select an option (1-4):" "$GREEN"
  
  read -r option
  
  case $option in
    1)
      # BACKUP option
      print_message "\n=== BACKING UP LOCAL DOTFILES ===" "$GREEN"
      copy_dotfiles_to_repo
      
      # Ask if user wants to commit and push changes
      print_message "\nWould you like to commit and push changes to GitHub? (y/n)" "$YELLOW"
      read -r commit_answer
      
      if [[ $commit_answer =~ ^[Yy]$ ]]; then
        # Check if there are any changes
        if git -C "$DOTFILES_REPO" status --porcelain | grep -q .; then
          print_message "Changes detected. Please enter a commit message:" "$YELLOW"
          read -r commit_message
          
          git -C "$DOTFILES_REPO" add .
          git -C "$DOTFILES_REPO" commit -m "$commit_message"
          git -C "$DOTFILES_REPO" push origin main || git -C "$DOTFILES_REPO" push origin master
          
          print_message "Changes committed and pushed to repository" "$GREEN"
        else
          print_message "No changes detected in repository" "$YELLOW"
        fi
      fi
      
      print_message "\nBackup completed! Press Enter to continue..." "$GREEN"
      read -r
      main_menu
      ;;
      
    2)
      # RESTORE option
      print_message "\n=== RESTORING DOTFILES FROM GITHUB ===" "$GREEN"
      
      # Ask if user wants to update the repository first
      print_message "Would you like to pull the latest changes from GitHub first? (y/n)" "$YELLOW"
      read -r pull_answer
      
      if [[ $pull_answer =~ ^[Yy]$ ]]; then
        git -C "$DOTFILES_REPO" pull
        print_message "Repository updated from GitHub" "$GREEN"
      fi
      
      # Ask for confirmation before restore
      print_message "\nWARNING: This will replace your current dotfiles with those from the repository." "$RED"
      print_message "Your existing files will be backed up before replacement." "$YELLOW"
      print_message "Do you want to continue with the restore? (y/n)" "$RED"
      read -r restore_confirm
      
      if [[ $restore_confirm =~ ^[Yy]$ ]]; then
        "$DOTFILES_REPO/install.sh"
        print_message "\nRestore completed! Press Enter to continue..." "$GREEN"
      else
        print_message "\nRestore cancelled. Press Enter to continue..." "$YELLOW"
      fi
      read -r
      main_menu
      ;;
      
    3)
      # EDIT option
      print_message "\n=== EDIT TRACKED FILES ===" "$GREEN"
      
      # Create temporary file with current dotfiles
      TMP_FILE=$(mktemp)
      
      # If .dotfiles file exists, copy its contents
      if [ -f "$DOTFILES_REPO/.dotfiles" ]; then
        cp "$DOTFILES_REPO/.dotfiles" "$TMP_FILE"
      else
        # Otherwise, use the default list
        for file in "${DOTFILES[@]}"; do
          echo "$file" >> "$TMP_FILE"
        done
      fi
      
      # Open the file in the user's preferred editor
      if [ -n "$EDITOR" ]; then
        $EDITOR "$TMP_FILE"
      elif command -v vim &> /dev/null; then
        vim "$TMP_FILE"
      elif command -v nano &> /dev/null; then
        nano "$TMP_FILE"
      else
        print_message "No suitable editor found. Please install vim or nano." "$RED"
        rm "$TMP_FILE"
        read -r
        main_menu
        return
      fi
      
      # Save the changes
      cp "$TMP_FILE" "$DOTFILES_REPO/.dotfiles"
      rm "$TMP_FILE"
      
      print_message "Tracked files list updated. Press Enter to continue..." "$GREEN"
      read -r
      main_menu
      ;;
      
    4)
      print_message "\nExiting dotfiles management script. Goodbye!" "$GREEN"
      exit 0
      ;;
      
    *)
      print_message "\nInvalid option. Press Enter to try again..." "$RED"
      read -r
      main_menu
      ;;
  esac
}

# Start the main menu
main_menu
