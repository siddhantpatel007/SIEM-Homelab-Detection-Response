# Detection Rule Mapping

Complete documentation of all custom detection rules, their MITRE ATT&CK mappings, severity levels, detection logic, and automated response actions.

---

## Custom Rules Summary

| Rule ID | Attack Category | MITRE Technique | Severity | Response Action |
|---------|----------------|-----------------|----------|-----------------|
| 100001 | Reconnaissance | T1046 | Level 8 | Alert |
| 100002 | Brute Force | T1110.001 | Level 10 | Block IP (1hr) + Notify |
| 100003 | Account Compromise | T1110.001, T1078 | Level 14 | Disable User Account |
| 100004 | Web Attack | T1190 | Level 12 | Notify |
| 100005 | Web Scanning | T1595.002 | Level 10 | Alert |
| 100006 | Privilege Escalation | T1548.003 | Level 12 | Notify |
| 100007 | System Enumeration | T1083 | Level 8 | Alert |
| 100008 | Data Exfiltration | T1041 | Level 13 | Notify |
| 100009 | Suspicious Network | T1041 | Level 10 | Alert |
| 100010 | Aggressive Scanning | T1046 | Level 10 | Alert |
| 100011 | High-Volume Brute Force | T1110.001 | Level 12 | Block IP (1hr) + Notify |

---

## Detailed Rule Documentation

### Rule 100001 — Port Scan Detection

- **MITRE ATT&CK:** T1046 (Network Service Scanning)
- **Severity:** Level 8 (Medium)
- **Parent Rule:** 86601 (Suricata alert)
- **Detection Logic:** Triggers when Suricata generates an alert matching scan-related signatures
- **Log Source:** Suricata eve.json
- **Response:** Alert only

### Rule 100002 — SSH Brute Force Detection

- **MITRE ATT&CK:** T1110.001 (Brute Force: Password Guessing)
- **Severity:** Level 10 (High)
- **Parent Rule:** 5760 (sshd authentication failed)
- **Detection Logic:** Triggers when 5 or more SSH authentication failures occur within a 60-second window from the same source IP
- **Log Source:** /var/log/auth.log via syslog
- **Response:** Firewall drop (block attacker IP for 1 hour) + custom notification

### Rule 100003 — Successful Login After Brute Force

- **MITRE ATT&CK:** T1110.001 (Brute Force), T1078 (Valid Accounts)
- **Severity:** Level 14 (Critical)
- **Parent Rule:** 100002 (SSH brute force)
- **Detection Logic:** Triggers when a successful authentication event is detected from an IP that previously triggered brute force alerts — indicates the attacker cracked a password
- **Log Source:** /var/log/auth.log via syslog
- **Response:** Disable user account + kill active sessions

### Rule 100004 — Directory Traversal Attempt

- **MITRE ATT&CK:** T1190 (Exploit Public-Facing Application)
- **Severity:** Level 12 (High)
- **Parent Rule:** 31100 (Apache web server events)
- **Detection Logic:** Triggers when a web request URL contains directory traversal patterns such as `..`, `/etc/passwd`, `/etc/shadow`, or `/proc/self`
- **Log Source:** /var/log/apache2/access.log
- **Response:** Custom notification

### Rule 100005 — Web Vulnerability Scanning

- **MITRE ATT&CK:** T1595.002 (Active Scanning: Vulnerability Scanning)
- **Severity:** Level 10 (High)
- **Parent Rule:** 31100 (Apache web server events)
- **Detection Logic:** Triggers when 30 or more web server events occur within a 60-second window from the same source — indicates automated scanning
- **Log Source:** /var/log/apache2/access.log
- **Response:** Alert only

### Rule 100006 — Unauthorized Sudo Attempt

- **MITRE ATT&CK:** T1548.003 (Abuse Elevation Control: Sudo and Sudo Caching)
- **Severity:** Level 12 (High)
- **Parent Rule:** 5405 (Unauthorized user attempted sudo)
- **Detection Logic:** Triggers when a user not in the sudoers file attempts to use sudo
- **Log Source:** /var/log/auth.log via syslog
- **Response:** Custom notification

### Rule 100007 — SUID Binary Enumeration

- **MITRE ATT&CK:** T1083 (File and Directory Discovery)
- **Severity:** Level 8 (Medium)
- **Parent Rule:** 80700 (auditd events)
- **Detection Logic:** Triggers when auditd logs an event tagged with the `recon` key, indicating execution of enumeration tools like `find`, `whoami`, `id`, or `uname`
- **Log Source:** /var/log/audit/audit.log
- **Response:** Alert only

### Rule 100008 — Netcat Execution (Data Exfiltration)

- **MITRE ATT&CK:** T1041 (Exfiltration Over C2 Channel)
- **Severity:** Level 13 (High)
- **Parent Rule:** 80700 (auditd events)
- **Detection Logic:** Triggers when auditd logs the execution of `nc`, `ncat`, or `netcat` tagged with the `suspicious_tool` key
- **Log Source:** /var/log/audit/audit.log
- **Response:** Custom notification

### Rule 100009 — Suspicious Outbound Network Connection

- **MITRE ATT&CK:** T1041 (Exfiltration Over C2 Channel)
- **Severity:** Level 10 (High)
- **Parent Rule:** 80700 (auditd events)
- **Detection Logic:** Triggers when auditd logs an outbound network connection event tagged with the `network_connect` key
- **Log Source:** /var/log/audit/audit.log
- **Response:** Alert only

### Rule 100010 — Aggressive Network Scanning

- **MITRE ATT&CK:** T1046 (Network Service Scanning)
- **Severity:** Level 10 (High)
- **Parent Rule:** 86601 (Suricata alert)
- **Detection Logic:** Triggers when 15 or more Suricata scan alerts occur within a 2-minute window — indicates aggressive or comprehensive port scanning
- **Log Source:** Suricata eve.json
- **Response:** Alert only

### Rule 100011 — High-Volume SSH Brute Force

- **MITRE ATT&CK:** T1110.001 (Brute Force: Password Guessing)
- **Severity:** Level 12 (High)
- **Parent Rule:** 5760 (sshd authentication failed)
- **Detection Logic:** Triggers when 10 or more SSH authentication failures occur within a 2-minute window — indicates a sustained automated brute force attack
- **Log Source:** /var/log/auth.log via syslog
- **Response:** Firewall drop (block attacker IP for 1 hour) + custom notification

---

## MITRE ATT&CK Coverage Map

```
┌──────────────────────────────────────────────────────────────────┐
│                     MITRE ATT&CK COVERAGE                        │
├──────────────────┬───────────────────────────────────────────────┤
│ Tactic           │ Techniques Detected                           │
├──────────────────┼───────────────────────────────────────────────┤
│ Reconnaissance   │ T1046 (Network Service Scanning)              │
│                  │ T1595.002 (Vulnerability Scanning)            │
├──────────────────┼───────────────────────────────────────────────┤
│ Initial Access   │ T1190 (Exploit Public-Facing Application)     │
│                  │ T1078 (Valid Accounts)                        │
├──────────────────┼───────────────────────────────────────────────┤
│ Credential Access│ T1110.001 (Brute Force: Password Guessing)    │
├──────────────────┼───────────────────────────────────────────────┤
│ Priv. Escalation │ T1548.003 (Sudo and Sudo Caching)            │
├──────────────────┼───────────────────────────────────────────────┤
│ Discovery        │ T1083 (File and Directory Discovery)          │
├──────────────────┼───────────────────────────────────────────────┤
│ Exfiltration     │ T1041 (Exfiltration Over C2 Channel)         │
└──────────────────┴───────────────────────────────────────────────┘
```

---

## Log Sources and Detection Layers

| Log Source | What It Captures | Feeds Into |
|-----------|-----------------|------------|
| /var/log/auth.log | SSH logins, sudo attempts, PAM events | Wazuh Agent → Manager |
| /var/log/apache2/access.log | Web server requests, HTTP status codes | Wazuh Agent → Manager |
| /var/log/apache2/error.log | Web server errors, misconfigurations | Wazuh Agent → Manager |
| /var/log/suricata/eve.json | Network-level IDS alerts, flow data | Wazuh Agent → Manager |
| /var/log/audit/audit.log | System calls, file access, command execution | Wazuh Agent → Manager |

---

## Severity Level Guide

| Level | Classification | Description | Example |
|-------|---------------|-------------|---------|
| 8 | Medium | Suspicious activity requiring investigation | Port scan, SUID enumeration |
| 10 | High | Confirmed malicious activity | Brute force attack, web scanning |
| 12 | High | Active attack with potential for damage | Directory traversal, unauthorized sudo |
| 13 | High | Dangerous tool usage in a sensitive context | Netcat execution on production system |
| 14 | Critical | Confirmed compromise requiring immediate action | Successful login after brute force |