---
name: cloud-infra
description: Professional AWS/GCP/Cloudflare infrastructure design and operations: IaC-first (Terraform/CDK), least-privilege IAM, multi-account separation, VPC network segmentation, secrets management, observability (structured logs/metrics/SLOs/alerts), backup and DR with RTO/RPO targets, cost guardrails, zero-downtime deploys, and a pre-deploy security checklist. Load when designing or operating cloud infra on AWS, GCP, Cloudflare, Terraform, IAM, VPC, serverless, or any deployment infrastructure.
origin: Local
---

# Cloud Infrastructure Design & Operations

Professional-grade patterns for AWS, GCP, and Cloudflare. IaC-first. Security by default.

## When to Activate

- Designing new cloud infrastructure or reviewing existing architecture
- Writing Terraform, CDK, or Pulumi modules
- Configuring IAM roles, policies, and service accounts
- Setting up network segmentation, VPCs, or Cloudflare routing
- Implementing secrets management or environment variable pipelines
- Building observability stacks (logs, metrics, alerts, SLOs)
- Planning backup, DR, or business continuity
- Managing costs with budgets, tagging, and guardrails
- Planning zero-downtime deployments or runbook automation

---

## IaC-First Principle

All infrastructure changes go through code. No manual console edits in production.

```hcl
# Terraform example: enforce remote state + backend
terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
  backend "s3" {
    bucket         = "my-org-tfstate"
    key            = "prod/infra.tfstate"
    region         = "ap-northeast-1"
    encrypt        = true
    dynamodb_table = "tfstate-locks"  # prevent concurrent applies
  }
}
```

Conventions:
- One Terraform workspace per environment (dev/staging/prod) or per bounded domain
- State in remote backend with locking; never commit `.tfstate` to git
- Modules for reusable patterns (VPC, ECS service, Lambda function)
- Pin provider versions; use `dependabot` or Renovate for upgrades
- `terraform plan` is mandatory in CI; `apply` only from CD pipeline with approval gate for prod

---

## IAM — Least Privilege

Grant the minimum permissions required. Never use root credentials for automation.

### AWS

```hcl
# Bad: wildcard
resource "aws_iam_policy" "bad" {
  policy = jsonencode({
    Statement = [{ Effect = "Allow", Action = "*", Resource = "*" }]
  })
}

# Good: scoped to specific actions and resources
resource "aws_iam_role_policy" "app_s3" {
  role = aws_iam_role.app.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject", "s3:PutObject"]
      Resource = "arn:aws:s3:::${var.bucket_name}/*"
    }]
  })
}
```

IAM rules:
- One role per service, never shared roles between services
- Roles for EC2/ECS/Lambda (instance profiles); access keys only for external systems
- Enable MFA enforcement for human users and the AWS root account
- Review unused permissions quarterly with IAM Access Analyzer

### GCP

```hcl
# Service account per workload
resource "google_service_account" "api" {
  account_id   = "api-server"
  display_name = "API Server Service Account"
}

resource "google_project_iam_member" "api_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.api.email}"
}
```

---

## Multi-Account / Multi-Project Separation

Separate environments at the account (AWS) or project (GCP) level — not just by VPC or namespace.

```
AWS Organization structure:
├── Root (management account — no workloads)
├── Security (audit logs, GuardDuty, SecurityHub)
├── Shared Services (ECR, DNS, artifact storage)
├── Dev
├── Staging
└── Prod
```

Benefits:
- Blast radius containment: a compromised dev account cannot reach prod
- Cost visibility by account
- Independent IAM boundaries

---

## Network Segmentation

### AWS VPC

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "prod-vpc"
  cidr = "10.0.0.0/16"

  azs              = ["ap-northeast-1a", "ap-northeast-1c"]
  private_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]   # app layer
  database_subnets = ["10.0.3.0/24", "10.0.4.0/24"]   # DB layer
  public_subnets   = ["10.0.5.0/24", "10.0.6.0/24"]   # ALB only

  enable_nat_gateway = true
  single_nat_gateway = false  # HA: one per AZ in prod

  # No public IP on instances
  map_public_ip_on_launch = false
}
```

Security group rules:
- Allow only what is documented. Default deny.
- ALB security group: 443 from 0.0.0.0/0 only
- App security group: only from ALB security group
- DB security group: only from app security group, no internet access

### Cloudflare

```hcl
resource "cloudflare_access_application" "admin" {
  zone_id          = var.zone_id
  name             = "Admin Panel"
  domain           = "admin.example.com"
  session_duration = "8h"
}

resource "cloudflare_access_policy" "admin_email" {
  application_id = cloudflare_access_application.admin.id
  zone_id        = var.zone_id
  name           = "Allow org email"
  decision       = "allow"

  include {
    email_domain = ["example.com"]
  }
}
```

Use Cloudflare Zero Trust to gate internal tools without VPN.

---

## Secrets Management

Never store secrets as plaintext — not in environment variables baked into images, not in Terraform state (use `sensitive = true`), not in git.

### AWS Secrets Manager / Parameter Store

```python
# Application code: fetch at runtime
import boto3
import json

def get_secret(secret_name: str) -> dict:
    client = boto3.client("secretsmanager", region_name="ap-northeast-1")
    value = client.get_secret_value(SecretId=secret_name)
    return json.loads(value["SecretString"])

# Usage
db_creds = get_secret("prod/app/db")
```

```hcl
# Terraform: reference secrets without embedding them
data "aws_secretsmanager_secret_version" "db" {
  secret_id = "prod/app/db"
}

locals {
  db_url = jsondecode(data.aws_secretsmanager_secret_version.db.secret_string)["url"]
}
```

### GCP Secret Manager

```python
from google.cloud import secretmanager

def access_secret(project_id: str, secret_id: str) -> str:
    client = secretmanager.SecretManagerServiceClient()
    name = f"projects/{project_id}/secrets/{secret_id}/versions/latest"
    return client.access_secret_version(name=name).payload.data.decode("utf-8")
```

Rules:
- Rotate secrets on a schedule (90 days for DB passwords, 180 days for API keys)
- Audit secret access via CloudTrail / Cloud Audit Logs
- Never log secret values; log only the secret name and access metadata

---

## Observability

Three pillars: logs, metrics, traces. One additional: SLOs.

### Structured Logging

```json
{
  "timestamp": "2025-01-15T10:30:00Z",
  "level": "ERROR",
  "service": "payment-api",
  "requestId": "abc-123",
  "userId": "u-456",
  "error": "stripe_charge_failed",
  "duration_ms": 234
}
```

Log aggregation: CloudWatch Logs → Log Insights / Grafana Loki / Datadog

### Metrics & Alerts

```hcl
# AWS CloudWatch alarm example
resource "aws_cloudwatch_metric_alarm" "error_rate" {
  alarm_name          = "api-error-rate-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "5XXError"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }
}
```

Key metrics to alert on:
- Error rate (5xx / total requests > threshold)
- P99 latency > SLO target
- CPU/memory > 80% sustained for 5 min
- Queue depth growing without workers consuming
- Certificate expiry < 30 days

### SLO Definition

```yaml
# SLO declaration (e.g., Sloth / Nobl9 / custom)
slo:
  name: api-availability
  description: "API returns 2xx or 4xx for ≥99.9% of requests"
  objective: 99.9
  window: 30d
  indicators:
    - type: request_based
      good_events: http_requests_total{status!~"5.."}
      total_events: http_requests_total
```

Error budget = 1 - SLO. When error budget is >50% consumed in a week, halt non-critical feature work.

---

## Backup & Disaster Recovery

Define RTO and RPO before choosing the DR strategy.

| Strategy | RTO | RPO | Cost |
|---|---|---|---|
| Backup & Restore | Hours–Days | Hours | Low |
| Pilot Light | 30–60 min | Minutes | Medium |
| Warm Standby | Minutes | Seconds | High |
| Multi-site Active/Active | ~0 | ~0 | Very high |

For most SaaS products: Warm Standby is the right balance.

```hcl
# RDS automated backups + cross-region replication
resource "aws_db_instance" "main" {
  identifier              = "prod-db"
  backup_retention_period = 14           # 14 days of automated snapshots
  backup_window           = "03:00-04:00" # UTC, low-traffic window
  deletion_protection     = true
  multi_az                = true          # synchronous standby in another AZ
}

resource "aws_db_snapshot_copy" "cross_region" {
  source_db_snapshot_identifier = aws_db_instance.main.latest_restorable_time
  target_db_snapshot_identifier = "prod-db-backup-${timestamp()}"
  destination_region            = "ap-northeast-3"  # separate region
}
```

DR checklist:
- Automated backups tested monthly (restore to staging and verify data integrity)
- RPO documented and communicated to stakeholders
- Runbook for each failure scenario: DB failure, AZ outage, region outage, data corruption
- Contact list with escalation path

---

## Cost Guardrails

```hcl
# AWS Budget alert
resource "aws_budgets_budget" "monthly" {
  name         = "monthly-infra"
  budget_type  = "COST"
  limit_amount = "500"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = ["ops@example.com"]
  }
}
```

Cost hygiene:
- Tag every resource: `environment`, `team`, `service`, `cost-center`
- Right-size over-provisioned instances quarterly (use Compute Optimizer / Recommender)
- Delete unused resources: unattached EBS volumes, idle load balancers, old snapshots
- Reserved Instances / Committed Use for predictable steady-state workloads (break-even ~6 months)
- Spot Instances for batch, dev, and stateless workloads

---

## Zero-Downtime Deploys

```yaml
# ECS rolling update
deployment_configuration:
  maximum_percent:         200  # double capacity during deploy
  minimum_healthy_percent: 100  # never below full capacity

# Combined with ALB target group deregistration delay
deregistration_delay: 30  # seconds to drain connections
```

Principles:
- Deploy immutable artifacts (container image by digest, not tag)
- Database migrations must be backward-compatible with the previous application version
  - Add-only schema changes first (add column, add index)
  - Application updated to use new schema
  - Remove old columns/tables in a separate later migration
- Feature flags to decouple deploy from release
- Rollback = redeploy previous image digest (< 5 min)

---

## Pre-Deploy Checklist

Before any production deployment:

### Security
- [ ] No plaintext secrets in code, Dockerfiles, or env vars
- [ ] IAM roles scoped to minimum required permissions
- [ ] Security groups follow default-deny principle
- [ ] Dependencies scanned for CVEs (Trivy, Snyk, Dependabot)
- [ ] Encryption at rest enabled (S3 SSE, RDS encrypted storage)
- [ ] Encryption in transit enforced (TLS 1.2+, no HTTP)
- [ ] Public-exposure audit: no unintended public S3 buckets, endpoints, or DB ports

### Reliability
- [ ] Health check endpoint returns meaningful status
- [ ] Liveness and readiness probes configured
- [ ] Multi-AZ deployment for stateful services
- [ ] Auto-scaling configured with appropriate min/max
- [ ] Circuit breakers or retry logic for downstream service calls

### Observability
- [ ] Structured logs flowing to aggregation system
- [ ] Key metrics alarmed (error rate, latency, saturation)
- [ ] SLOs defined and dashboards updated
- [ ] Distributed tracing enabled for cross-service calls

### Operations
- [ ] Rollback procedure documented and tested in staging
- [ ] DB migration tested against a production-sized snapshot
- [ ] Runbook updated for the change
- [ ] On-call engineer confirmed for the deploy window
