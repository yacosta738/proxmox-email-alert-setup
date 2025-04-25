# Proxmox Email Alert Setup

This repository contains a script to easily configure email alerts on Proxmox servers using Gmail/G Suite.

## 📋 Features

- Automated configuration of Postfix for sending emails
- Support for SMTP authentication with Gmail/G Suite
- Customization of sender name and address
- Email sending test to verify the configuration
- Step-by-step instructions for complete alert setup in Proxmox

## 🚀 Quick Usage

To run the script directly from GitHub:

```bash
bash -c "$(curl -fsS https://raw.githubusercontent.com/yacosta738/proxmox-email-alert-setup/main/proxmox-email-alert-setup.sh)"
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

1. Clone this repository or download the script:

   ```bash
   git clone https://github.com/yacosta738/proxmox-email-alert-setup.git
   cd proxmox-email-alert-setup
   ```

2. Make the script executable:

   ```bash
   chmod +x proxmox-email-alert-setup.sh
   ```

3. Run the script with root permissions:

   ```bash
   sudo ./proxmox-email-alert-setup.sh
   ```

## 🔍 What does the script do?

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

## ⭐ Based on

This script is based on the excellent tutorial by [Techno Tim](https://technotim.live/posts/proxmox-alerts/).

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome. If you find any issues or have improvements, feel free to open an issue or submit a pull request.
