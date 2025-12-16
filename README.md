```
linux-system-health-monitor
```

---

# 🖥️ Linux System Health Monitoring (Production-Style)

A **production-inspired system health monitoring solution** built on **Rocky Linux** using **Bash, systemd timers, Telegram, and Email alerts**.

This project focuses on **alert quality, severity-based routing, and noise reduction**, instead of basic “print everything” scripts.

---

## 🎯 Project Goals

Most beginner monitoring scripts:

* Spam alerts
* Alert for non-critical issues
* Rely only on cron
* Become ignored over time

This project was built to:

* Send **alerts only when action is required**
* Separate **CRITICAL vs WARNING** conditions
* Use **Telegram for real-time incidents**
* Use **Email as an audit trail**
* Run reliably using **systemd timers**

---

## 🔧 Features

* ✅ Disk usage monitoring
* ✅ Memory usage monitoring
* ✅ Load average monitoring
* 🚨 **CRITICAL alerts → Telegram group**
* 📧 **Email alerts (rate-limited to once per hour)**
* 📊 `df -h` output attached in email
* 🔐 Secure secrets handling (no hardcoded tokens)
* ⏱️ Uses **systemd timers** instead of cron
* 📉 Prevents alert fatigue

---

## 🧠 Alert Design Logic

| Severity | Action               |
| -------- | -------------------- |
| OK       | No alert             |
| WARNING  | Email (rate-limited) |
| CRITICAL | Telegram + Email     |

Telegram is used for **instant incident visibility**, while email is used for **logging and reporting**.

---

## 🧩 Script Overview

The script classifies system state into two buckets:

```bash
CRITICAL=""
WARNING=""
```

Example logic:

```bash
if (( DISK >= 85 )); then
  CRITICAL+="Disk usage CRITICAL: ${DISK}%\n"
elif (( DISK >= 75 )); then
  WARNING+="Disk usage WARNING: ${DISK}%\n"
fi
```

This approach makes the script:

* Easy to extend
* Easy to route alerts
* Similar to real monitoring tools

---

## 📱 Telegram Alerts (CRITICAL Only)

Telegram is used for real-time alerts via a bot.

```bash
send_telegram() {
  curl -s -X POST "https://api.telegram.org/bot${TG_BOT_TOKEN}/sendMessage" \
    -d chat_id="${TG_CHAT_ID}" \
    -d text="$1"
}
```

Telegram messages are sent **only for CRITICAL conditions**.

---

## 📧 Email Alerts (Rate-Limited)

To avoid alert spam, email alerts are limited to **once per hour** using a timestamp file:

```bash
MAIL_RATE_FILE="/var/tmp/last_health_mail"
MAIL_INTERVAL=3600
```

Emails include:

* CRITICAL issues
* WARNING issues
* `df -h` output for context

---

## 🔐 Secure Secrets Handling

Secrets are stored outside the script:

```bash
~/.tg_secrets
```

```bash
TG_BOT_TOKEN="YOUR_BOT_TOKEN"
TG_CHAT_ID="-100XXXXXXXXXX"
```

Permissions:

```bash
chmod 600 ~/.tg_secrets
```

---

## ⏱️ Scheduling with systemd Timer

Instead of cron, this project uses a **systemd timer** for better reliability.

### system-health.timer

```ini
[Timer]
OnBootSec=2min
OnUnitActiveSec=5min
Persistent=true
```

Benefits:

* Survives reboots
* Integrated logging
* Better error visibility

---

## 🚀 Installation & Usage

### 1️⃣ Clone the repo

```bash
git clone https://github.com/yourusername/linux-system-health-monitor.git
cd linux-system-health-monitor
```

### 2️⃣ Install dependencies

```bash
sudo dnf install -y bc curl msmtp
```

### 3️⃣ Configure secrets

```bash
nano ~/.tg_secrets
chmod 600 ~/.tg_secrets
```

### 4️⃣ Install script

```bash
sudo cp system_health.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/system_health.sh
```

### 5️⃣ Enable systemd timer

```bash
sudo cp system-health.service /etc/systemd/system/
sudo cp system-health.timer /etc/systemd/system/

sudo systemctl daemon-reload
sudo systemctl enable --now system-health.timer
```

---

## 🧪 Testing

To test alerts safely:

* Temporarily force a CRITICAL value inside the script
* Run the script manually
* Verify Telegram + Email delivery

---

## 📚 Learning Outcomes

This project helped reinforce:

* Bash scripting best practices
* Linux system monitoring fundamentals
* Alert fatigue prevention
* systemd timers vs cron
* Secure secret management
* Production-style thinking

---

## 🔮 Possible Improvements

* CPU temperature monitoring
* Network latency checks
* Prometheus-style metrics output
* Ansible role packaging
* Kubernetes node monitoring

---

## 📌 Disclaimer

This project is intended for **learning and demonstration purposes**, inspired by real production monitoring patterns.

---

## 🤝 Contributions

Suggestions, improvements, and feedback are welcome.

---

