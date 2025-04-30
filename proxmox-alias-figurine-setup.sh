#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default settings
VERBOSE=false

# Function to show usage
show_usage() {
  echo -e "Usage: $0 [OPTIONS]"
  echo -e "Options:"
  echo -e "  -v, --verbose    Enable verbose output"
  echo -e "  -h, --help       Show this help message"
  echo -e "  -s, --shell      Specify shell config file (bash, zsh, fish or path)"
}

# Function to log verbose information
log_verbose() {
  if $VERBOSE; then
    echo -e "${CYAN}[VERBOSE] $1${NC}" >&2
  fi
}

# Parse command line arguments
parse_args() {
  CUSTOM_SHELL=""
  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -v|--verbose)
        VERBOSE=true
        log_verbose "Verbose mode enabled"
        ;;
      -h|--help)
        show_usage
        exit 0
        ;;
      -s|--shell)
        CUSTOM_SHELL="$2"
        log_verbose "Custom shell specified: $CUSTOM_SHELL"
        shift
        ;;
      *)
        echo -e "${RED}Unknown parameter: $1${NC}"
        show_usage
        exit 1
        ;;
    esac
    shift
  done
}

# Display diagnostic info
display_diagnostics() {
  log_verbose "--------- SHELL DIAGNOSTICS ---------"
  log_verbose "Current \$SHELL: $SHELL"
  log_verbose "Current \$ZSH_VERSION: $ZSH_VERSION"
  log_verbose "Current \$BASH_VERSION: $BASH_VERSION"
  log_verbose "\$HOME/.zshrc exists: $([ -f "$HOME/.zshrc" ] && echo "Yes" || echo "No")"
  log_verbose "\$HOME/.bashrc exists: $([ -f "$HOME/.bashrc" ] && echo "Yes" || echo "No")"
  log_verbose "Shell process: $(ps -p $$ -o comm=)"
  log_verbose "----------------------------------"
}

# Detect shell configuration file
detect_shell_config() {
  # Show diagnostics but don't capture in output
  display_diagnostics >&2
  
  # If a custom shell was specified, use it
  if [ -n "$CUSTOM_SHELL" ]; then
    log_verbose "Using custom shell configuration: $CUSTOM_SHELL" >&2
    
    case "$CUSTOM_SHELL" in
      bash)
        if [ -f "$HOME/.bashrc" ]; then
          echo "$HOME/.bashrc"
        elif [ -f "$HOME/.bash_profile" ]; then
          echo "$HOME/.bash_profile"
        else
          echo ""
        fi
        ;;
      zsh)
        echo "$HOME/.zshrc"
        ;;
      fish)
        echo "$HOME/.config/fish/config.fish"
        ;;
      *)
        # Assume it's a direct path
        echo "$CUSTOM_SHELL"
        ;;
    esac
    return
  fi
  
  # First check for ZSH-specific environment variables
  if [ -n "$ZSH_VERSION" ]; then
    log_verbose "ZSH detected via ZSH_VERSION, using ~/.zshrc" >&2
    echo "$HOME/.zshrc"
    return
  fi
  
  # Check SHELL environment variable
  if [[ "$SHELL" == */zsh ]]; then
    log_verbose "ZSH detected via SHELL variable, using ~/.zshrc" >&2
    echo "$HOME/.zshrc"
    return
  elif [[ "$SHELL" == */bash ]]; then
    if [ -f "$HOME/.bashrc" ]; then
      log_verbose "BASH detected via SHELL variable, using ~/.bashrc" >&2
      echo "$HOME/.bashrc"
      return
    elif [ -f "$HOME/.bash_profile" ]; then
      log_verbose "BASH detected via SHELL variable, using ~/.bash_profile" >&2
      echo "$HOME/.bash_profile"
      return
    fi
  fi
  
  # Check for common config files
  if [ -f "$HOME/.zshrc" ] && command -v zsh &> /dev/null; then
    log_verbose "ZSH detected via file existence, using ~/.zshrc" >&2
    echo "$HOME/.zshrc"
  elif [ -f "$HOME/.bashrc" ]; then
    log_verbose "BASH detected via file existence, using ~/.bashrc" >&2
    echo "$HOME/.bashrc"
  elif [ -f "$HOME/.bash_profile" ]; then
    log_verbose "BASH detected via file existence, using ~/.bash_profile" >&2
    echo "$HOME/.bash_profile"
  elif [ -f "$HOME/.config/fish/config.fish" ]; then
    log_verbose "FISH detected via file existence, using ~/.config/fish/config.fish" >&2
    echo "$HOME/.config/fish/config.fish"
  else
    log_verbose "Could not detect shell configuration file" >&2
    
    echo -e "${YELLOW}Could not automatically determine your shell configuration file.${NC}" >&2
    echo -e "Please select your shell configuration file:" >&2
    echo -e "1) ~/.bashrc" >&2
    echo -e "2) ~/.zshrc" >&2
    echo -e "3) ~/.config/fish/config.fish" >&2
    echo -e "4) Other (specify path)" >&2
    read -p "Enter choice (1/2/3/4): " shell_choice
    
    case $shell_choice in
      1)
        echo "$HOME/.bashrc"
        ;;
      2)
        echo "$HOME/.zshrc"
        ;;
      3)
        echo "$HOME/.config/fish/config.fish"
        ;;
      4)
        read -p "Enter the full path to your shell configuration file: " custom_path
        echo "$custom_path"
        ;;
      *)
        echo ""
        ;;
    esac
  fi
}

# Check if figurine is already installed
check_figurine_installed() {
  log_verbose "Checking if figurine is already installed..."
  
  if command -v figurine &> /dev/null; then
    log_verbose "figurine command found in PATH"
    echo -e "${GREEN}✓ Figurine is already installed.${NC}"
    return 0
  else
    log_verbose "figurine command not found in PATH"
    echo -e "${YELLOW}⚠ Figurine is not installed.${NC}"
    return 1
  fi
}

# Install figurine
install_figurine() {
  echo -e "${BLUE}Installing figurine...${NC}"
  log_verbose "Starting figurine installation process"
  
  # Try to install using the installer script
  log_verbose "Attempting installation via installer script"
  if curl -sSL https://raw.githubusercontent.com/yacosta738/figurine/main/install.sh | bash; then
    log_verbose "Installer script completed successfully"
    echo -e "${GREEN}✓ Figurine installed successfully.${NC}"
  else
    # If installer script fails, try with go install
    log_verbose "Installer script failed. Trying with Go..."
    echo -e "${YELLOW}Installer script failed. Trying with Go...${NC}"
    
    if command -v go &> /dev/null; then
      log_verbose "Go is installed, attempting to install figurine with 'go install'"
      if go install github.com/yacosta738/figurine@latest; then
        log_verbose "Go installation completed successfully"
        echo -e "${GREEN}✓ Figurine installed successfully with Go.${NC}"
      else
        log_verbose "Failed to install figurine with Go"
        echo -e "${RED}✗ Failed to install figurine with Go.${NC}"
        return 1
      fi
    else
      log_verbose "Go is not installed"
      echo -e "${RED}✗ Neither installer script nor Go is available.${NC}"
      return 1
    fi
  fi
  
  log_verbose "Installation process completed"
  return 0
}

# Add figurine to shell configuration
add_to_shell_config() {
  local shell_config="$1"
  
  if [ -z "$shell_config" ]; then
    log_verbose "Shell configuration file is empty"
    echo -e "${RED}✗ Could not determine shell configuration file.${NC}"
    return 1
  fi
  
  log_verbose "Adding figurine to shell configuration file: $shell_config"
  echo -e "${BLUE}Adding figurine to $shell_config...${NC}"
  
  # Ensure the shell config file exists
  if [ ! -f "$shell_config" ]; then
    log_verbose "Creating shell configuration file: $shell_config"
    echo -e "${YELLOW}Shell configuration file $shell_config does not exist. Creating it...${NC}"
    touch "$shell_config" || {
      log_verbose "Failed to create shell configuration file"
      echo -e "${RED}✗ Failed to create $shell_config. Check permissions.${NC}"
      return 1
    }
  fi
  
  # Check if figurine command is already in the config
  log_verbose "Checking if figurine command already exists in config"
  if grep -q "figurine -f \"3d.flf\" \$(hostname)" "$shell_config"; then
    log_verbose "figurine command already exists in configuration"
    echo -e "${GREEN}✓ Figurine command already exists in $shell_config.${NC}"
    return 0
  fi
  
  # Add the command
  log_verbose "Adding figurine command to configuration file"
  cat >> "$shell_config" << EOF

# Display hostname with figurine
echo ""
figurine -f "3d.flf" \$(hostname)
echo ""
EOF
  
  log_verbose "Command added successfully"
  echo -e "${GREEN}✓ Added figurine command to $shell_config.${NC}"
  echo -e "${YELLOW}Please restart your shell or run 'source $shell_config' to apply changes.${NC}"
  return 0
}

# Main function
main() {
  echo -e "${BLUE}=====================================${NC}"
  echo -e "${BLUE}     Figurine Setup Script          ${NC}"
  echo -e "${BLUE}=====================================${NC}"
  
  # Parse command line arguments
  parse_args "$@"
  
  log_verbose "Starting the setup process"
  
  # Check if figurine is already installed
  if ! check_figurine_installed; then
    log_verbose "Figurine needs to be installed"
    if ! install_figurine; then
      log_verbose "Installation failed"
      echo -e "${RED}✗ Failed to install figurine. Exiting.${NC}"
      exit 1
    fi
  fi
  
  # Detect shell configuration file
  log_verbose "Detecting shell configuration file"
  local shell_config=$(detect_shell_config)
  log_verbose "Detected shell config: $shell_config"
  
  # Add figurine to shell config
  if add_to_shell_config "$shell_config"; then
    log_verbose "Setup completed successfully"
    echo -e "${GREEN}✓ Setup completed successfully.${NC}"
    # Show an example of how it will look
    log_verbose "Showing example output"
    echo -e "${BLUE}Here's how it will appear in your terminal:${NC}"
    echo ""
    figurine -f "3d.flf" $(hostname)
    echo ""
  else
    log_verbose "Failed to add figurine to shell configuration"
    echo -e "${RED}✗ Failed to add figurine to shell configuration.${NC}"
    echo -e "${YELLOW}You can manually add the following to your shell configuration file:${NC}"
    echo -e "echo \"\""
    echo -e "figurine -f \"3d.flf\" \$(hostname)"
    echo -e "echo \"\""
    exit 1
  fi
}

# Run the script with all arguments passed to it
main "$@"
