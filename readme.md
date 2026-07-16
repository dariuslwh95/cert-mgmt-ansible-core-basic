```mermaid
graph TD
    Control[Deployment Server <br> RHEL / ansible-core] --> Crypto[community.crypto Collection]
    Crypto --> Inventory[Dynamic Inventory <br> Linux Servers & FQDNs]
    
    Inventory --> Auth[Key-Pair Authentication <br> SSH via Private Key]
    
    Auth --> CheckFS[Local Filesystem Scans <br> /etc/pki/tls/ & /etc/ssl/]
    Auth --> CheckWS[Active Webserver Audits <br> NGINX / Apache / HAProxy]
    
    CheckFS --> Normalize[Normalize Certificate Metadata <br> Expiry, CN, Issuers]
    CheckWS --> Normalize
    
    Normalize --> CSV[Generate Structured CSV <br> Splunk Ingestion Format]
    CSV --> HEC[Upload to Splunk <br> HTTP Event Collector]

    classDef main fill:#1f4e79,stroke:#fff,stroke-width:2px,color:#fff;
    classDef process fill:#f2f2f2,stroke:#333,stroke-width:1px,color:#000;
    classDef output fill:#d9e1f2,stroke:#1f4e79,stroke-width:1px,color:#000;
    class Control,Crypto,Inventory main;
    class Auth,CheckFS,CheckWS,Normalize process;
    class CSV,HEC output;