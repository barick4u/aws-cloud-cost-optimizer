# AWS Cloud Cost Optimizer 🧠💸

Tired of surprise AWS bills? This script helps you:

✅ Scan **all regions and profiles**  
✅ Detect **underutilized EC2 instances** (low avg CPU usage)  
✅ Find **unused EBS volumes**  
✅ 📩 Email you a detailed cleanup report

Works in **Dry Run mode by default** – no actual actions unless you allow.

---

## 🛠 Requirements

- AWS CLI configured (`~/.aws/credentials`)
- `jq` installed (for JSON parsing)
- Python 3 (for sending email via SMTP)

---

## ⚙️ How It Works

- Loops through all AWS regions and profiles
- Fetches EC2 CPU metrics via CloudWatch (7-day avg)
- Flags instances with < 5% usage
- Lists unattached EBS volumes
- Sends report via Gmail SMTP

---

📧 How to Enable Gmail Email Alerts

To send email reports, you’ll need a Gmail App Password (not your normal password).

🔐 Steps to generate:
	1.	Visit 👉 https://myaccount.google.com/apppasswords
	2.	Complete 2-Step Verification if not already done
	3.	In the App dropdown, select: Mail
	4.	In the Device dropdown, choose: Other → name it AWS Cleaner
	5.	Copy the generated 16-digit password
	6.	In the script, replace the password section:
		```APP_PASSWORD = "your_16_digit_app_password"```
🛑 Important Notes
	•	Do not use your normal Gmail password
	•	App Passwords work only when 2FA is enabled
	•	You can revoke this password anytime via Google Account settings
------

## 🚀 Getting Started

```bash
chmod +x aws_cloud_cleanup.sh
./aws_cloud_cleanup.sh
