# Dotfiles Repository Summary

This consolidated dotfiles repository provides a cross-platform configuration for macOS (Apple Silicon and Intel) and Ubuntu development environments.

## Repository Structure

```
dotfiles/
├── .dotfiles           # List of files to be installed
├── install.sh          # Main installation script
├── macos/              # macOS specific configurations
│   ├── .zprofile       # macOS specific shell profile
│   └── bin/
│       └── brew-install.sh  # Homebrew installer for macOS
├── ubuntu/             # Ubuntu specific configurations
│   ├── .bashrc         # Ubuntu bashrc
│   ├── .zprofile       # Ubuntu specific shell profile  
│   └── bin/
│       └── apt-install.sh   # Ubuntu package installer
└── shared/             # Shared configurations
    ├── .aliases        # Common shell aliases
    ├── .aws/           # AWS configuration
    │   ├── config
    │   └── credentials.template
    ├── .docker/        # Docker configurations
    │   ├── config.json
    │   └── docker-compose.yml.template
    ├── .dockerignore   # Docker ignore patterns
    ├── .functions      # Shell functions
    ├── .gitconfig      # Git configuration
    ├── .gitignore_global  # Global git ignore
    ├── .terraformrc    # Terraform configuration
    ├── .tmux.conf      # Tmux configuration
    ├── .zshrc          # Common zsh configuration
    ├── bin/            # Utility scripts
    │   ├── backup-env.sh    # Environment backup script
    │   └── update-dotfiles.sh  # Update dotfiles
    └── terraform.tfvars.template  # Terraform variables template
```

## Features

1. **Cross-Platform Support**
   - Works on macOS (Apple Silicon and Intel) and Ubuntu
   - Platform detection to apply appropriate configurations

2. **Shell Environment**
   - Comprehensive ZSH configuration
   - Optional Bash support for Ubuntu
   - Aliases and Functions for productivity

3. **Development Tools**
   - Git configuration
   - AWS CLI configuration
   - Docker setup
   - Terraform configuration

4. **Package Management**
   - Homebrew for macOS
   - APT for Ubuntu

5. **Backup and Restore**
   - Environment backup functionality
   - Dotfiles update mechanism

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/username/dotfiles.git
   cd dotfiles
   ```

2. Run the installation script:
   ```bash
   ./install.sh
   ```

## Platform-Specific Setup

### macOS

For macOS (both Apple Silicon and Intel), additional setup:

```bash
./macos/bin/brew-install.sh
```

This installs Homebrew and essential development packages.

### Ubuntu

For Ubuntu, additional setup:

```bash
sudo ./ubuntu/bin/apt-install.sh
```

This installs essential packages and development tools.

## Maintenance

### Backing Up Environment

```bash
./shared/bin/backup-env.sh
```

This creates a comprehensive backup of your current environment.

### Updating Dotfiles

```bash
./shared/bin/update-dotfiles.sh
```

This pulls the latest changes and updates your dotfiles installation.