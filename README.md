# Dotfiles

A comprehensive dotfiles management system for maintaining consistent development environments across multiple machines (macOS and Ubuntu).

## What's Inside

- Terminal configuration (Zsh, Bash)
- Neovim setup
- tmux configuration
- Git configuration
- AWS, Docker, and Terraform setup
- Development tools and utilities
- Backup and restoration scripts
- OS-specific settings (macOS and Ubuntu)
- Cross-platform compatibility (Apple Silicon, Intel Mac, Ubuntu)

## Directory Structure

```
~/dotfiles/
├── .dotfiles              # List of managed dotfiles
├── install.sh             # Direct-copy installation script
├── SUMMARY.md             # Repository overview and summary
├── scripts/               # Helper scripts
│   └── dotfiles-manager.sh  # Advanced management script
│   └── shortcuts/
│       └── functions.sh   # Utility functions
├── macos/                 # macOS-specific configuration
│   ├── .zshrc             # macOS zsh configuration
│   ├── .zprofile          # macOS shell profile
│   └── bin/               # macOS utilities
│       └── brew-install.sh  # Homebrew installation script
├── ubuntu/                # Ubuntu-specific configuration
│   ├── .bashrc            # Ubuntu bash configuration
│   ├── .zprofile          # Ubuntu shell profile
│   └── bin/               # Ubuntu utilities
│       └── apt-install.sh # Ubuntu package installer
└── shared/                # Configuration files shared across platforms
    ├── .aliases           # Common shell aliases
    ├── .functions         # Shell utility functions
    ├── .gitconfig         # Git configuration
    ├── .gitignore_global  # Global gitignore
    ├── .tmux.conf         # Tmux configuration
    ├── .zshrc             # Common zsh configuration
    ├── .aws/              # AWS CLI configuration
    │   ├── config         # AWS config
    │   └── credentials.template # Credentials template
    ├── .docker/           # Docker configuration
    │   ├── config.json    # Docker CLI config
    │   └── docker-compose.yml.template # Template
    ├── .dockerignore      # Global docker ignore
    ├── .terraformrc       # Terraform configuration
    ├── bin/               # Shared utilities
    │   ├── backup-env.sh  # Environment backup script
    │   └── update-dotfiles.sh # Update dotfiles
    └── .config/
        └── nvim/
            └── init.lua   # Neovim configuration
```

## Quick Start

### Initial Setup on a New Machine

```bash
# Clone the repository
git clone https://github.com/joshuamichaelhall/dotfiles.git ~/dotfiles

# Navigate to the repository
cd ~/dotfiles

# Run the installation script (automatically detects your OS)
./install.sh
```

### Platform-Specific Setup

```bash
# For macOS (both Apple Silicon and Intel)
./macos/bin/brew-install.sh

# For Ubuntu
sudo ./ubuntu/bin/apt-install.sh
```

### Backing Up Your Environment

```bash
# Create a comprehensive backup of your environment
./shared/bin/backup-env.sh
```

### Using the Management Script

For more advanced management, use the dotfiles manager:

```bash
# Run the management script
~/dotfiles/manage
```

## Features

### Installation Highlights

- **Direct File Copying**: Uses robust file copying instead of symlinks for maximum compatibility
- **Cross-Platform Support**: Automatically detects your OS and installs the appropriate configuration files
- **Architecture Detection**: Configures the correct paths for both Apple Silicon and Intel Macs
- **Automatic Backups**: Creates dated backups of your existing configuration before making changes
- **Cloud Tool Integration**: Pre-configured for AWS, Docker, and Terraform

### Management Tools

- **Add New Dotfiles**: Easily add new configuration files to your repository
- **Update From Home**: Sync changes from your home directory to the repository
- **Git Integration**: Commit and push changes to GitHub
- **File Listing**: View all tracked files at a glance
- **Environment Backup**: Create comprehensive backups of your environment
- **Dotfiles Updates**: Pull latest changes and reinstall configurations

## Platform-Specific Support

### macOS

The dotfiles automatically detect and adapt to different Mac architectures:

- **Apple Silicon Macs**: Uses Homebrew at `/opt/homebrew/bin/brew`
- **Intel Macs**: Uses Homebrew at `/usr/local/bin/brew`

The `.zprofile` file automatically detects your Mac's architecture and configures the appropriate paths. Additional features:

- Homebrew packages installation script
- macOS-specific aliases and functions
- Terminal and shell optimizations

### Ubuntu

Ubuntu-specific configurations are stored in the `ubuntu/` directory and are automatically installed when the system is detected as Ubuntu. Additional features:

- APT package installation script
- Ubuntu-specific aliases and functions
- Bash and ZSH configurations

## Development Tools

### AWS Integration

- AWS CLI configuration
- Profile management
- Region settings
- Credential templates (securely)

### Docker Configuration

- Docker CLI configuration
- Docker Compose templates
- Container management functions
- .dockerignore for common patterns

### Terraform Setup

- Terraform CLI configuration
- Provider caching
- Common variable templates
- Helper functions

## Maintenance and Troubleshooting

### Fixing Common Issues

If you encounter broken symlinks or other issues:

```bash
# Run the direct installation script
./install.sh
```

### Updating the Repository

To update your dotfiles from your home directory:

```bash
# Run the management script
~/dotfiles/manage

# Choose option 2: Update repository from home directory
```

To update from the repository and reinstall:

```bash
# Run the update script
./shared/bin/update-dotfiles.sh
```

## Customization

Feel free to:
- Add additional files to track by editing the `.dotfiles` file
- Modify the scripts to suit your workflow
- Create branch-based configurations for different environments
- Extend the platform-specific configurations

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