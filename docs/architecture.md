# Architecture Documentation

## Overview

This project implements a classic **three-tier architecture** on AWS, automated end-to-end with **Terraform** for infrastructure and **GitHub Actions + AWS Step Functions** for CI/CD.

```
Internet
   │
   ▼
[Web ALB]  ← public subnets (AZ-a, AZ-b)
   │
   ▼
[Web EC2 ASG]  ← Nginx, serves React SPA
   │  /api/*
   ▼
[App ALB]  ← private subnets (internal)
   │
   ▼
[App EC2 ASG]  ← Node.js Express REST API
   │
   ▼
[Amazon RDS MySQL]  ← DB subnets (multi-AZ)
```

## Tiers

| Tier | Technology | Subnet | HA Strategy |
|------|-----------|--------|-------------|
| Web  | Nginx + React | Public (2 AZs) | ASG + ALB |
| App  | Node.js + Express | Private (2 AZs) | ASG + internal ALB |
| Data | Amazon RDS MySQL 8.0 | DB subnets (2 AZs) | Multi-AZ standby |

## CI/CD Pipeline

```
git push → main
   │
   ▼
[GitHub Actions]
   ├── Job 1: terraform apply   (provision/update infra)
   ├── Job 2: build & upload    (zip artifacts → S3)
   └── Job 3: trigger SFN       (start Step Function)

[AWS Step Functions]
   ├── DeployAppTier  (Lambda → SSM RunCommand on app EC2s)
   ├── WaitForAppHealthy (60s wait)
   ├── CheckAppHealth (Lambda → ASG health check)
   ├── DeployWebTier  (Lambda → SSM RunCommand on web EC2s)
   ├── WaitForWebHealthy (60s wait)
   └── CheckWebHealth (Lambda → ASG health check)
```

## GitHub Secrets Required

| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | IAM access key with deploy permissions |
| `AWS_SECRET_ACCESS_KEY` | Corresponding secret key |
| `STEPFUNCTION_ARN` | ARN of the deployed Step Function |
| `DB_PASSWORD` | RDS master password (passed as TF var) |

## Key Design Decisions

- **No bastion host** — all EC2 management done via SSM Session Manager
- **Artifacts in S3** — both tiers built once, deployed to N instances via SSM
- **Step Function orchestration** — deploy app tier first (backend ready before frontend), with health checks between stages
- **Blue/green capable** — ASG launch templates make rolling/blue-green upgrades straightforward
