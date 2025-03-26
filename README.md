## Dotfiles Management System

A version-controlled dotfiles management system for maintaining consistent development environments across multiple machines.

## Overview

This repository contains configuration files for:
- zsh shell environment
- Neovim editor
- tmux terminal multiplexer
- Git configuration
- Other shell utilities and configs

The system uses symbolic links to connect files in this repository to their expected locations in your home directory.

## Quick Start

### Initial Setup on a New Machine

```bash
# Clone the repository
git clone https://github.com/joshuamichaelhall/dotfiles.git ~/dotfiles

# Navigate to the repository
cd ~/dotfiles

# Run the installation script
./install.sh
```

### Using the Management Script

For more advanced management, use the `dotfiles.sh` script:

```bash
# Make the script executable (first time only)
chmod +x ~/dotfiles/dotfiles.sh

# Run the management script
~/dotfiles/dotfiles.sh
```

## Features

### Backup (Save Local to GitHub)

The backup operation:
1. Copies your local dotfiles to the repository
2. Optionally commits and pushes changes to GitHub
3. Creates backups of any files being replaced

This is useful when:
- You've made changes to your local configuration
- You've added new dotfiles you want to track
- You want to synchronize changes across multiple machines

### Restore (Get from GitHub and Apply Locally)

The restore operation:
1. Optionally pulls the latest changes from GitHub
2. Creates backups of your existing local files
3. Creates symbolic links from your home directory to files in the repository

This is useful when:
- Setting up a new machine
- Recovering after a system change
- Ensuring all machines have the same configuration

## File Management

Files managed by this system are listed in the `.dotfiles` file.

Current managed files include:
- `.zshrc`
- `.zshenv`
- `.zprofile`
- `.tmux.conf`
- `.vimrc`
- `.config/nvim/init.vim`
- `.config/nvim/init.lua`
- `.gitconfig`
- `.gitignore_global`
- `.bashrc`
- `.bash_profile`

To add or remove files from management, edit the `.dotfiles` file.

## Best Practices

1. **Regular Backups**: After making significant changes to your configuration, run a backup to save those changes to your repository.

2. **Descriptive Commit Messages**: Use detailed commit messages to track changes over time.

3. **Keep Secrets Separate**: Never store API keys, tokens, or passwords in your dotfiles repository. Use environment variables or separate secure storage.

4. **System-Specific Configuration**: For machine-specific settings, use conditional logic in your configurations:

   ```bash
   # In .zshrc for example:
   if [[ "$(hostname)" == "work-laptop" ]]; then
     # Work-specific settings
   elif [[ "$(hostname)" == "home-desktop" ]]; then
     # Home-specific settings
   fi
   ```

5. **Repository Structure**: Consider organizing complex configurations into subdirectories:
   ```
   ~/dotfiles/
   ├── zsh/
   ├── vim/
   ├── tmux/
   ├── git/
   └── ...
   ```

## Maintenance and Troubleshooting

### Manual Repairs

If something breaks, you can manually restore from backups:
- Check the `~/.dotfiles_backup/` directory for timestamped backups
- Use `ln -s` to manually create symbolic links if needed

### Updating

To update the management script itself:
1. Pull the latest version from GitHub
2. Review changes before running it

### Debugging

If you encounter issues:
1. Check that symbolic links are correctly established:
   ```bash
   ls -la ~ | grep -e "->.*dotfiles"
   ```
2. Verify the dotfiles repository is up to date:
   ```bash
   cd ~/dotfiles && git status
   ```

## Customization

The dotfiles management system is built to be extensible. Feel free to:
- Add additional files to manage
- Modify the scripts to suit your workflow
- Create branch-based configurations for different environments

---

Created by: Joshua Michael Hall  
GitHub: [@joshuamichaelhall](https://github.com/joshuamichaelhall)  
Website: [joshuamichaelhall.com](https://joshuamichaelhall.com) dotfiles
