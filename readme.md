                 Deployment Server (RHEL)

                       ansible-core
                             │
                community.crypto collection
                             │
                     Dynamic Inventory
                             │
       ┌─────────────────────┴─────────────────────┐
       │                                           │
SSH to Linux servers                    DNS/FQDN inventory
       │                                           │
Find configured certificates          Resolve hostnames
       │                                           │
Parse NGINX/Apache/HAProxy          openssl s_client
Application keystores (JKS/P12)           │
       └─────────────────────┬─────────────────────┘
                             │
                 Normalize certificate data
                             │
                  Generate CSV for Splunk
                             │
                    Upload to Splunk HEC
