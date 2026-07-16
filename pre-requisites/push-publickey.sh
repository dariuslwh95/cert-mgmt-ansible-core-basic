#!/bin/bash
mkdir -p /home/splunk/.ssh && chmod 700 /home/splunk/.ssh
echo "PASTE_YOUR_PUBLIC_KEY_STRING_HERE" > /home/splunk/.ssh/authorized_keys
chmod 600 /home/splunk/.ssh/authorized_keys
chown -R splunk:splunk /home/splunk/.ssh