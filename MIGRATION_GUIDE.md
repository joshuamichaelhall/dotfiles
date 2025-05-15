# Dotfiles Migration Guide

This guide provides instructions for migrating from different setups to this dotfiles repository, including how to preserve your personal configurations while adopting these dotfiles.

## Table of Contents

- [Why Migrate?](#why-migrate)
- [Preparation](#preparation)
- [Migrating from Other Dotfiles](#migrating-from-other-dotfiles)
- [Migrating from macOS to Ubuntu](#migrating-from-macos-to-ubuntu)
- [Migrating from Ubuntu to macOS](#migrating-from-ubuntu-to-macos)
- [Preserving Personal Customizations](#preserving-personal-customizations)
- [Post-Migration Steps](#post-migration-steps)
- [Restoring from Backup](#restoring-from-backup)

## Why Migrate?

This dotfiles repository offers several advantages:

1. **Cross-platform compatibility** - Works seamlessly across macOS (Apple Silicon & Intel) and Ubuntu
2. **Comprehensive tooling** - Configured for development with AWS, Docker, Terraform, and more
3. **Backup and restore** - Easy environment backup and restoration
4. **Modular design** - Pick and choose which components to adopt
5. **Consistent experience** - Same workflow across different machines and environments

## Preparation

### 1. Backup Your Existing Configuration

Before making any changes, back up your existing configuration:

```bash
# Create a backup directory
mkdir -p ~/.dotfiles_backup/original
cd ~

# Backup common dotfiles
cp -r .zshrc .bashrc .bash_profile .profile .gitconfig .vimrc .tmux.conf \
   .aws .docker .terraform* \
   ~/.dotfiles_backup/original/
```

### 2. Review Your Current Setup

Make a note of your custom configurations, especially:

- Shell (Bash/Zsh) aliases and functions
- Git user configuration and aliases
- Editor preferences
- Package lists
- Secret tokens and credentials

### 3. Clone the New Dotfiles Repository

```bash
git clone https://github.com/joshuamichaelhall/dotfiles.git ~/dotfiles-new
cd ~/dotfiles-new
```

## Migrating from Other Dotfiles

### From Bash to Zsh

If you're primarily a Bash user migrating to Zsh:

1. Identify your important Bash configurations:
   ```bash
   grep -n "alias\|function\|export\|PATH" ~/.bashrc ~/.bash_profile
   ```

2. Add these to a custom file for preservation:
   ```bash
   # Create a custom file
   mkdir -p ~/dotfiles-new/shared/custom
   touch ~/dotfiles-new/shared/custom/user-customizations.sh
   
   # Add your specific configurations
   echo "# Custom user configurations migrated from Bash" > ~/dotfiles-new/shared/custom/user-customizations.sh
   # Add your exports, aliases, etc.
   ```

3. Reference this file in the installation:
   Add the following line to `shared/.zshrc` before installation:
   ```bash
   # Source custom user configurations
   [[ -f $HOME/dotfiles/shared/custom/user-customizations.sh ]] && source $HOME/dotfiles/shared/custom/user-customizations.sh
   ```

### From Other Dotfiles Managers

If you're using another dotfiles manager (like chezmoi, GNU stow, or rcm):

1. Identify key configurations to preserve:
   ```bash
   # List files managed by your current dotfiles system
   # (Command varies based on your current system)
   ```

2. Extract unique configurations:
   ```bash
   # Copy custom configurations to a backup location
   mkdir -p ~/dotfiles-migration-temp
   # Copy your customizations
   ```

3. Integrate configurations:
   Review each file and integrate your custom settings into the corresponding files in this new dotfiles repository.

## Migrating from macOS to Ubuntu

If you're moving from macOS to Ubuntu:

1. Export your Homebrew packages list:
   ```bash
   brew list --formula > ~/brew-formulas.txt
   brew list --cask > ~/brew-casks.txt
   ```

2. Install equivalent Ubuntu packages:
   ```bash
   # Edit the Ubuntu package installation script
   vim ~/dotfiles-new/ubuntu/bin/apt-install.sh
   
   # Add your required packages to the apt install command
   ```

3. Update tool paths:
   ```bash
   # Review paths in your shell configuration
   grep -n "PATH" ~/.zshrc ~/.bash_profile
   
   # Update paths in the new dotfiles if needed
   vim ~/dotfiles-new/ubuntu/.zprofile
   ```

## Migrating from Ubuntu to macOS

If you're moving from Ubuntu to macOS:

1. Export your APT packages list:
   ```bash
   dpkg --get-selections > ~/ubuntu-packages.txt
   ```

2. Install equivalent macOS packages:
   ```bash
   # Edit the macOS Homebrew installation script
   vim ~/dotfiles-new/macos/bin/brew-install.sh
   
   # Add your required packages to the brew install commands
   ```

3. Update tool paths:
   ```bash
   # Review paths in your shell configuration
   grep -n "PATH" ~/.bashrc ~/.zshrc
   
   # Update paths in the new dotfiles if needed
   vim ~/dotfiles-new/macos/.zprofile
   ```

## Preserving Personal Customizations

### Git Configuration

To preserve your Git identity:

1. Extract your Git user information:
   ```bash
   git config --get user.name
   git config --get user.email
   git config --get-regexp "^alias\."
   ```

2. Create a local Git config:
   ```bash
   cat > ~/.gitconfig.local << EOL
   [user]
       name = Your Name
       email = your.email@example.com
   
   # Add your custom Git aliases here
   [alias]
       # Your aliases
   EOL
   ```

3. The main `.gitconfig` already includes local config:
   ```
   # This is already in the dotfiles .gitconfig
   [include]
       path = ~/.gitconfig.local
   ```

### Shell Customizations

For shell-specific customizations:

1. Create personal shell files:
   ```bash
   # For Zsh
   touch ~/.zshrc.local
   
   # For Bash
   touch ~/.bashrc.local
   ```

2. Add your customizations to these files

3. The main shell configs already source these locals:
   ```
   # This is already in the shell dotfiles
   [ -f ~/.zshrc.local ] && source ~/.zshrc.local
   ```

### AWS, Docker, and Terraform Customizations

1. Extract your configurations:
   ```bash
   # AWS
   cp ~/.aws/config ~/.aws/config.backup
   cp ~/.aws/credentials ~/.aws/credentials.backup
   
   # Docker
   cp ~/.docker/config.json ~/.docker/config.json.backup
   
   # Terraform
   cp ~/.terraformrc ~/.terraformrc.backup
   ```

2. After installation, merge your specific settings from backups.

## Post-Migration Steps

### 1. Install the Dotfiles

Once you've prepared your customizations:

```bash
cd ~/dotfiles-new
./install.sh
```

### 2. Install Additional Tools

```bash
# On macOS
./macos/bin/brew-install.sh

# On Ubuntu
sudo ./ubuntu/bin/apt-install.sh
```

### 3. Restore Personal Configurations

```bash
# Restore credentials and personal configurations
cp ~/.aws/credentials.backup ~/.aws/credentials
# Similar for other sensitive configurations
```

### 4. Verify Your Setup

Test key functionality to ensure everything is working:

```bash
# Test shell functionality
source ~/.zshrc

# Test Git
git status

# Test AWS CLI (if configured)
aws sts get-caller-identity

# Test Docker (if installed)
docker info

# Test Terraform (if installed)
terraform version
```

## Restoring from Backup

If you encounter issues with the new dotfiles, you can revert to your backup:

```bash
# Revert to original configuration
cd ~/.dotfiles_backup/original
cp -r . ~/

# Restart your shell
exec $SHELL -l
```

---

Remember that migration is a gradual process. You can adopt parts of these dotfiles incrementally rather than switching everything at once. The modular nature of this repository makes it easy to pick and choose the components you want to use.

For additional help or to report issues, please open an issue on the GitHub repository: https://github.com/joshuamichaelhall/dotfiles/issues