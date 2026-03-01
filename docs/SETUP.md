# DevSecOps Setup Guide

## Overview

Complete DevSecOps demonstration with GCP/GKE security features.

**Estimated Cost**: $8-12 for 5 days
**Time to Setup**: 30-45 minutes

## Architecture

## Prerequisites

- GCP account with billing enabled
- gcloud CLI installed
- Terraform >= 1.0
- kubectl, helm
- GitHub account

## Quick Start

```bash
# 1. Clone repository
git clone https://github.com/YOUR_USERNAME/devsecops-test.git
cd devsecops-test

# 2. Run complete setup
bash scripts/setup/99-complete-setup.sh

# 3. Access dashboard
# URL will be displayed at the end
Manual Setup
1. Prerequisites
bash


bash scripts/setup/00-prerequisites.sh
2. GCP Setup
bash


# Set project
gcloud config set project YOUR_PROJECT_ID

# Run GCP setup
bash scripts/setup/01-gcp-setup.sh
3. Terraform
bash


bash scripts/setup/02-terraform-init.sh
bash scripts/setup/03-deploy-infrastructure.sh
4. Kubernetes
bash


bash scripts/setup/04-deploy-kubernetes.sh
5. Cloud Functions & Cloud Run
bash


bash scripts/setup/05-deploy-functions.sh
bash scripts/setup/06-deploy-cloud-run.sh
Verification
bash


# Check vulnerabilities
bash scripts/monitoring/check-vulnerabilities.sh

# Query BigQuery
bash scripts/monitoring/query-bigquery.sh

# Test APT detection
bash scripts/monitoring/test-apt-detection.sh
Exploitation Demo
bash


# Create exploit branch
bash scripts/exploitation/create-exploit-branch.sh

# Push and create PR
git push origin exploit-github-actions-*

# Create PR on GitHub
# GitHub Actions will run the exploit
Cost Management
bash


# Check costs
bash scripts/cost-optimization/check-costs.sh

# Scale down
bash scripts/cost-optimization/scale-down.sh

# Cleanup (keep data)
bash scripts/cleanup/cleanup-keep-data.sh

# Complete cleanup
bash scripts/cleanup/cleanup-all.sh
Troubleshooting
GKE Cluster Not Ready
bash


gcloud container clusters describe ${CLUSTER_NAME} --region ${REGION}
Trivy Not Scanning
bash


kubectl logs -n trivy-system -l app.kubernetes.io/name=trivy-operator
BigQuery No Data
bash


# Check log sink
gcloud logging sinks describe gke-logs-to-bq

# Manual export
bash scripts/monitoring/check-vulnerabilities.sh
Support
See full documentation in docs/ directory.




### Файл: `docs/ARCHITECTURE.md`

```markdown
# Architecture Overview

## High-Level Architecture
┌─────────────────────────────────────────────────────────────┐ │ GitHub Actions │ │ (Workload Identity Federation) │ └────────────┬────────────────────────────────────────────────┘ │ ▼ ┌─────────────────────────────────────────────────────────────┐ │ Cloud Build (CI/CD) │ │ • Terraform validation • Container builds │ │ • Trivy scanning • Artifact Registry │ └────────────┬────────────────────────────────────────────────┘ │ ▼ ┌─────────────────────────────────────────────────────────────┐ │ GKE Autopilot Cluster │ │ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ │ │ │ Trivy │ │ Vulnerable │ │ Falco │ │ │ │ Operator │ │ Apps │ │ (IDS/IPS) │ │ │ └──────────────┘ └──────────────┘ └──────────────┘ │ │ │ │ VPC Network + Cloud Armor Security Policies │ └────────────┬────────────────────────────────────────────────┘ │ ▼ ┌─────────────────────────────────────────────────────────────┐ │ Pub/Sub Topics │ │ • trivy-reports • apt-detection • security-alerts │ └────────────┬────────────────────────────────────────────────┘ │ ▼ ┌──────────────────────────┬──────────────────────────────────┐ │ Cloud Functions │ Cloud Run │ │ • Process reports │ • Security Dashboard │ │ • Detect APT │ • REST API │ └──────────────────────────┴──────────────────────────────────┘ │ │ ▼ ▼ ┌────────────────────────┐ ┌──────────────────────┐ │ BigQuery │ │ Cloud Storage │ │ • Vulnerabilities │ │ • Terraform State │ │ • APT Indicators │ │ • Scan Results │ │ • Security Metrics │ │ • Backups │ └────────────────────────┘ └──────────────────────┘




## Components

### 1. Source Control & CI/CD

**GitHub Actions**
- Workload Identity Federation (keyless auth)
- Terraform plan on PR
- Vulnerable workflow for exploitation demo

**Cloud Build**
- Automated container builds
- Terraform validation
- Trivy container scanning

### 2. Compute & Orchestration

**GKE Autopilot**
- Pay-per-pod pricing (~$0.80/day)
- Automatic node management
- Built-in security features
- Workload Identity enabled

### 3. Security Scanning

**Trivy Operator**
- Continuous vulnerability scanning
- CIS Kubernetes Benchmark
- Log compression (gzip)
- Pub/Sub integration

**Falco**
- Runtime security (IDS/IPS)
- Custom rules for APT detection
- Syscall monitoring
- eBPF-based

### 4. Event Processing

**Pub/Sub**
- Decoupled event bus
- Message retention: 3 days
- Automatic retry

**Cloud Functions (2nd gen)**
- Event-driven processing
- Python 3.11 runtime
- Auto-scaling (0-3 instances)
- 256MB memory

### 5. Data & Analytics

**BigQuery**
- Security data warehouse
- Partitioned tables (by day)
- 3-day retention
- Free tier: 1TB queries/month

**Cloud Storage**
- Terraform state (versioned)
- Scan results (3-day lifecycle)
- Function source code

### 6. Visualization

**Cloud Run**
- Security dashboard web app
- Flask + Bootstrap UI
- Real-time metrics
- Public access (demo only)

### 7. Security Features

**Cloud Armor**
- WAF policies
- Rate limiting
- Geo-blocking
- Port 31337 blocked

**Binary Authorization**
- Container image verification
- Attestation required
- Whitelist trusted registries

**Secret Manager**
- Credentials storage
- Automatic rotation
- IAM-based access

**Workload Identity**
- Keyless authentication
- Pod-to-GCP-SA binding
- No service account keys

## Data Flow

### Vulnerability Scanning Flow
Trivy Operator scans pods
Results stored as VulnerabilityReport CRDs
Log exporter publishes to Pub/Sub (gzip compressed)
Cloud Function processes and extracts data
Structured data inserted into BigQuery
Dashboard queries BigQuery for visualization



### APT Detection Flow
Falco monitors syscalls in real-time
Custom rules detect:
Magic file creation (/tmp/.magic_file)
Port 31337 connections
Crypto miner processes
Alerts published to Pub/Sub
Cloud Function analyzes and scores risk
High-risk indicators saved to BigQuery
Monitoring alerts triggered



## Security Design

### Defense in Depth
Layer 1: Network ├─ VPC with private subnets ├─ Cloud Armor policies └─ Network policies in K8s

Layer 2: Identity ├─ Workload Identity (no keys!) ├─ Least privilege IAM └─ Service Account separation

Layer 3: Compute ├─ GKE Autopilot (Google-managed nodes) ├─ Shielded nodes └─ Binary Authorization

Layer 4: Application ├─ Trivy vulnerability scanning ├─ Falco runtime protection └─ Regular updates

Layer 5: Data ├─ Encryption at rest ├─ Encryption in transit └─ Access logging

Layer 6: Monitoring ├─ Cloud Logging ├─ Cloud Monitoring └─ Security dashboard




## Cost Optimization

### Daily Costs Breakdown
GKE Autopilot: $0.80 Cloud Functions: $0.00 (free tier) Cloud Run: $0.20 Pub/Sub: $0.00 (free tier) BigQuery: $0.00 (free tier) Cloud Storage: $0.10 Logging/Monitoring: $0.20 Network egress: $0.10 ───────────────────────────── TOTAL: ~$1.40/day




### Optimization Strategies

1. **Use Autopilot** instead of Standard GKE (saves 40%)
2. **3-day retention** on BigQuery tables
3. **Minimal logging** (SYSTEM_COMPONENTS only)
4. **Scale to zero** for Cloud Run
5. **Free tier** for Functions, Pub/Sub, BigQuery
6. **Lifecycle policies** on Cloud Storage

## Scalability

Current setup handles:
- **Scans**: 50-100 pods
- **Events**: 10k messages/hour
- **Storage**: 10GB logs/week
- **Queries**: 100GB/month

To scale up:
- Increase Cloud Function instances
- Add BigQuery streaming inserts
- Enable Cloud Monitoring dashboards
- Add more Falco rules

## High Availability

- **GKE**: Multi-zone by default
- **Cloud Functions**: Auto-scaling
- **BigQuery**: Global service
- **Cloud Storage**: Multi-region option

## Monitoring & Alerting

### Key Metrics

- Vulnerability count by severity
- APT indicator detections
- Resource compliance status
- Cost per day

### Alerts

- APT detection (CRITICAL)
- High/Critical vulnerabilities (HIGH)
- Budget alerts (INFO)

See `docs/SCREENSHOTS.md` for dashboard examples.