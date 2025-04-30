#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Detect shell configuration file
detect_shell_config() {
  if [ -n "$ZSH_VERSION" ]; then
    echo "$HOME/.zshrc"
  elif [ -n "$BASH_VERSION" ]; then
    if [ -f "$HOME/.bashrc" ]; then
      echo "$HOME/.bashrc"
    elif [ -f "$HOME/.bash_profile" ]; then
      echo "$HOME/.bash_profile"
    fi
  elif [ -f "$HOME/.config/fish/config.fish" ]; then
    echo "$HOME/.config/fish/config.fish"
  else
    echo ""
  fi
}

# Check if figurine is already installed
check_figurine_installed() {
  if command -v figurine &> /dev/null; then
    echo -e "${GREEN}✓ Figurine is already installed.${NC}"
    return 0
  else
    echo -e "${YELLOW}⚠ Figurine is not installed.${NC}"
    return 1
  fi
}

# Install figurine
install_figurine() {
  echo -e "${BLUE}Installing figurine...${NC}"
  
  # Try to install using the installer script
  if curl -sSL https://raw.githubusercontent.com/yacosta738/figurine/main/install.sh | bash; then
    echo -e "${GREEN}✓ Figurine installed successfully.${NC}"
  else
    # If installer script fails, try with go install
    echo -e "${YELLOW}Installer script failed. Trying with Go...${NC}"
    if command -v go &> /dev/null; then
      if go install github.com/yacosta738/figurine@latest; then
        echo -e "${GREEN}✓ Figurine installed successfully with Go.${NC}"
      else
        echo -e "${RED}✗ Failed to install figurine with Go.${NC}"
        return 1
      fi
    else
      echo -e "${RED}✗ Neither installer script nor Go is available.${NC}"
      return 1
    fi
  fi
  return 0
}

# Add figurine to shell configuration
add_to_shell_config() {
  local shell_config="$1"
  
  if [ -z "$shell_config" ]; then
    echo -e "${RED}✗ Could not determine shell configuration file.${NC}"
    return 1
  fi
  
  echo -e "${BLUE}Adding figurine to $shell_config...${NC}"
  
  # Check if figurine command is already in the config
  if grep -q "figurine -f \"3d.flf\" \$(hostname)" "$shell_config"; then
    echo -e "${GREEN}✓ Figurine command already exists in $shell_config.${NC}"
    return 0
  fi
  
  # Add the command
  cat >> "$shell_config" << EOF

# Display hostname with figurine
echo ""
figurine -f "3d.flf" \$(hostname)
echo ""
EOF
  
  echo -e "${GREEN}✓ Added figurine command to $shell_config.${NC}"
  echo -e "${YELLOW}Please restart your shell or run 'source $shell_config' to apply changes.${NC}"
  return 0
}

# Main function
main() {
  echo -e "${BLUE}=====================================${NC}"
  echo -e "${BLUE}     Figurine Setup Script          ${NC}"
  echo -e "${BLUE}=====================================${NC}"
  
  # Check if figurine is already installed
  if ! check_figurine_installed; then
    if ! install_figurine; then
      echo -e "${RED}✗ Failed to install figurine. Exiting.${NC}"
      exit 1
    fi
  fi
  
  # Detect shell configuration file
  local shell_config=$(detect_shell_config)
  
  # Add figurine to shell config
  if add_to_shell_config "$shell_config"; then
    echo -e "${GREEN}✓ Setup completed successfully.${NC}"
    # Show an example of how it will look
    echo -e "${BLUE}Here's how it will appear in your terminal:${NC}"
    echo ""
    figurine -f "3d.flf" $(hostname)
    echo ""
  else
    echo -e "${RED}✗ Failed to add figurine to shell configuration.${NC}"
    echo -e "${YELLOW}You can manually add the following to your shell configuration file:${NC}"
    echo -e "echo \"\""
    echo -e "figurine -f \"3d.flf\" \$(hostname)"
    echo -e "echo \"\""
    exit 1
  fi
}

# Run the script
main
