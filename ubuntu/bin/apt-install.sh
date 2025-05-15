#!/bin/bash
# Ubuntu package installation script

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

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  print_message "Please run this script with sudo or as root" "$RED"
  exit 1
fi

# Update package lists
print_message "Updating package lists..." "$YELLOW"
apt update

# Upgrade packages
print_message "Upgrading packages..." "$YELLOW"
apt upgrade -y

# Install essential packages
print_message "Installing essential packages..." "$YELLOW"
apt install -y \
  apt-transport-https \
  bat \
  build-essential \
  ca-certificates \
  curl \
  fd-find \
  git \
  gnupg \
  htop \
  jq \
  lsb-release \
  neovim \
  net-tools \
  ripgrep \
  software-properties-common \
  tmux \
  tree \
  unzip \
  wget \
  zsh \
  zsh-autosuggestions \
  zsh-syntax-highlighting

# Create symbolic links for fd (fd-find)
ln -sf $(which fdfind) /usr/local/bin/fd

# Install Docker
print_message "Installing Docker..." "$YELLOW"
if ! command -v docker &> /dev/null; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt update
  apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  # Add current user to docker group
  if [ -n "$SUDO_USER" ]; then
    usermod -aG docker $SUDO_USER
    print_message "Added $SUDO_USER to the docker group" "$GREEN"
  fi
else
  print_message "Docker is already installed" "$GREEN"
fi

# Install Node.js via nvm
print_message "Installing Node.js via nvm..." "$YELLOW"
if [ ! -d "$HOME/.nvm" ]; then
  export NVM_DIR="$HOME/.nvm"
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  nvm install --lts
  nvm use --lts
else
  print_message "nvm is already installed" "$GREEN"
fi

# Install AWS CLI
print_message "Installing AWS CLI..." "$YELLOW"
if ! command -v aws &> /dev/null; then
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  ./aws/install
  rm -rf aws awscliv2.zip
else
  print_message "AWS CLI is already installed" "$GREEN"
fi

# Install Terraform
print_message "Installing Terraform..." "$YELLOW"
if ! command -v terraform &> /dev/null; then
  wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
  apt update
  apt install -y terraform
else
  print_message "Terraform is already installed" "$GREEN"
fi

# Set zsh as default shell
if [ -n "$SUDO_USER" ]; then
  print_message "Setting zsh as default shell for $SUDO_USER..." "$YELLOW"
  chsh -s $(which zsh) $SUDO_USER
fi

print_message "Installation complete!" "$GREEN"
print_message "Please log out and log back in for all changes to take effect." "$BLUE"
print_message "Especially for Docker and zsh changes." "$BLUE"