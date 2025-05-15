# Dotfiles Setup Guide

This guide walks you through setting up and using the dotfiles repository on a new machine. Follow these steps to get a consistent development environment across macOS (Apple Silicon & Intel) and Ubuntu systems.

## Table of Contents

- [Initial Installation](#initial-installation)
- [macOS Setup](#macos-setup)
- [Ubuntu Setup](#ubuntu-setup)
- [AWS Configuration](#aws-configuration)
- [Docker Configuration](#docker-configuration)
- [Terraform Configuration](#terraform-configuration)
- [Daily Usage](#daily-usage)
- [Backing Up Your Environment](#backing-up-your-environment)
- [Troubleshooting](#troubleshooting)

## Initial Installation

### 1. Clone the Repository

First, clone the dotfiles repository to your home directory:

```bash
git clone https://github.com/joshuamichaelhall/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 2. Run the Installation Script

The installation script will automatically detect your operating system and install the appropriate configuration files:

```bash
./install.sh
```

This script:
- Detects your OS and architecture
- Backs up your existing configuration files
- Installs new configuration files from the dotfiles repository
- Reports any issues that might occur during installation

### 3. Restart Your Terminal

For all changes to take effect, restart your terminal after installation:

```bash
exec $SHELL -l
```

## macOS Setup

### Install Development Tools

After installing the dotfiles, you can set up common development tools on macOS:

```bash
# Install Homebrew and packages
./macos/bin/brew-install.sh
```

This script will:
- Install or update Homebrew
- Install essential command line tools
- Install development tools (Node.js, Python, Ruby, etc.)
- Install AWS CLI, Terraform, and Docker CLI
- Install common applications via brew cask

### Additional macOS Customizations

The dotfiles include macOS-specific configurations:
- Terminal settings optimized for development
- Homebrew path configuration for both Apple Silicon and Intel Macs
- Useful shell aliases and functions

## Ubuntu Setup

### Install Development Tools

After installing the dotfiles, you can set up common development tools on Ubuntu:

```bash
# Run with sudo to install system packages
sudo ./ubuntu/bin/apt-install.sh
```

This script will:
- Update and upgrade your Ubuntu system
- Install essential development packages
- Install Docker and configure your user account
- Install Node.js via nvm
- Install AWS CLI
- Install Terraform
- Set zsh as the default shell

### Additional Ubuntu Customizations

The dotfiles include Ubuntu-specific configurations:
- Terminal settings optimized for development
- Bash and ZSH configurations
- Useful shell aliases and functions

## AWS Configuration

### Set Up AWS CLI

The dotfiles include AWS CLI configuration templates. After installation:

1. Review the AWS config file:
   ```bash
   cat ~/.aws/config
   ```

2. Copy the credentials template and add your actual AWS credentials:
   ```bash
   cp ~/.aws/credentials.template ~/.aws/credentials
   vim ~/.aws/credentials  # Or use your preferred editor
   ```

3. Test your AWS configuration:
   ```bash
   aws sts get-caller-identity
   ```

## Docker Configuration

### Docker Setup

The dotfiles include Docker configuration. After installation:

1. Review Docker CLI config:
   ```bash
   cat ~/.docker/config.json
   ```

2. Review Docker Compose template:
   ```bash
   cat ~/.docker/docker-compose.yml.template
   ```

3. Check Docker aliases and functions:
   ```bash
   grep -A 10 "Docker aliases" ~/.aliases
   grep -A 10 "Docker" ~/.functions
   ```

## Terraform Configuration

### Terraform Setup

The dotfiles include Terraform configuration. After installation:

1. Review the Terraform config:
   ```bash
   cat ~/.terraformrc
   ```

2. Copy the Terraform variables template for use in your projects:
   ```bash
   cp ~/dotfiles/shared/terraform.tfvars.template ~/your-project/terraform.tfvars
   vim ~/your-project/terraform.tfvars  # Or use your preferred editor
   ```

## Daily Usage

### Shell Aliases and Functions

The dotfiles include numerous aliases and functions to improve your workflow. Here are some highlights:

```bash
# Navigation
.. # Go up one directory
... # Go up two directories

# Git commands
gs # git status
gl # git pull
gp # git push

# Docker commands
d # docker
dc # docker-compose
dps # docker ps

# AWS commands
awsprofile dev # Switch to the dev AWS profile
awswho # Show current AWS identity

# Terraform commands
tf # terraform
tfi # terraform with auto-init
```

View all available aliases and functions:

```bash
cat ~/.aliases
cat ~/.functions
```

### Dotfiles Management

For day-to-day management of your dotfiles, use the management script:

```bash
~/dotfiles/manage
```

This interactive script allows you to:
1. View tracked files
2. Update your dotfiles repository from your home directory
3. Install dotfiles from the repository to your home directory
4. Add new files to track
5. Commit and push changes to GitHub

## Backing Up Your Environment

Before making significant changes to your environment, create a backup:

```bash
~/dotfiles/shared/bin/backup-env.sh
```

This script creates a comprehensive backup of your current environment settings, including:
- Shell configurations
- Git configurations
- SSH configurations (without private keys)
- Vim configurations
- AWS configurations (without credentials)
- Terraform configurations
- Docker configurations (without auth tokens)

## Troubleshooting

### Common Issues

#### 1. Shell commands not found

If shell commands are not found after installation:

```bash
# Source your shell configuration
source ~/.zshrc  # For Zsh
source ~/.bashrc  # For Bash

# Or restart your shell
exec $SHELL -l
```

#### 2. Homebrew path issues on macOS

If Homebrew commands are not found:

```bash
# For Apple Silicon Macs
eval "$(/opt/homebrew/bin/brew shellenv)"

# For Intel Macs
eval "$(/usr/local/bin/brew shellenv)"
```

#### 3. Permission issues on installation scripts

If you encounter permission issues with scripts:

```bash
# Make scripts executable
chmod +x ~/dotfiles/install.sh
chmod +x ~/dotfiles/macos/bin/brew-install.sh
chmod +x ~/dotfiles/ubuntu/bin/apt-install.sh
chmod +x ~/dotfiles/shared/bin/backup-env.sh
chmod +x ~/dotfiles/shared/bin/update-dotfiles.sh
```

#### 4. Updating after upstream changes

To update your local installation after changes in the repository:

```bash
# Pull latest changes
cd ~/dotfiles
git pull

# Run update script
./shared/bin/update-dotfiles.sh
```

#### 5. Local changes conflict with repository

If your local changes conflict with the repository:

```bash
# View local changes
cd ~/dotfiles
git status

# Either commit your changes
git add -A
git commit -m "My local customizations"

# Or stash them temporarily
git stash
git pull
git stash pop
```

---

For additional help or to report issues, please open an issue on the GitHub repository: https://github.com/joshuamichaelhall/dotfiles/issues