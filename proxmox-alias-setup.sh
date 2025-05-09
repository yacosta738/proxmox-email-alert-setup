#!/bin/bash

# Script to automatically add useful aliases to shell configuration file
# For Proxmox VE servers
# IMPORTANT: This script can be run by any user with permissions to their own home directory

# Determine the shell configuration file (Bash or Zsh are most common)
CONFIG_FILE=""
SHELL_TYPE=""

# Display diagnostic info
echo "Diagnostic information:"
echo "Current \$SHELL: $SHELL"
echo "Environment detection: $(env | grep ZSH || echo 'No ZSH environment variables found')"
echo "Shell process: $(ps -p $$ -o comm=)"
echo "------------------------------"

# First, check for ZSH-specific environment variables
if [ -n "$ZSH_VERSION" ]; then
    CONFIG_FILE="$HOME/.zshrc"
    SHELL_TYPE="Zsh (detected by ZSH_VERSION)"
# Then attempt to detect based on SHELL variable
elif [ "$(basename "$SHELL")" = "zsh" ]; then
    CONFIG_FILE="$HOME/.zshrc"
    SHELL_TYPE="Zsh (detected by SHELL)"
elif [ "$(basename "$SHELL")" = "bash" ]; then
    CONFIG_FILE="$HOME/.bashrc"
    SHELL_TYPE="Bash (detected by SHELL)"
else
    # If detection fails, attempt to detect by file existence and current environment
    if [ -f "$HOME/.zshrc" ] && command -v zsh &> /dev/null; then
        CONFIG_FILE="$HOME/.zshrc"
        SHELL_TYPE="Zsh (detected by file presence and command)"
    elif [ -f "$HOME/.bashrc" ]; then
        CONFIG_FILE="$HOME/.bashrc"
        SHELL_TYPE="Bash (detected by file)"
    else
        echo "Error: Could not automatically determine your shell configuration file (.bashrc or .zshrc)."
        echo "Please specify your shell configuration file:"
        echo "1) ~/.bashrc"
        echo "2) ~/.zshrc"
        echo "3) Other (specify path)"
        read -p "Enter choice (1/2/3): " shell_choice
        
        case $shell_choice in
            1)
                CONFIG_FILE="$HOME/.bashrc"
                SHELL_TYPE="Bash (manually selected)"
                ;;
            2)
                CONFIG_FILE="$HOME/.zshrc"
                SHELL_TYPE="Zsh (manually selected)"
                ;;
            3)
                read -p "Enter the full path to your shell configuration file: " custom_path
                CONFIG_FILE="$custom_path"
                SHELL_TYPE="Custom (manually specified)"
                ;;
            *)
                echo "Invalid choice. Exiting."
                exit 1
                ;;
        esac
    fi
fi

echo "Detected shell: $SHELL_TYPE"
echo "Using configuration file: $CONFIG_FILE"
echo ""

# Verify that the config file exists or can be created
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Configuration file $CONFIG_FILE does not exist. Creating it..."
    touch "$CONFIG_FILE" || { 
        echo "Error: Could not create $CONFIG_FILE. Please check permissions."; 
        exit 1; 
    }
    echo "Created $CONFIG_FILE successfully."
fi

# Check if wget is installed, as several aliases require it
if ! command -v wget &> /dev/null; then
    echo "Warning: Command 'wget' not found. Some aliases might not function."
    echo "Consider installing wget (e.g., sudo apt update && sudo apt install wget)"
    echo ""
    # You could add a pause here if desired: read -p "Press Enter to continue..."
fi

# Add aliases to the end of the configuration file
# Using 'cat << EOF >> ...' to better handle quotes and line breaks
echo "Adding aliases to $CONFIG_FILE..."

cat << EOF >> "$CONFIG_FILE"

# --- Automatically added Proxmox aliases ---
alias mv='mv -i'
alias aptup='apt update && apt upgrade'
alias lxcclean='bash -c "\$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/misc/clean-lxcs.sh)"'
alias lxcupdate='bash -c "\$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/misc/update-lxcs.sh)"'
alias lxctrim='bash -c "\$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/misc/fstrim.sh)"'
alias kernelclean='bash -c "\$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/misc/kernel-clean.sh)"'
alias updatecerts='pvecm updatecerts'
# --- End of added aliases ---
EOF

# Check if the operation was successful
if [ $? -eq 0 ]; then
    echo ""
    echo "Success! Aliases have been added to $CONFIG_FILE."
    echo ""
    echo "For changes to take effect, you need to reload your shell configuration."
    echo "You can do this by running one of the following commands:"
    echo "  source $CONFIG_FILE"
    echo "Or simply close and reopen your terminal."
else
    echo ""
    echo "Error: There was a problem adding aliases to $CONFIG_FILE."
    exit 1
fi

exit 0