#!/bin/bash
set -x
# ================= CONFIG =================
MAIL_TO="mohitpar128@gmail.com"
HOST=$(hostname)
DATE=$(date +"%Y-%m-%d %H:%M:%S")

# Thresholds
DISK_CRIT=85
DISK_WARN=75

MEM_CRIT=85
MEM_WARN=70

LOAD_CRIT=3.0
LOAD_WARN=2.0

# State & rate-limit files
STATE_FILE="/var/tmp/system_health_state"
MAIL_RATE_FILE="/var/tmp/last_health_mail"
MAIL_INTERVAL=3600   # 1 hour

# Telegram secrets
source ~/.tg_secrets

CRITICAL=""
WARNING=""
# =========================================


# -------- Previous State --------
PREV_STATE="OK"
[ -f "$STATE_FILE" ] && PREV_STATE=$(cat "$STATE_FILE")


# -------- Disk Check --------
DISK=$(df -h / | awk 'NR==2 {gsub("%",""); print $5}')
if (( DISK >= DISK_CRIT )); then
  CRITICAL+="❌ Disk CRITICAL: ${DISK}%\n"
elif (( DISK >= DISK_WARN )); then
  WARNING+="⚠ Disk WARNING: ${DISK}%\n"
fi


# -------- Memory Check --------
MEM=$(free -m | awk 'NR==2 {printf "%.0f", $3/$2*100}')
if (( MEM >= MEM_CRIT )); then
  CRITICAL+="❌ Memory CRITICAL: ${MEM}%\n"
elif (( MEM >= MEM_WARN )); then
  WARNING+="⚠ Memory WARNING: ${MEM}%\n"
fi


# -------- Load Check --------
LOAD=$(awk '{print $1}' /proc/loadavg)
if (( $(echo "$LOAD >= $LOAD_CRIT" | bc) )); then
  CRITICAL+="❌ Load CRITICAL: ${LOAD}\n"
elif (( $(echo "$LOAD >= $LOAD_WARN" | bc) )); then
  WARNING+="⚠ Load WARNING: ${LOAD}\n"
fi


# -------- Decide Current State --------
CURR_STATE="OK"
[[ -n "$CRITICAL" ]] && CURR_STATE="CRITICAL"
[[ -z "$CRITICAL" && -n "$WARNING" ]] && CURR_STATE="WARNING"


# -------- Telegram (CRITICAL only) --------
send_telegram() {
  curl -s -X POST "https://api.telegram.org/bot${TG_BOT_TOKEN}/sendMessage" \
    -d chat_id="${TG_CHAT_ID}" \
    -d text="$1" >/dev/null
}


# -------- Email via Postfix --------
send_mail() {
  {
    echo "Host : $HOST"
    echo "Time : $DATE"
    echo
    echo "==== CRITICAL ===="
    echo -e "$CRITICAL"
    echo "==== WARNING ===="
    echo -e "$WARNING"
    echo
    echo "==== Disk Usage ===="
    df -h
  } | mail -s "🚨 System Health Alert on $HOST" "$MAIL_TO"
}


# -------- Recovery Mail --------
send_recovery_mail() {
  {
    echo "✅ System RECOVERED"
    echo
    echo "Host : $HOST"
    echo "Time : $DATE"
    echo
    echo "All parameters are back to normal."
    echo
    df -h
  } | mail -s "✅ RECOVERY: System Healthy on $HOST" "$MAIL_TO"
}


# -------- Recovery Logic --------
if [[ "$PREV_STATE" != "OK" && "$CURR_STATE" == "OK" ]]; then
  send_recovery_mail
  echo "OK" > "$STATE_FILE"
  exit 0
fi


# -------- Rate-limit Mail --------
NOW=$(date +%s)
LAST_MAIL=0
[ -f "$MAIL_RATE_FILE" ] && LAST_MAIL=$(cat "$MAIL_RATE_FILE")


# -------- Alert Logic --------

# Telegram only on NEW CRITICAL
if [[ "$CURR_STATE" == "CRITICAL" && "$PREV_STATE" != "CRITICAL" ]]; then
  TG_MSG="🚨 CRITICAL SYSTEM ALERT

Host: $HOST
Time: $DATE

$CRITICAL"
  send_telegram "$TG_MSG"
fi

# Email (CRITICAL or WARNING, rate-limited)
if [[ "$CURR_STATE" != "OK" ]]; then
  if (( NOW - LAST_MAIL >= MAIL_INTERVAL )); then
    send_mail
    echo "$NOW" > "$MAIL_RATE_FILE"
  fi
fi


# -------- Save State --------
echo "$CURR_STATE" > "$STATE_FILE"
