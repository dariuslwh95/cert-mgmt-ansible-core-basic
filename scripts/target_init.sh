#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "=== Installing AWS SSM Agent ==="
dnf install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
systemctl enable amazon-ssm-agent --now

echo "=== Installing Python 3 & Utilities ==="
dnf update -y
dnf install -y python3 aws-cli