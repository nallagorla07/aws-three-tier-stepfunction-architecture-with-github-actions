#!/bin/bash
set -e

yum update -y
yum install -y nodejs npm aws-cli unzip

# Pull app-tier artifact from S3
aws s3 cp s3://${s3_bucket}/app-tier.zip /tmp/app-tier.zip
mkdir -p /opt/app
unzip -o /tmp/app-tier.zip -d /opt/app/

cd /opt/app
npm install --production

# Inject DB connection via env
cat > /etc/systemd/system/app.service << UNIT
[Unit]
Description=Three-Tier App Server
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/app
ExecStart=/usr/bin/node server.js
Restart=on-failure
Environment=PORT=8080
Environment=DB_HOST=${db_endpoint}
Environment=DB_USER=${db_username}
Environment=DB_PASS=${db_password}
Environment=DB_NAME=${db_name}

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable app
systemctl start app
