```
linux-system-health-monitor
```

---


# 🖥️ Linux System Health Monitoring (Production-Style)

A production-inspired Linux system health monitoring solution built on **Rocky Linux** using:

* 🐚 Bash
* ⏰ Cron Job Scheduler
* 📱 Telegram Bot API
* 📧 Postfix (Gmail SMTP relay)

This project focuses on **alert quality, severity-based routing, state transitions, and noise reduction**, instead of basic monitoring scripts that spam alerts.

---

# 🎯 Project Objectives

Most beginner monitoring scripts:

* ❌ Send repeated alerts
* ❌ Do not classify severity
* ❌ Ignore state transitions
* ❌ Cause alert fatigue

This project was designed to:

* ✅ Send alerts only when required
* ✅ Separate **CRITICAL / WARNING / OK** states
* ✅ Send Telegram alerts for real-time incidents
* ✅ Use Email as an audit trail
* ✅ Detect recovery events
* ✅ Prevent duplicate alerts
* ✅ Run automatically using cron

---

# 🔧 Features

* ✅ Disk usage monitoring
* ✅ Memory usage monitoring
* ✅ Load average monitoring
* 🚨 Telegram alerts (CRITICAL only)
* 📧 Email alerts via Postfix (rate-limited to once per hour)
* 📊 `df -h` output included in email
* 🔐 Secure secrets handling (no hardcoded tokens)
* 📉 Alert fatigue prevention using state tracking
* ⏰ Automated execution via cron

---

# 🧠 Alert Design Logic

The script dynamically classifies system state:

```bash
CRITICAL=""
WARNING=""
```

### Example Disk Logic

```bash
if (( DISK >= DISK_CRIT )); then
  CRITICAL+="❌ Disk CRITICAL: ${DISK}%\n"
elif (( DISK >= DISK_WARN )); then
  WARNING+="⚠ Disk WARNING: ${DISK}%\n"
fi
```

---

# 🔄 State-Based Alerting

The script tracks previous system state using:

```
/var/tmp/system_health_state
```

Example:

```bash
STATE_FILE="/var/tmp/system_health_state"
PREV_STATE=$(cat "$STATE_FILE" 2>/dev/null || echo "OK")
```

### State Transition Behavior

| Previous            | Current            | Action |
| ------------------- | ------------------ | ------ |
| OK → CRITICAL       | Telegram + Email   |        |
| CRITICAL → OK       | Recovery Email     |        |
| CRITICAL → CRITICAL | No duplicate alert |        |
| WARNING → WARNING   | No duplicate alert |        |

This ensures:

* No Telegram spam
* Alerts only on meaningful transitions
* Recovery detection

---

# 📱 Telegram Alerts (CRITICAL Only)

Telegram is used for real-time alerting.

```bash
send_telegram() {
  curl -s -X POST "https://api.telegram.org/bot${TG_BOT_TOKEN}/sendMessage" \
    -d chat_id="${TG_CHAT_ID}" \
    --data-urlencode text="$1"
}
```

Telegram triggers only when entering a new CRITICAL state.

---

# 📧 Email Alerts (Postfix Gmail Relay)

This project uses **Postfix configured as a Gmail SMTP relay**.

### Why Postfix?

* Production-grade MTA
* SMTP retry support
* Reliable queue handling
* System-integrated mail service

### Email Rate Limiting

```bash
MAIL_RATE_FILE="/var/tmp/last_health_mail"
MAIL_INTERVAL=3600
```

Emails include:

* CRITICAL issues
* WARNING issues
* Hostname & timestamp
* Full `df -h` output

Example:

```bash
} | mail -s "🚨 System Health Alert on $HOST" "$MAIL_TO"
```

---

# 🔐 Secure Secrets Handling

Telegram credentials are stored outside the script:

```
~/.tg_secrets
```

Example:

```bash
TG_BOT_TOKEN="YOUR_BOT_TOKEN"
TG_CHAT_ID="-100XXXXXXXXXX"
```

Set permissions:

```bash
chmod 600 ~/.tg_secrets
```

---

# ⏰ Automation Using Cron

The script runs automatically using a cron job.

### Example: Run Every 5 Minutes

```bash
crontab -e
```

Add:

```bash
*/5 * * * * /usr/local/bin/system_health.sh >> /var/log/system_health.log 2>&1
```

### Benefits

* Lightweight
* Simple to configure
* Works on all Linux distributions
* Easy log tracking

---

# 🏗️ Architecture Flow

```
cron (every 5 min)
        ↓
system_health.sh
        ↓
Evaluate Disk / Memory / Load
        ↓
Determine State (OK / WARNING / CRITICAL)
        ↓
Telegram (CRITICAL only)
        ↓
Postfix Email (rate-limited)
        ↓
Update state file
```

---

# 🚀 Installation Guide

## 1️⃣ Clone Repository

```bash
git clone https://github.com/yourusername/linux-system-health-monitor.git
cd linux-system-health-monitor
```

---

## 2️⃣ Install Dependencies

```bash
sudo dnf install -y bc curl postfix mailx
```

---

## 3️⃣ Configure Postfix (Gmail Relay)

Edit:

```
/etc/postfix/main.cf
```

Configure Gmail SMTP relay with App Password.

Restart:

```bash
sudo systemctl restart postfix
```

---

## 4️⃣ Configure Telegram Secrets

```bash
nano ~/.tg_secrets
chmod 600 ~/.tg_secrets
```

---

## 5️⃣ Install Script

```bash
sudo cp system_health.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/system_health.sh
```

---

## 6️⃣ Configure Cron

```bash
crontab -e
```

Add:

```bash
*/5 * * * * /usr/local/bin/system_health.sh >> /var/log/system_health.log 2>&1
```

---

# 🧪 Testing

To test alerts safely:

1. Temporarily lower threshold values
2. Run script manually
3. Verify Telegram + Email delivery
4. Restore thresholds

---

# 📚 Learning Outcomes

This project demonstrates:

* Production-style alert design
* Bash scripting best practices
* State-based monitoring logic
* SMTP relay configuration with Postfix
* Cron automation
* Alert fatigue prevention
* Secure secret management

---

# 🔮 Future Improvements

* CPU temperature monitoring
* Network latency checks
* Multi-mount disk monitoring
* Prometheus-compatible metrics
* Ansible role packaging
* Docker container version

---


## 🤝 Contributions

Suggestions, improvements, and feedback are welcome.

---

## 📄 License
This project is licensed under the MIT License.
