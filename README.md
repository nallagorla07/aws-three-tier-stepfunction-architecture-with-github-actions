# AWS Three-Tier Architecture with Step Functions & GitHub Actions

A production-ready three-tier AWS architecture (Web → App → Data) provisioned by **Terraform** and deployed end-to-end via **GitHub Actions + AWS Step Functions**.

```
Internet → Web ALB → Nginx EC2 ASG → App ALB (internal) → Node.js EC2 ASG → RDS MySQL
```

---

## Repository Structure

```
.
├── terraform/                  # All infrastructure-as-code
│   ├── provider.tf
│   ├── versions.tf
│   ├── variables.tf
│   ├── vpc.tf                  # VPC, subnets, IGW, NAT, route tables
│   ├── security_groups.tf
│   ├── iam.tf                  # EC2 instance profile, Lambda role, SFN role
│   ├── ec2_asg.tf              # ALBs, Launch Templates, Auto Scaling Groups
│   ├── rds.tf                  # Multi-AZ RDS MySQL
│   ├── s3.tf                   # Artifact bucket
│   ├── lambda.tf               # deploy-trigger Lambda
│   ├── stepfunction.tf         # Step Function state machine
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   └── userdata/
│       ├── web_userdata.sh
│       └── app_userdata.sh
├── lambda/
│   └── deploy-trigger/
│       └── lambda_function.py  # SSM deploy + health-check logic
├── step-function/
│   └── deployment-flow.json    # State machine definition
├── app-tier/                   # Node.js Express REST API
│   ├── server.js
│   ├── package.json
│   ├── config/db.js
│   ├── routes/items.js
│   └── middleware/errorHandler.js
├── web-tier/                   # React SPA
│   ├── package.json
│   ├── public/index.html
│   └── src/
│       ├── index.jsx
│       ├── pages/Home.jsx
│       ├── api/items.js
│       └── styles/main.css
├── scripts/
│   ├── deploy-app.sh
│   └── deploy-web.sh
├── monitoring/
│   └── cloudwatch.tf           # CloudWatch alarms & log groups
├── docs/
│   └── architecture.md
└── .github/workflows/
    ├── deploy.yml              # Main pipeline (push → main)
    ├── terraform.yml           # PR validation
    └── destroy.yml             # Manual destroy (workflow_dispatch)
```

---

## Prerequisites

- AWS account with an IAM user that has permissions for EC2, RDS, S3, Lambda, Step Functions, SSM, and IAM
- Terraform ≥ 1.5 installed locally
- An EC2 Key Pair in `us-east-1`
- An S3 bucket for Terraform state (update `versions.tf` backend config)

---

## Quick Start

### 1. Configure Terraform variables

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform.tfvars with your values
```

### 2. Deploy infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 3. Add GitHub Secrets

| Secret | Value |
|--------|-------|
| `AWS_ACCESS_KEY_ID` | Your IAM access key |
| `AWS_SECRET_ACCESS_KEY` | Your IAM secret key |
| `STEPFUNCTION_ARN` | Output from `terraform output step_function_arn` |
| `DB_PASSWORD` | Your chosen RDS password |

### 4. Push to `main`

```bash
git push origin main
```

The pipeline will: validate → apply Terraform → build & upload artifacts → trigger the Step Function → deploy app tier → health check → deploy web tier → health check.

---

## CI/CD Flow

```
push → main
  │
  ├─ [Job 1] terraform apply
  ├─ [Job 2] build web (npm run build) → zip → S3
  │          zip app-tier → S3
  └─ [Job 3] start Step Function execution
               ├── DeployAppTier   (Lambda → SSM on app EC2s)
               ├── WaitForAppHealthy (60s)
               ├── CheckAppHealth
               ├── DeployWebTier   (Lambda → SSM on web EC2s)
               ├── WaitForWebHealthy (60s)
               └── CheckWebHealth
```

---

## Destroy

To tear down all infrastructure, trigger the **Destroy Infrastructure** workflow from GitHub Actions → **workflow_dispatch**, and type `DESTROY` in the confirmation field.

---

## GitHub Secrets Required

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `STEPFUNCTION_ARN`
- `DB_PASSWORD`
