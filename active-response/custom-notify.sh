#!/bin/bash

# ============================================
# Wazuh Active Response: Alert Notification
# Logs enriched alert data for SOC review
# ============================================

LOG_FILE="/var/log/wazuh-custom-alerts.log"

# Read alert JSON from STDIN
read INPUT_JSON

# Extract fields using jq
ALERT_MSG=$(echo "$INPUT_JSON" | jq -r '.parameters.alert.rule.description // "N/A"')
RULE_ID=$(echo "$INPUT_JSON" | jq -r '.parameters.alert.rule.id // "N/A"')
SEVERITY=$(echo "$INPUT_JSON" | jq -r '.parameters.alert.rule.level // "N/A"')
SRC_IP=$(echo "$INPUT_JSON" | jq -r '.parameters.alert.data.srcip // "N/A"')
MITRE_ID=$(echo "$INPUT_JSON" | jq -r '.parameters.alert.rule.mitre.id[0] // "N/A"')
AGENT=$(echo "$INPUT_JSON" | jq -r '.parameters.alert.agent.name // "N/A"')
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Write enriched alert to log
echo "================================================================" >> "$LOG_FILE"
echo "TIMESTAMP:  $TIMESTAMP" >> "$LOG_FILE"
echo "SEVERITY:   Level $SEVERITY" >> "$LOG_FILE"
echo "RULE:       $RULE_ID" >> "$LOG_FILE"
echo "MITRE:      $MITRE_ID" >> "$LOG_FILE"
echo "SOURCE IP:  $SRC_IP" >> "$LOG_FILE"
echo "AGENT:      $AGENT" >> "$LOG_FILE"
echo "ALERT:      $ALERT_MSG" >> "$LOG_FILE"
echo "================================================================" >> "$LOG_FILE"

exit 0