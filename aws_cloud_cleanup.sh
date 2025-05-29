#!/bin/bash

# CONFIG
PROFILES=("default")
REGIONS=$(aws ec2 describe-regions --output text | cut -f4)
REPORT_FILE="/tmp/cloud_report.txt"
EMAIL_FROM="your@email.com"
EMAIL_TO="team@email.com"
APP_PASSWORD="your_app_password"  # Gmail App Password
DRY_RUN=true  # ✅ Set to false for real actions

# INIT REPORT
echo "🧾 AWS Cloud Cleanup Report - $(date)" > "$REPORT_FILE"

for PROFILE in "${PROFILES[@]}"; do
  echo -e "\n🔐 Profile: $PROFILE" >> "$REPORT_FILE"

  for REGION in $REGIONS; do
    echo -e "\n🌍 Region: $REGION" >> "$REPORT_FILE"

    INSTANCES=$(aws ec2 describe-instances \
      --profile "$PROFILE" --region "$REGION" \
      --query "Reservations[].Instances[?State.Name=='running'].InstanceId[]" \
      --output text)

    for INSTANCE_ID in $INSTANCES; do
      CPU=$(aws cloudwatch get-metric-statistics \
        --profile "$PROFILE" --region "$REGION" \
        --metric-name CPUUtilization \
        --start-time $(date -u -d '-7 days' +%Y-%m-%dT%H:%M:%SZ) \
        --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
        --period 86400 --statistics Average \
        --namespace AWS/EC2 \
        --dimensions Name=InstanceId,Value=$INSTANCE_ID \
        --output json | jq '[.Datapoints[].Average] | add / length')

      if [[ ! -z "$CPU" && $(echo "$CPU < 5" | bc) -eq 1 ]]; then
        if [[ "$DRY_RUN" = true ]]; then
          echo "🧪 Would stop instance: $INSTANCE_ID (Avg CPU: $CPU%)" >> "$REPORT_FILE"
        else
          echo "🛑 Stopping instance: $INSTANCE_ID (Avg CPU: $CPU%)" >> "$REPORT_FILE"
          aws ec2 stop-instances --instance-ids "$INSTANCE_ID" \
            --profile "$PROFILE" --region "$REGION"
        fi
      fi
    done

    UNUSED_VOLS=$(aws ec2 describe-volumes \
      --profile "$PROFILE" --region "$REGION" \
      --filters Name=status,Values=available \
      --query "Volumes[*].VolumeId" --output text)

    for VOL in $UNUSED_VOLS; do
      if [[ "$DRY_RUN" = true ]]; then
        echo "🧪 Would delete EBS volume: $VOL" >> "$REPORT_FILE"
      else
        echo "🛑 Deleting EBS volume: $VOL" >> "$REPORT_FILE"
        aws ec2 delete-volume --volume-id "$VOL" \
          --profile "$PROFILE" --region "$REGION"
      fi
    done
  done
done

# EMAIL REPORT
python3 - <<EOF
import smtplib
from email.message import EmailMessage

msg = EmailMessage()
msg["Subject"] = "AWS Cloud Cleanup Report"
msg["From"] = "$EMAIL_FROM"
msg["To"] = "$EMAIL_TO"

with open("$REPORT_FILE") as f:
    msg.set_content(f.read())

with smtplib.SMTP_SSL("smtp.gmail.com", 465) as smtp:
    smtp.login("$EMAIL_FROM", "$APP_PASSWORD")
    smtp.send_message(msg)

print("✅ Email sent to $EMAIL_TO")
EOF
