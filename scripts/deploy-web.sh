#!/bin/bash
# deploy-web.sh  –  Pull latest artifact from S3 and reload Nginx
set -euo pipefail

S3_BUCKET="${S3_BUCKET:-three-tier-artifacts}"
ARTIFACT="web-tier.zip"
DEPLOY_DIR="/usr/share/nginx/html"

echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] Deploying web tier..."

aws s3 cp "s3://${S3_BUCKET}/${ARTIFACT}" "/tmp/${ARTIFACT}"
unzip -o "/tmp/${ARTIFACT}" -d "${DEPLOY_DIR}"
nginx -t && systemctl reload nginx

echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] Web tier deployment complete."
