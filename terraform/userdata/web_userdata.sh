#!/bin/bash
set -e

yum update -y
yum install -y nginx aws-cli unzip

# Pull web-tier artifact from S3
aws s3 cp s3://${s3_bucket}/web-tier.zip /tmp/web-tier.zip
unzip -o /tmp/web-tier.zip -d /usr/share/nginx/html/

# Configure Nginx reverse proxy to internal app ALB
cat > /etc/nginx/conf.d/app.conf << NGINX
server {
    listen 80;
    server_name _;

    root /usr/share/nginx/html;
    index index.html;

    location /api/ {
        proxy_pass http://${app_alb_dns}/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
NGINX

systemctl enable nginx
systemctl start nginx
