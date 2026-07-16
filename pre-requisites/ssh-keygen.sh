#!/bin/bash
sudo -u ansible ssh-keygen -t ed25519 -N "" -f /home/ansible/.ssh/ansible_ed25519

chmod 600 /home/ec2-user/.ssh/ansible_ed25519
chmod 644 /home/ec2-user/.ssh/ansible_ed25519.pub