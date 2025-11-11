#!/bin/bash
# Kubernetes Cluster Setup Script for WRight Now
# Creates a local kind cluster with nginx-ingress for development

set -e

echo "🚀 Setting up WRight Now Kubernetes cluster..."

# Check if kind is installed
if ! command -v kind &> /dev/null; then
    echo "❌ Error: kind is not installed"
    echo "📦 Install kind: https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ Error: kubectl is not installed"
    echo "📦 Install kubectl: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

# Check if cluster already exists
if kind get clusters 2>/dev/null | grep -q "^wrightnow$"; then
    echo "⚠️  Cluster 'wrightnow' already exists"
    read -p "Do you want to delete and recreate it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  Deleting existing cluster..."
        kind delete cluster --name wrightnow
    else
        echo "ℹ️  Using existing cluster"
        exit 0
    fi
fi

# Create kind cluster
echo "📦 Creating kind cluster 'wrightnow'..."
kind create cluster --config k8s/overlays/local/kind-cluster-config.yaml

# Wait for cluster to be ready
echo "⏳ Waiting for cluster to be ready..."
kubectl wait --for=condition=ready node --all --timeout=60s

# Install nginx-ingress controller
echo "📦 Installing nginx-ingress controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for ingress-nginx to be ready
echo "⏳ Waiting for nginx-ingress to be ready..."
kubectl wait --namespace ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=90s

echo "✅ Kubernetes cluster 'wrightnow' created successfully!"
echo ""
echo "📊 Cluster info:"
kubectl cluster-info
echo ""
echo "Next steps:"
echo "  1. Copy and configure secrets:"
echo "     cp k8s/base/postgres/secrets.example.yaml k8s/base/postgres/secrets.yaml"
echo "     cp k8s/base/authentik/secrets.example.yaml k8s/base/authentik/secrets.yaml"
echo "  2. Deploy services:"
echo "     ./scripts/k8s-deploy.sh"
echo ""
