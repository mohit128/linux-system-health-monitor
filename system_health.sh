#!/bin/bash

# ================= CONFIG =================
MAIL_TO="mohitpar128@gmail.com"
HOST=$(hostname)
DATE=$(date +"%Y-%m-%d %H:%M:%S")

DISK_CRIT=85
MEM_CRIT=85
LOAD_CRIT=3.0

DISK_WARN=75
MEM_WARN=70
LOAD_WARN=2.0

MAIL_RATE_FILE="/var/tmp/last_health_mail"
MAIL_INTERVAL=3600   # 1 hour

source ~/.tg_secrets

CRITICAL=""
WARNING=""
# =========================================

# -------- Disk --------
DISK=$(df -h / | awk 'NR==2 {gsub("%",""); print $5}')
if (( DISK >= DISK_CRIT )); then
  CRITICAL+="❌ Disk CRITICAL: ${DISK}%\n"
elif (( DISK >= DISK_WARN )); then
  WARNING+="⚠ Disk warning: ${DISK}%\n"
fi

# -------- Memory --------
MEM=$(free -m | awk 'NR==2 {printf "%.0f", $3/$2*100}')
if (( MEM >= MEM_CRIT )); then
  CRITICAL+="❌ Memory CRITICAL: ${MEM}%\n"
elif (( MEM >= MEM_WARN )); then
  WARNING+="⚠ Memory warning: ${MEM}%\n"
fi

# -------- Load --------
LOAD=$(awk '{print $1}' /proc/loadavg)
if (( $(echo "$LOAD >= $LOAD_CRIT" | bc) )); then
  CRITICAL+="❌ Load CRITICAL: ${LOAD}\n"
elif (( $(echo "$LOAD >= $LOAD_WARN" | bc) )); then
  WARNING+="⚠ Load warning: ${LOAD}\n"
fi

# -------- Telegram (CRITICAL ONLY) --------
send_telegram() {
  curl -s -X POST "https://api.telegram.org/bot${TG_BOT_TOKEN}/sendMessage" \
    -d chat_id="${TG_CHAT_ID}" \
    -d text="$1"
}

# -------- Email (Rate-limited) --------
send_mail() {
{
  echo "Subject: 🚨 System Health Alert on $HOST"
  echo
  echo "Host : $HOST"
  echo "Time : $DATE"
  echo
  echo "==== CRITICAL ===="
  echo -e "$CRITICAL"
  echo "==== WARNING ===="
  echo -e "$WARNING"
  echo
  echo "==== df -h output ===="
  df -h
} | msmtp "$MAIL_TO"
}

NOW=$(date +%s)
LAST_MAIL=0
[ -f "$MAIL_RATE_FILE" ] && LAST_MAIL=$(cat "$MAIL_RATE_FILE")

# -------- ACTION LOGIC --------
if [[ -n "$CRITICAL" ]]; then
  TG_MSG="🚨 *CRITICAL SYSTEM ALERT*\n\nHost: $HOST\nTime: $DATE\n\n$CRITICAL"
  send_telegram "$TG_MSG"
fi

if [[ -n "$CRITICAL" || -n "$WARNING" ]]; then
  if (( NOW - LAST_MAIL >= MAIL_INTERVAL )); then
    send_mail
    echo "$NOW" > "$MAIL_RATE_FILE"
  fi
fi

