#!/bin/bash
set -e

echo "[SECURITY] Install UFW & Fail2Ban..."
sudo apt-get install -y ufw fail2ban unattended-upgrades

SSH_PORT="${SSH_PORT:-22}"

echo "[SECURITY] Configure UFW (deny inbound, allow SSH/HTTP/HTTPS)..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
if [ "$SSH_PORT" = "22" ]; then
  sudo ufw allow OpenSSH
else
  echo "[SECURITY] Non-default SSH port detected, allowing ${SSH_PORT}/tcp..."
  sudo ufw allow "${SSH_PORT}/tcp"
fi
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

echo "[SECURITY] Harden SSH (disable root login)..."
sudo mv /tmp/secure_sshd_config.conf /etc/ssh/sshd_config.d/99-secure.conf
sudo chown root:root /etc/ssh/sshd_config.d/99-secure.conf
sudo chmod 644 /etc/ssh/sshd_config.d/99-secure.conf

ENABLE_PASSWORD_AUTH="${ENABLE_PASSWORD_AUTH:-false}"
if [ "$ENABLE_PASSWORD_AUTH" = "true" ]; then
  echo "[SECURITY] Password authentication in use, keeping it enabled..."
  sudo sed -i \
    -e 's/^AuthenticationMethods .*/AuthenticationMethods any/' \
    -e 's/^#\s*PasswordAuthentication .*/PasswordAuthentication yes/' \
    /etc/ssh/sshd_config.d/99-secure.conf
fi

ENABLE_ROOT_LOGIN="${ENABLE_ROOT_LOGIN:-false}"
if [ "$ENABLE_ROOT_LOGIN" = "true" ]; then
  echo "[SECURITY] WARNING: ssh_username is 'root', keeping root login enabled (not recommended)..."
  sudo sed -i \
    -e 's/^PermitRootLogin .*/PermitRootLogin yes/' \
    /etc/ssh/sshd_config.d/99-secure.conf
fi

# Test SSH config for errors before restarting
sudo sshd -t
echo "[SECURITY] Restart SSH to apply changes..."
sudo systemctl restart ssh

echo "[SECURITY] Enable unattended security updates..."
sudo dpkg-reconfigure -f noninteractive unattended-upgrades

echo "[SECURITY] Configure Fail2Ban to use UFW for bans..."
# Make sure the ufw action is present (it is on Ubuntu by default at /etc/fail2ban/action.d/ufw.conf)
cat <<'EOF' | sudo tee /etc/fail2ban/jail.local >/dev/null
[DEFAULT]
# Use UFW to enforce bans
banaction = ufw
banaction_allports = ufw
backend = systemd

# Tuning
bantime  = 1h
findtime = 10m
maxretry = 5

# Optional: whitelist your own network (uncomment and edit)
# ignoreip = 127.0.0.1/8 ::1 10.0.0.0/8 192.168.0.0/16

[sshd]
enabled = true
port    = ssh
logpath = %(sshd_log)s
EOF

echo "[SECURITY] Enable & restart Fail2Ban..."
sudo systemctl enable fail2ban
sudo systemctl restart fail2ban

echo "[SECURITY] Cleanup..."
sudo apt-get autoremove -y
sudo apt-get clean
echo "[SECURITY] Completed."
