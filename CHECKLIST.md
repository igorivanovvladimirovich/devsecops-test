# DevSecOps Setup Checklist

## Pre-Setup

- [ ] GCP account created
- [ ] Billing enabled
- [ ] gcloud CLI installed
- [ ] Terraform installed
- [ ] kubectl installed
- [ ] Helm installed
- [ ] GitHub account ready

## GCP Setup

- [ ] Project created: `gcloud config set project PROJECT_ID`
- [ ] APIs enabled: `bash scripts/setup/01-gcp-setup.sh`
- [ ] Budget alert configured: $15 for 5 days
- [ ] Terraform state bucket created

## Infrastructure

- [ ] Terraform initialized: `bash scripts/setup/02-terraform-init.sh`
- [ ] Infrastructure deployed: `bash scripts/setup/03-deploy-infrastructure.sh`
- [ ] GKE cluster accessible: `kubectl get nodes`
- [ ] Workload Identity configured

## Kubernetes

- [ ] Trivy Operator installed
- [ ] Falco deployed
- [ ] Vulnerable apps deployed
- [ ] APT simulation running
- [ ] Network policies applied

## Monitoring

- [ ] BigQuery dataset created
- [ ] Cloud Functions deployed
- [ ] Cloud Run dashboard accessible
- [ ] Pub/Sub topics created
- [ ] Log sinks configured

## Security

- [ ] Vulnerability scans running: `kubectl get vulnerabilityreports -A`
- [ ] APT detection active: `bash scripts/monitoring/test-apt-detection.sh`
- [ ] Dashboard showing data: `$DASHBOARD_URL`
- [ ] Cloud Armor policies active

## GitHub

- [ ] Repository forked/created
- [ ] Secrets configured:
  - [ ] WIF_PROVIDER
  - [ ] GCP_SA_EMAIL
  - [ ] PROJECT_ID
- [ ] Vulnerable workflow active
- [ ] Branch protection (optional)

## Exploitation

- [ ] Webhook.site URL obtained
- [ ] Exploit branch created: `bash scripts/exploitation/create-exploit-branch.sh`
- [ ] PR created
- [ ] Exploit executed
- [ ] Credentials exfiltrated to webhook

## Verification

- [ ] Vulnerabilities visible in BigQuery
- [ ] APT indicators detected
- [ ] Dashboard shows metrics
- [ ] GitHub Actions ran exploit successfully
- [ ] Cost under $2/day

## Cleanup

- [ ] Test completed
- [ ] Data exported (if needed)
- [ ] Resources deleted: `bash scripts/cleanup/cleanup-all.sh`
- [ ] Cost verified: $0/hour
- [ ] No lingering resources

## Learning Outcomes

- [ ] Understand GKE Autopilot
- [ ] Trivy vulnerability scanning
- [ ] Falco runtime security
- [ ] BigQuery for security analytics
- [ ] GitHub Actions security
- [ ] Workload Identity
- [ ] Cloud Functions event processing
- [ ] Cost optimization techniques

**Total Time**: 30-45 minutes
**Total Cost**: $8-10 for 5 days