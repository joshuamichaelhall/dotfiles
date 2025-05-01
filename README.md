<<<<<<< Updated upstream
# Dotfiles Management System
||||||| Stash base
## Dotfiles Management System
=======
# Dotfiles
>>>>>>> Stashed changes

A comprehensive dotfiles management system for maintaining consistent development environments across multiple machines (macOS and Ubuntu).

## What's Inside

<<<<<<< Updated upstream
This repository contains configuration files for:
- zsh and bash shell environments
- Neovim editor
- tmux terminal multiplexer
||||||| Stash base
This repository contains configuration files for:
- zsh shell environment
- Neovim editor
- tmux terminal multiplexer
=======
- Terminal configuration (Zsh, Bash)
- Neovim setup
- tmux configuration
>>>>>>> Stashed changes
- Git configuration
<<<<<<< Updated upstream
- Other shell utilities and configs

The system uses symbolic links to connect files in this repository to their expected locations in your home directory. Files are organized by platform (macOS/Ubuntu) with shared configurations to maintain consistency across different machines.
||||||| Stash base
- Other shell utilities and configs

The system uses symbolic links to connect files in this repository to their expected locations in your home directory.
=======
- OS-specific settings
>>>>>>> Stashed changes

## Quick Start

### Initial Setup on a New Machine

```bash
# Clone the repository
git clone https://github.com/joshuamichaelhall/dotfiles.git ~/dotfiles

# Navigate to the repository
cd ~/dotfiles

# Run the installation script (automatically detects your OS)
./install.sh
<<<<<<< Updated upstream
```

### Using the Management Script

For more advanced management, use the `dotfiles.sh` script:

```bash
# Make the script executable (first time only)
chmod +x ~/dotfiles/dotfiles.sh

# Run the management script
~/dotfiles/dotfiles.sh
```

## Cross-Platform Compatibility

This dotfiles repository is designed to work seamlessly across different platforms:

### Mac Architecture Support

The dotfiles automatically detect and adapt to different Mac architectures:

- **Apple Silicon Macs**: Uses Homebrew at `/opt/homebrew/bin/brew`
- **Intel Macs**: Uses Homebrew at `/usr/local/bin/brew`

The `.zprofile` file automatically detects your Mac's architecture and configures the appropriate paths, ensuring that all tools and utilities work correctly regardless of which Mac you're using.

### Key Features

- **Auto-detection**: No manual configuration needed when switching between Intel and Apple Silicon Macs
- **Unified Configuration**: Maintain a single set of dotfiles that works across all your systems
- **Fallback Mechanisms**: Includes PATH entries for both architectures to ensure tools are found
- **Improved Installation**: The install script verifies that key tools like Homebrew and tmux are properly initialized

### Troubleshooting

If you experience issues after installation:

1. **Path Issues**: Try opening a new terminal session or run: `source ~/.zprofile`
2. **Missing Tools**: Run the installation script again with `./install.sh`
3. **Verify Installation**: Run `verify_installation` to check your environment

### Manual Fix for Common Issues

If you encounter issues with Homebrew or tmux not being found:

```bash
# For Apple Silicon Macs
export PATH="/opt/homebrew/bin:$PATH"

# For Intel Macs
export PATH="/usr/local/bin:$PATH"

# Verify Homebrew is working
which brew

# Install missing tools if needed
brew install tmux
```

## Repository Structure

```
~/dotfiles/
├── .dotfiles              # List of managed dotfiles
├── install.sh             # Installation script
├── update.sh              # Repository structure update script
├── dotfiles.sh            # Management script
├── macos/                 # macOS-specific configuration
│   ├── .zshrc
│   ├── .zprofile
│   └── .bash_profile
├── ubuntu/                # Ubuntu-specific configuration
│   └── ...                # Ubuntu config files (to be added)
└── shared/                # Configuration files shared across platforms
    ├── .gitconfig
    ├── .tmux.conf
    ├── .bashrc
    └── .config/
        └── nvim/
            └── init.lua   # Neovim configuration
```

## Features

### Backup (Save Local to GitHub)

The backup operation:
1. Copies your local dotfiles to the repository
2. Organizes them into the appropriate platform directory (macOS/Ubuntu/shared)
3. Optionally commits and pushes changes to GitHub
4. Creates backups of any files being replaced

This is useful when:
- You've made changes to your local configuration
- You've added new dotfiles you want to track
- You want to synchronize changes across multiple machines

### Restore (Get from GitHub and Apply Locally)

The restore operation:
1. Optionally pulls the latest changes from GitHub
2. Creates backups of your existing local files
3. Creates symbolic links from your home directory to files in the repository
4. Automatically selects the appropriate platform-specific files based on your OS

This is useful when:
- Setting up a new machine
- Recovering after a system change
- Ensuring all machines have the same configuration

## File Management

Files managed by this system are listed in the `.dotfiles` file, which organizes them by platform:

```
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
```

To add or remove files from management, use the "EDIT" option in the `dotfiles.sh` script or manually edit the `.dotfiles` file.

## Configuration Overview

### Shell Environment
- **ZSH**: Configured with Oh My Zsh, Powerlevel10k theme, and plugins for development
- **Bash**: Basic configuration with rbenv initialization and PostgreSQL path

### Neovim
- Modern configuration using Lua
- Lazy.nvim for plugin management
- Sensible defaults for editing
- Key mappings for improved workflow
- Space as leader key

### tmux
- Prefix remapped from `Ctrl+b` to `Ctrl+a`
- Mouse mode enabled
- Vim-like copy mode
- Custom status bar
- Plugin manager with useful plugins installed

### Git
- User identity configuration
- Editor preferences

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

5. **Manage Platform Differences**: Put platform-specific configurations in the appropriate directory (macos/ or ubuntu/) and shared configurations in the shared/ directory.

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
3. Check that files are in the correct platform-specific directories

## Customization

The dotfiles management system is built to be extensible. Feel free to:
- Add additional files to manage by editing the `.dotfiles` file
- Modify the scripts to suit your workflow
- Create branch-based configurations for different environments

## Disclaimer

This project is a work in progress. Use at your own risk. The author is not responsible for any issues that may arise from using these configurations or scripts. Please report any issues through GitHub.

---

## Acknowledgements

This project was developed with assistance from Anthropic's Claude AI assistant, which helped with:
- Documentation writing and organization
- Code structure suggestions
- Troubleshooting and debugging assistance

Claude was used as a development aid while all final implementation decisions and code review were performed by Joshua Michael Hall.

---

Created by: Joshua Michael Hall  
GitHub: [@joshuamichaelhall](https://github.com/joshuamichaelhall)  
Website: [joshuamichaelhall.com](https://joshuamichaelhall.com)
||||||| Stash base
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
=======
>>>>>>> Stashed changes
