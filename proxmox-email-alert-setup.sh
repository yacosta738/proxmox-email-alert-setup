#!/bin/bash

# Script to configure email alerts in Proxmox using Gmail/G Suite
# Based on Techno Tim's tutorial: https://technotim.live/posts/proxmox-alerts/
# IMPORTANT: Run this script with sudo or as root.

# --- Privilege Check ---
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root or with sudo." >&2
  exit 1
fi

# --- Exit on error ---
set -e

# --- Variables (you can modify them if desired) ---
POSTFIX_MAIN_CONF="/etc/postfix/main.cf"
POSTFIX_SASL_PASSWD="/etc/postfix/sasl_passwd"
POSTFIX_HEADER_CHECKS="/etc/postfix/smtp_header_checks"
GMAIL_SMTP_SERVER="smtp.gmail.com"
GMAIL_SMTP_PORT="587"

# --- Start of Configuration ---
echo "--- Starting Proxmox email alert configuration ---"

# --- 1. Install dependencies ---
echo "--- Step 1: Updating package list and installing dependencies (libsasl2-modules, mailutils, postfix-pcre) ---"
apt update
apt install -y libsasl2-modules mailutils postfix-pcre
echo "--- Dependencies installed successfully ---"
echo

# --- 2. Configure Google app password ---
echo "--- Step 2: Google account configuration ---"
echo "You will need an 'App Password' from your Google account."
echo "If you don't have one, create it here: https://myaccount.google.com/apppasswords"
read -p "Enter your Gmail/G Suite email address: " GMAIL_USER
read -sp "Enter your Google App Password: " GMAIL_APP_PASSWORD
echo # New line after password entry
echo

# --- 3. Configure Postfix ---
echo "--- Step 3: Configuring Postfix ---"

# Create/update SASL password file
echo "Creating SASL password file..."
echo "[${GMAIL_SMTP_SERVER}]:${GMAIL_SMTP_PORT} ${GMAIL_USER}:${GMAIL_APP_PASSWORD}" > "${POSTFIX_SASL_PASSWD}"

# Set correct permissions
echo "Setting permissions for ${POSTFIX_SASL_PASSWD}..."
chmod 600 "${POSTFIX_SASL_PASSWD}"

# Hash the password file
echo "Hashing SASL password file..."
postmap hash:"${POSTFIX_SASL_PASSWD}"

# Check if the .db file was created (optional, informational)
if [ -f "${POSTFIX_SASL_PASSWD}.db" ]; then
    echo "File ${POSTFIX_SASL_PASSWD}.db created successfully."
else
    echo "WARNING! Could not find ${POSTFIX_SASL_PASSWD}.db." >&2
fi

# Backup and update main.cf
echo "Backing up ${POSTFIX_MAIN_CONF} to ${POSTFIX_MAIN_CONF}.bak..."
cp "${POSTFIX_MAIN_CONF}" "${POSTFIX_MAIN_CONF}.bak"

echo "Adding Gmail configuration to ${POSTFIX_MAIN_CONF}..."
# Remove old configurations if they exist to avoid duplicates (optional but recommended)
sed -i '/^# google mail configuration/,+9 d' "${POSTFIX_MAIN_CONF}"
sed -i '/^smtp_header_checks = .*/d' "${POSTFIX_MAIN_CONF}"
# Remove existing relayhost line to avoid conflicts
sed -i '/^relayhost = /d' "${POSTFIX_MAIN_CONF}"

# Add new configuration
cat << EOF >> "${POSTFIX_MAIN_CONF}"

# google mail configuration - added by script
relayhost = [${GMAIL_SMTP_SERVER}]:${GMAIL_SMTP_PORT}
smtp_use_tls = yes
smtp_sasl_auth_enable = yes
smtp_sasl_security_options = noanonymous
smtp_sasl_password_maps = hash:${POSTFIX_SASL_PASSWD}
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
# The following lines may vary or may not be necessary in all configurations, but are included according to the tutorial
# smtp_tls_session_cache_database = btree:\${data_directory}/smtp_scache
# smtp_tls_session_cache_timeout = 3600s
EOF

echo "Relayhost configuration added."
echo

# --- 4. Customize sender name ---
echo "--- Step 4: Customizing email sender name ---"
read -p "Enter the desired sender name (e.g., Proxmox Server PVE1): " FROM_NAME
read -p "Enter the desired sender email address (can be the same as Gmail or different, e.g., pve1-alert@your_domain.com): " FROM_EMAIL

# Create/update smtp_header_checks file
echo "Creating ${POSTFIX_HEADER_CHECKS}..."
echo "/^From:.*/ REPLACE From: ${FROM_NAME} <${FROM_EMAIL}>" > "${POSTFIX_HEADER_CHECKS}"

# Hash the file
echo "Hashing ${POSTFIX_HEADER_CHECKS}..."
postmap hash:"${POSTFIX_HEADER_CHECKS}"

# Check if the .db file was created (optional, informational)
if [ -f "${POSTFIX_HEADER_CHECKS}.db" ]; then
    echo "File ${POSTFIX_HEADER_CHECKS}.db created successfully."
else
    echo "WARNING! Could not find ${POSTFIX_HEADER_CHECKS}.db." >&2
fi

# Add configuration to main.cf
echo "Adding smtp_header_checks configuration to ${POSTFIX_MAIN_CONF}..."
echo "smtp_header_checks = pcre:${POSTFIX_HEADER_CHECKS}" >> "${POSTFIX_MAIN_CONF}"
echo "Sender customization configuration added."
echo

# --- 5. Reload Postfix ---
echo "--- Step 5: Reloading Postfix service ---"
systemctl reload postfix
echo "Postfix reloaded."
echo

# --- 6. Send test email ---
echo "--- Step 6: Test email sending ---"
read -p "Do you want to send a test email to ${GMAIL_USER}? (y/N): " SEND_TEST_EMAIL
if [[ "$SEND_TEST_EMAIL" =~ ^[Yy]$ ]]; then
    echo "Sending test email to ${GMAIL_USER}..."
    if echo "This is a test message sent from Postfix on your Proxmox server (${HOSTNAME})" | mail -s "Test Email from Proxmox (${HOSTNAME})" "${GMAIL_USER}"; then
        echo "Test email sent. Check your inbox (and spam folder)."
    else
        echo "Error sending test email! Check Postfix configuration and logs (/var/log/mail.log)." >&2
    fi
else
    echo "Skipping test email."
fi
echo

# --- 7. Final Steps (Manual) ---
echo "--- Basic configuration completed! ---"
echo
echo "--- Important Final Steps (Manual in Proxmox GUI): ---"
echo "1.  **Configure Notification Recipient:**"
echo "    Go to 'Datacenter' -> 'Options' -> 'Email Notifications'."
echo "    Set the 'Email Recipient Address' to where you want alerts to be delivered."
echo "    You may also need to configure the 'Email From Address' here if you didn't customize the sender earlier or if Proxmox requires it."
echo
echo "2.  **Enable Specific Alerts:**"
echo "    * **Backup Alerts:** In your backup job configuration ('Datacenter' -> 'Backup'), make sure the 'Send email to' option is configured with the desired address and select when to send emails (e.g., 'Always' or 'On failure')."
echo "    * **SMART Alerts:** Go to 'Your Node' -> 'Disks' -> 'SMART'. Enable SMART monitoring for your disks if you haven't already. Alerts should use the global notification settings."
echo "    * **ZFS Alerts:** If you use ZFS, Proxmox monitors pool status. Make sure general notifications are configured as indicated in step 1. You can test by forcing an error (WITH CAUTION!) as shown in the tutorial video."
echo
echo "Remember to check Postfix logs (/var/log/mail.log) if you encounter issues."
echo "--- Script finished ---"

exit 0