# DevSecOps Security Demonstration

Complete DevSecOps pipeline with GCP/GKE showcasing:
- Kubernetes security scanning (Trivy)
- Runtime threat detection (Falco)
- APT simulation (Russian APT indicators)
- GitHub Actions exploitation
- Security analytics (BigQuery)
- Cost-optimized architecture ($8-10 for 5 days)

## Quick Start

```bash
# 1. Setup prerequisites
bash scripts/setup/00-prerequisites.sh

# 2. Configure GCP
gcloud config set project YOUR_PROJECT_ID
bash scripts/setup/01-gcp-setup.sh

# 3. Deploy everything
bash scripts/setup/99-complete-setup.sh

# 4. Access dashboard
# URL displayed at end of setup
Architecture
GKE Autopilot: Pay-per-pod Kubernetes
Trivy Operator: Continuous vulnerability scanning
Falco: Runtime security monitoring
BigQuery: Security data warehouse
Cloud Functions: Event processing
Cloud Run: Security dashboard
Cost
1.24/day∗∗=∗∗1.24/day** = **6.20 for 5 days

See docs/COST-ANALYSIS.md for details.

Exploitation Demo
bash


# Create malicious PR
bash scripts/exploitation/create-exploit-branch.sh

# Push and create PR on GitHub
# GitHub Actions will steal credentials
Monitoring
bash


# Check vulnerabilities
bash scripts/monitoring/check-vulnerabilities.sh

# Test APT detection
bash scripts/monitoring/test-apt-detection.sh

# Query BigQuery
bash scripts/monitoring/query-bigquery.sh
Cleanup
bash


# Complete cleanup
bash scripts/cleanup/cleanup-all.sh
Documentation
Setup Guide
Architecture
Exploitation Guide
Cost Analysis
Learning Objectives
✅ GKE Autopilot configuration ✅ Kubernetes security scanning ✅ Runtime threat detection ✅ Security data analytics ✅ GitHub Actions security ✅ Workload Identity ✅ Cost optimization

Perfect for: DevSecOps interview preparation, GCP learning, security demonstrations


---

Теперь у вас есть полный проект с:

1. ✅ **Terraform** - вся инфраструктура GCP
2. ✅ **Kubernetes** - vulnerable apps, Trivy, Falco
3. ✅ **Local Kind** - тестирование без затрат (container escape demo)
4. ✅ **Exploit** - GitHub Actions vulnerability demonstration
5. ✅ **Scripts** - setup, monitoring, cleanup
6. ✅ **Cloud Functions** - event processing
7. ✅ **Cloud Run** - security dashboard

**Стоимость**: \$6-8 за 5 дней тестирования

Готовы начать деплой?