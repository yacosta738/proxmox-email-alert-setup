# Proxmox Email Alert Setup

This repository contains scripts to easily configure email alerts and useful aliases on Proxmox servers.

## 📋 Features

- Automated configuration of Postfix for sending emails
- Support for SMTP authentication with Gmail/G Suite
- Customization of sender name and address
- Email sending test to verify the configuration
- Step-by-step instructions for complete alert setup in Proxmox
- Script to add useful aliases to your Proxmox shell
- Verbose mode option to see detailed script execution information

## 🚀 Quick Usage

To run the email setup script directly from GitHub:

```bash
bash -c "$(curl -fsS https://raw.githubusercontent.com/yacosta738/proxmox-email-alert-setup/main/proxmox-email-alert-setup.sh)"
```

To run the alias setup script directly from GitHub:

```bash
bash -c "$(curl -fsS https://raw.githubusercontent.com/yacosta738/proxmox-email-alert-setup/main/proxmox-alias-setup.sh)"
```

> ⚠️ **Important**: Replace `yacosta738` with your GitHub username after forking or cloning this repository.

## ⚙️ Prerequisites

Before running the script, you'll need:

1. A Proxmox VE server installed and running
2. Root or sudo access to the server
3. A Gmail/G Suite account
4. A Google "App Password" (not your regular password)
   - To create one, visit [https://myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords)

## 📥 Manual Installation

If you prefer a manual installation:

1. Clone this repository or download the scripts:

   ```bash
   git clone https://github.com/yacosta738/proxmox-email-alert-setup.git
   cd proxmox-email-alert-setup
   ```

2. Make the scripts executable:

   ```bash
   chmod +x proxmox-email-alert-setup.sh
   chmod +x proxmox-alias-setup.sh
   ```

3. Run the scripts:

   ```bash
   # For email alerts setup (requires root/sudo)
   sudo ./proxmox-email-alert-setup.sh
   
   # For adding useful aliases (can be run as regular user)
   ./proxmox-alias-setup.sh
   ```

## 🔍 What do the scripts do?

### Email Alert Setup

1. **Installs necessary dependencies**:
   - `libsasl2-modules`: Support for SASL authentication
   - `mailutils`: Tools for sending emails
   - `postfix-pcre`: Support for regular expressions in Postfix

2. **Configures SMTP authentication** for Gmail/G Suite:
   - Creates and configures the SASL password file
   - Updates Postfix configuration to use TLS

3. **Customizes the sender** of email notifications:
   - Allows you to specify a custom name and email address

4. **Tests the configuration** by sending a test email

5. **Provides instructions** to complete the setup in the Proxmox web interface

### Alias Setup

The `proxmox-alias-setup.sh` script adds convenient aliases to your shell configuration:

1. **Automatically detects your shell** (Bash or Zsh)
2. **Adds useful aliases** to your configuration file:
   - `mv='mv -i'`: Interactive move to prevent accidental overwrites
   - `aptup='apt update && apt upgrade'`: Quick package updates
   - `lxcclean`: Clean unused LXC container data
   - `lxcupdate`: Update all LXC containers
   - `lxctrim`: Run FSTRIM on LXC containers
   - `kernelclean`: Clean old kernel packages
   - `updatecerts='pvecm updatecerts'`: Update Proxmox cluster certificates

## 🛠️ Additional Configuration in Proxmox

After running the script, you need to complete the configuration in the Proxmox web interface:

1. **Configure alerts recipient**:
   - Go to `Datacenter` -> `Options` -> `Email Notifications`
   - Set up the recipient's email address

2. **Enable specific alerts**:
   - **Backups**: In your backup job configuration
   - **SMART**: In your node's disks section
   - **ZFS**: Sent automatically if general notifications are configured

## 📝 Troubleshooting

If you encounter issues:

1. Check Postfix logs:

   ```bash
   tail -f /var/log/mail.log
   ```

2. Verify that your Google App Password is correct

3. Make sure your Google account doesn't have restrictions preventing less secure apps access

4. If using Gmail, verify that less secure apps access is enabled (or use an App Password if you have two-factor authentication enabled)

## 🛠️ Figurine Script Installation

To run the figurine setup script directly from GitHub:

```bash
bash -c "$(curl -fsS https://raw.githubusercontent.com/yacosta738/proxmox-email-alert-setup/main/proxmox-alias-figurine-setup.sh)"
```

For detailed verbose output showing what's happening during the setup process:

```bash
bash -c "$(curl -fsS https://raw.githubusercontent.com/yacosta738/proxmox-email-alert-setup/main/proxmox-alias-figurine-setup.sh)" -- --verbose
```

You can also use the `-v` short option for verbose mode:

```bash
bash -c "$(curl -fsS https://raw.githubusercontent.com/yacosta738/proxmox-email-alert-setup/main/proxmox-alias-figurine-setup.sh)" -- -v
```

For help and available options:

```bash
bash -c "$(curl -fsS https://raw.githubusercontent.com/yacosta738/proxmox-email-alert-setup/main/proxmox-alias-figurine-setup.sh)" -- --help
```

### What does the figurine script do?

The `proxmox-alias-figurine-setup.sh` script installs the `figurine` tool and configures it to display the hostname in a 3D font whenever you open a new terminal session. It automatically detects your shell configuration file and adds the necessary commands to it.

## ⭐ Based on

This script is based on the excellent tutorial by [Techno Tim](https://technotim.live/posts/proxmox-alerts/).

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome. If you find any issues or have improvements, feel free to open an issue or submit a pull request.
