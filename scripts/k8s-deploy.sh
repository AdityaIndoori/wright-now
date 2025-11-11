#!/bin/bash
# Kubernetes Deployment Script for WRight Now
# Deploys all services to the kind cluster

set -e

echo "🚀 Deploying WRight Now services to Kubernetes..."

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ Error: kubectl is not installed"
    echo "📦 Install kubectl: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

# Check if cluster exists
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Error: No Kubernetes cluster found"
    echo "Run './scripts/k8s-setup.sh' first to create the cluster"
    exit 1
fi

# Check if secrets exist
if [ ! -f "k8s/base/postgres/secrets.yaml" ]; then
    echo "⚠️  Warning: k8s/base/postgres/secrets.yaml not found"
    echo "Creating from example file..."
    cp k8s/base/postgres/secrets.example.yaml k8s/base/postgres/secrets.yaml
    echo "✅ Created k8s/base/postgres/secrets.yaml (using default values)"
fi

if [ ! -f "k8s/base/authentik/secrets.yaml" ]; then
    echo "⚠️  Warning: k8s/base/authentik/secrets.yaml not found"
    echo "Creating from example file..."
    cp k8s/base/authentik/secrets.example.yaml k8s/base/authentik/secrets.yaml
    echo "✅ Created k8s/base/authentik/secrets.yaml (using default values)"
fi

# Apply secrets first
echo "🔐 Applying secrets..."
kubectl apply -f k8s/base/postgres/secrets.yaml
kubectl apply -f k8s/base/authentik/secrets.yaml

# Apply Kustomize configuration
echo "📦 Deploying services with Kustomize..."
kubectl apply -k k8s/overlays/local

# Wait for all pods in staging-infra to be ready
echo "⏳ Waiting for pods to be ready (this may take a few minutes)..."
echo "   PostgreSQL, Redis, Authentik..."

# Set timeout to 5 minutes
TIMEOUT=300
START_TIME=$(date +%s)

while true; do
    # Check if all pods are ready
    NOT_READY=$(kubectl get pods -n staging-infra --no-headers 2>/dev/null | grep -v "Running" | grep -v "Completed" | wc -l || echo "1")
    
    if [ "$NOT_READY" -eq "0" ]; then
        echo "✅ All pods are ready!"
        break
    fi
    
    # Check timeout
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    
    if [ "$ELAPSED" -gt "$TIMEOUT" ]; then
        echo "❌ Timeout waiting for pods to be ready"
        echo "Current pod status:"
        kubectl get pods -n staging-infra
        exit 1
    fi
    
    echo "   Waiting... ($ELAPSED seconds elapsed)"
    sleep 10
done

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📊 Pod status:"
kubectl get pods -n staging-infra
echo ""
echo "📊 Service status:"
kubectl get svc -n staging-infra
echo ""
echo "📊 Ingress status:"
kubectl get ingress -n staging-infra
echo ""
echo "🌐 Access Authentik at: http://localhost/auth/"
echo ""
echo "Next steps:"
echo "  - Configure Authentik IdP at http://localhost/auth/"
echo "  - Deploy Core Backend (Sprint 0 Task 3.1)"
echo "  - Deploy AI Service (Sprint 0 Task 3.2)"
echo "  - Deploy Web Client (Sprint 0 Task 3.3)"
echo ""
