#!/bin/bash
# deploy-app.sh  –  Pull latest artifact from S3 and restart the app service
set -euo pipefail

S3_BUCKET="${S3_BUCKET:-three-tier-artifacts}"
ARTIFACT="app-tier.zip"
DEPLOY_DIR="/opt/app"

echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] Deploying app tier..."

aws s3 cp "s3://${S3_BUCKET}/${ARTIFACT}" "/tmp/${ARTIFACT}"
unzip -o "/tmp/${ARTIFACT}" -d "${DEPLOY_DIR}"
cd "${DEPLOY_DIR}"
npm install --production
systemctl restart app

echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] App tier deployment complete."
