#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "=== Installing AWS SSM Agent ==="
dnf install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
systemctl enable amazon-ssm-agent --now

echo "=== Updating System & Installing Build Dependencies ==="
dnf update -y
dnf install -y python3-pip python3-devel gcc openssl-devel libffi-devel awscli

echo "=== Automating Secure SSH Key Generation ==="
# 1. Ensure the directory exists with tight permissions
mkdir -p /home/ec2-user/.ssh
chmod 700 /home/ec2-user/.ssh

# 2. Generate the Ed25519 key pair directly into the ec2-user directory
# Using -N "" for no passphrase, and running it as ec2-user so it gets the right ownership
sudo -u ec2-user ssh-keygen -t ed25519 -N "" -f /home/ec2-user/.ssh/ansible_ed25519

# 3. Explicitly lock down the private key file permissions (the missing link!)
chmod 600 /home/ec2-user/.ssh/ansible_ed25519
chmod 644 /home/ec2-user/.ssh/ansible_ed25519.pub

# 4. Enforce clean ownership across the entire .ssh folder
chown -R ec2-user:ec2-user /home/ec2-user/.ssh

echo "=== Installing Ansible Core & Cryptography ==="
pip3 install --upgrade pip
pip3 install ansible-core cryptography

echo "=== Installing Ansible Community Crypto Collection System-Wide ==="
export PATH=$PATH:/usr/local/bin
mkdir -p /usr/share/ansible/collections
ansible-galaxy collection install community.crypto -p /usr/share/ansible/collections

echo "=== Setup Complete ==="