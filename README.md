# SIEM Home Lab: Detection Engineering & Automated Incident Response

A fully functional Security Operations Center (SOC) environment featuring real-time threat detection using Wazuh SIEM and Suricata IDS, custom MITRE ATT&CK-mapped detection rules, and automated incident response capabilities.

---

## Overview

This project demonstrates end-to-end security operations by building a multi-VM lab environment where real attacks are launched, detected, analyzed, and automatically responded to. Every detection rule is mapped to the MITRE ATT&CK framework, and automated playbooks handle containment actions like IP blocking and user account lockout.

### Key Highlights

- 9 custom detection rules mapped to MITRE ATT&CK framework
- 5 real attack simulations covering the full cyber kill chain
- 3 automated response playbooks (IP blocking, user lockout, enriched alerting)
- Custom SOC monitoring dashboard with multiple visualization panels
- Network-level and endpoint-level detection coverage

---

## Architecture

| Component | Role | IP Address |
|:----------|:-----|:-----------|
| Wazuh Server (Ubuntu 22.04) | SIEM — Manager, Indexer, Dashboard | `192.168.56.10` |
| Target Machine (Ubuntu 22.04) | Monitored endpoint with Wazuh Agent, Suricata, auditd | `192.168.56.11` |
| Kali Linux | Attack simulation machine | `192.168.56.12` |

> **Network:** Isolated host-only network (`192.168.56.0/24`) running on Oracle VirtualBox

```
┌──────────────────────────────────────────────────────────────┐
│                       VirtualBox Host                        │
│                                                              │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐ │
│  │  Wazuh Server  │  │ Target Machine │  │  Kali Linux    │ │
│  │                │  │                │  │  (Attacker)    │ │
│  │  - Wazuh Mgr   │  │  - Wazuh Agent │  │                │ │
│  │  - Indexer     │◄─┤  - Suricata    │  │  - Nmap        │ │
│  │  - Dashboard   │  │  - auditd      │  │  - Hydra       │ │
│  │                │  │  - Apache2     │  │  - Nikto       │ │
│  │  .56.10        │  │  .56.11        │  │  .56.12        │ │
│  └────────────────┘  └────────────────┘  └────────────────┘ │
│                                                              │
│            Network: 192.168.56.0/24 (Host-Only)              │
└──────────────────────────────────────────────────────────────┘
```

---

## Tech Stack

| Category | Technology |
|:---------|:-----------|
| SIEM Platform | Wazuh 4.9.2 (Manager + Indexer + Dashboard) |
| Network IDS | Suricata 7.x with Emerging Threats ruleset |
| Endpoint Monitoring | auditd (Linux Audit Daemon) |
| Log Forwarding | Filebeat |
| Attack Tools | Nmap, Hydra, Nikto, dirb, Netcat |
| Threat Framework | MITRE ATT&CK |
| Virtualization | Oracle VirtualBox |
| Operating Systems | Ubuntu 22.04 LTS, Kali Linux 2025.x |
| Scripting | Bash |

---

## Attack Simulations

Five real-world attacks were simulated across the full cyber kill chain:

| # | Attack | Tool Used | MITRE ATT&CK | Kill Chain Phase |
|:-:|:-------|:----------|:-------------|:-----------------|
| 1 | Network Reconnaissance | Nmap | T1046 | Reconnaissance |
| 2 | SSH Brute Force | Hydra | T1110.001 | Credential Access |
| 3 | Web Application Scanning | Nikto, dirb | T1190, T1595.002 | Initial Access |
| 4 | Privilege Escalation | Manual (sudo, find) | T1548.003, T1083 | Privilege Escalation |
| 5 | Data Exfiltration | Netcat | T1041 | Exfiltration |

### Kill Chain Flow

```
Reconnaissance       Initial Access        Privilege Escalation       Exfiltration
(Nmap scan)     →    (Hydra brute force) → (sudo attempts, SUID) →   (Netcat transfer)
    │                       │                       │                       │
    ▼                       ▼                       ▼                       ▼
  T1046                 T1110.001               T1548.003                T1041
```

---

## Custom Detection Rules

9 custom Wazuh rules were authored, each mapped to specific MITRE ATT&CK techniques:

| Rule ID | Attack Type | MITRE ID | Severity | Auto-Response |
|:--------|:-----------|:---------|:---------|:--------------|
| 100001 | Port Scan Detection | T1046 | Level 8 | Alert |
| 100002 | SSH Brute Force (5+ failures/60s) | T1110.001 | Level 10 | Block IP + Notify |
| 100003 | Login After Brute Force | T1110.001, T1078 | Level 14 | Disable User |
| 100004 | Directory Traversal | T1190 | Level 12 | Notify |
| 100005 | Web Vulnerability Scanning | T1595.002 | Level 10 | Alert |
| 100006 | Unauthorized Sudo Attempt | T1548.003 | Level 12 | Notify |
| 100007 | SUID Binary Enumeration | T1083 | Level 8 | Alert |
| 100008 | Netcat Execution | T1041 | Level 13 | Notify |
| 100009 | Suspicious Outbound Connection | T1041 | Level 10 | Alert |

---

## Automated Incident Response

Three active response playbooks were implemented for automatic threat containment:

### 1. IP Auto-Block (Firewall Drop)

> **Trigger:** Rule 100002 — SSH brute force detected
>
> **Action:** Adds iptables DROP rule blocking the attacker IP for 1 hour
>
> **Result:** Attacker is immediately cut off from the target machine

### 2. User Account Lockout

> **Trigger:** Rule 100003 — Successful login after brute force
>
> **Action:** Locks the compromised user account via `passwd -l` and kills all active sessions
>
> **Result:** Attacker loses access even after successful credential compromise

### 3. Enriched Alert Notification

> **Trigger:** Rules 100002, 100004, 100006, 100008 — High-severity alerts
>
> **Action:** Logs enriched alert data (timestamp, severity, MITRE ID, source IP, agent) to custom alert log
>
> **Result:** SOC analysts get immediate triage context without querying the SIEM

---

## Dashboard

Custom SOC monitoring dashboard built in the Wazuh Dashboard:

| Visualization | Type | Purpose |
|:-------------|:-----|:--------|
| Alerts by Severity | Pie Chart | Distribution of alerts across severity levels |
| Top Triggered Rules | Horizontal Bar | Most frequently firing detection rules |
| Attack Timeline | Line Chart | Alert volume over time showing attack patterns |
| Top Source IPs | Data Table | Most active attacker IP addresses |
| MITRE Techniques | Tag Cloud | Most commonly detected ATT&CK techniques |

## MITRE ATT&CK Coverage

```
┌────────────────────┬─────────────────────────────────────────────┐
│ Tactic             │ Techniques Detected                         │
├────────────────────┼─────────────────────────────────────────────┤
│ Reconnaissance     │ T1046  - Network Service Scanning           │
│                    │ T1595  - Vulnerability Scanning              │
├────────────────────┼─────────────────────────────────────────────┤
│ Initial Access     │ T1190  - Exploit Public-Facing Application  │
│                    │ T1078  - Valid Accounts                      │
├────────────────────┼─────────────────────────────────────────────┤
│ Credential Access  │ T1110  - Brute Force: Password Guessing     │
├────────────────────┼─────────────────────────────────────────────┤
│ Priv. Escalation   │ T1548  - Sudo and Sudo Caching              │
├────────────────────┼─────────────────────────────────────────────┤
│ Discovery          │ T1083  - File and Directory Discovery        │
├────────────────────┼─────────────────────────────────────────────┤
│ Exfiltration       │ T1041  - Exfiltration Over C2 Channel       │
└────────────────────┴─────────────────────────────────────────────┘
```

---

## Repository Structure

```
siem-homelab-detection-response/
│
├── README.md
├── architecture/
│   └── architecture-diagram.png
├── detection-rules/
│   └── local_rules.xml
├── active-response/
│   ├── custom-notify.sh
│   └── disable-user.sh
├── configurations/
│   ├── suricata-homelab.yaml
│   ├── audit.rules
│   └── ossec-agent.conf.example
├── attack-simulations/
│   └── attack-playbook.md
└── docs/
    └── detection-rule-mapping.md
```

---

## Setup and Reproduction

### Prerequisites

- Oracle VirtualBox 7.x
- Minimum 16GB RAM on host machine (6GB for Wazuh Server, 2GB each for Target and Kali)
- Ubuntu 22.04 Server ISO, Ubuntu 22.04 Desktop ISO, Kali Linux VirtualBox image
- 100GB free disk space

### Quick Start

1. Create three VMs on an isolated host-only network (`192.168.56.0/24`)
2. Install Wazuh 4.9 all-in-one (Manager + Indexer + Dashboard) on the server VM
3. Deploy Wazuh agent, Suricata, and auditd on the target VM
4. Import custom detection rules from [`detection-rules/local_rules.xml`](detection-rules/local_rules.xml)
5. Deploy active response scripts from [`active-response/`](active-response/)
6. Launch attack simulations from Kali following [`attack-simulations/attack-playbook.md`](attack-simulations/attack-playbook.md)

---

## Skills Demonstrated

- **Detection Engineering** — Authored custom SIEM rules with severity tuning and MITRE ATT&CK mapping
- **Incident Response** — Built automated containment playbooks reducing mean-time-to-respond
- **Network Security Monitoring** — Deployed Suricata IDS for network-level threat detection
- **Endpoint Security** — Configured auditd for system-level auditing and file integrity monitoring
- **Log Management** — Centralized multi-source log collection (syslog, Apache, Suricata, auditd) into a single SIEM
- **Threat Intelligence** — Applied MITRE ATT&CK framework for standardized threat classification
- **Security Visualization** — Built operational dashboards for real-time security monitoring
