#!/bin/bash

# ============================================
# Wazuh Active Response: Disable Compromised User
# Locks user account and kills all sessions
# ============================================

LOG_FILE="/var/log/wazuh-response-actions.log"

read INPUT_JSON

USER=$(echo "$INPUT_JSON" | jq -r '.parameters.alert.data.dstuser // .parameters.alert.data.srcuser // "unknown"')
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
RULE_ID=$(echo "$INPUT_JSON" | jq -r '.parameters.alert.rule.id // "N/A"')

# Safety check — never disable root or system users
if [ "$USER" != "unknown" ] && [ "$USER" != "root" ] && [ "$USER" != "wazuh" ]; then
    # Lock the account
    passwd -l "$USER" 2>/dev/null

    # Kill all user sessions
    pkill -u "$USER" 2>/dev/null

    echo "[$TIMESTAMP] AUTOMATED RESPONSE: Account '$USER' LOCKED and sessions KILLED (triggered by rule $RULE_ID)" >> "$LOG_FILE"
else
    echo "[$TIMESTAMP] AUTOMATED RESPONSE: Skipped — user '$USER' is protected or unknown" >> "$LOG_FILE"
fi

exit 0