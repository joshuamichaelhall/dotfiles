#!/usr/bin/env bash
# Enhanced Terminal Environment Functions - Cross-platform Edition
# Comprehensive helper functions for terminal-based development workflow
# Version: 4.0 - Fixed parsing issues around log_info calls

# Define colors for output
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[0;33m'
readonly RED='\033[0;31m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m' # No Color

#-------------------------------------------------------------
# Utility Functions
#-------------------------------------------------------------

# Simple log functions - Fixed issue with log_info call on line 338
log_info() {
    echo -e "${BLUE}INFO: $1${NC}"
}

log_success() {
    echo -e "${GREEN}SUCCESS: $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}WARNING: $1${NC}"
}

log_error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Create a directory if it doesn't exist
ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir" || {
            log_error "Failed to create directory: $dir"
            return 1
        }
    fi
    return 0
}

#-------------------------------------------------------------
# Project Management Functions
#-------------------------------------------------------------

# Create a new project directory with git initialization
# Usage: newproject <name> [<type>]
# Types: generic, python, node, ruby (default: generic)
newproject() {
    local name="$1"
    local type="${2:-generic}"
    
    if [[ -z "$name" ]]; then
        log_error "Usage: newproject <name> [<type>]"
        log_info "Types: generic, python, node, ruby (default: generic)"
        return 1
    fi
    
    local projects_dir="$HOME/projects"
    # Ensure projects directory exists
    ensure_dir "$projects_dir" || return 1
    
    local project_dir="$projects_dir/$name"
    
    # Check if directory already exists
    if [[ -d "$project_dir" ]]; then
        log_error "Project directory already exists: $project_dir"
        return 1
    fi
    
    # Create directory
    log_info "Creating project directory: $project_dir"
    mkdir -p "$project_dir" || {
        log_error "Failed to create project directory"
        return 1
    }
    
    # Change to project directory
    cd "$project_dir" || {
        log_error "Failed to change to project directory"
        return 1
    }
    
    # Initialize git
    log_info "Initializing Git repository..."
    git init >/dev/null || log_warning "Failed to initialize Git repository"
    
    # Create README.md
    log_info "Creating README.md..."
    cat > README.md << EOF
# $name

## Description

A brief description of the project.

## Installation

\`\`\`bash
# Installation instructions
\`\`\`

## Usage

\`\`\`bash
# Usage examples
\`\`\`

## Acknowledgements

This project was developed with assistance from Anthropic's Claude AI assistant, which helped with:
- Documentation writing and organization
- Code structure suggestions
- Troubleshooting and debugging assistance

Claude was used as a development aid while all final implementation decisions and code review were performed by Joshua Michael Hall.

## Disclaimer

This software is provided "as is", without warranty of any kind, express or implied. The authors or copyright holders shall not be liable for any claim, damages or other liability arising from the use of the software.

This project is a work in progress and may contain bugs or incomplete features. Users are encouraged to report any issues they encounter.
EOF
    
    # Create LICENSE file
    log_info "Creating LICENSE file..."
    cat > LICENSE << EOF
MIT License

Copyright (c) $(date +%Y) Joshua Michael Hall

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

    # Initialize project based on type
    case "$type" in
        python)
            log_info "Creating Python project structure..."
            mkdir -p src tests
            # More Python-specific setup here
            ;;
        node)
            log_info "Creating Node.js project structure..."
            mkdir -p src test
            # More Node-specific setup here
            ;;
        ruby)
            log_info "Creating Ruby project structure..."
            mkdir -p lib spec
            # More Ruby-specific setup here
            ;;
        *)
            log_info "Creating generic project structure..."
            mkdir -p src docs
            ;;
    esac
    
    # Initial commit
    log_info "Creating initial Git commit..."
    git add .
    git commit -m "Initial commit" --no-verify >/dev/null || log_warning "Failed to create initial commit"
    
    log_success "Project setup complete!"
    return 0
}

# Cross-platform helper functions
detect_platform() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
        if [[ $(uname -m) == 'arm64' ]]; then
            export MAC_ARCH="apple_silicon"
        else
            export MAC_ARCH="intel"
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

verify_installation() {
    local platform=$(detect_platform)
    
    log_info "Verifying installation on ${platform} platform"
    
    if [[ "$platform" == "macos" ]]; then
        if [[ "$MAC_ARCH" == "apple_silicon" ]]; then
            if [[ -d "/opt/homebrew" ]]; then
                log_success "Homebrew is installed at /opt/homebrew"
            else
                log_warning "Homebrew not found at /opt/homebrew"
            fi
        else
            if [[ -d "/usr/local/Homebrew" ]]; then
                log_success "Homebrew is installed at /usr/local"
            else
                log_warning "Homebrew not found at /usr/local"
            fi
        fi
    fi
}

# Tmux session creation - works across platforms
mks() {
    local session_name=${1:-dev}
    if ! command_exists tmux; then
        log_error "tmux is not installed. Please install it first."
        return 1
    fi
    
    tmux new-session -d -s "$session_name"
    tmux rename-window -t "$session_name:1" "edit"
    tmux new-window -t "$session_name:2" -n "shell"
    tmux new-window -t "$session_name:3" -n "test"
    tmux select-window -t "$session_name:1"
    tmux attach-session -t "$session_name"
}

# Welcome message
echo "Enhanced Terminal Environment functions loaded."
echo "Type 'verify_installation' to check your environment setup."