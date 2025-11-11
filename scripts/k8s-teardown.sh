#!/bin/bash
# Kubernetes Cluster Teardown Script for WRight Now
# Deletes the local kind cluster

set -e

echo "🗑️  Tearing down WRight Now Kubernetes cluster..."

# Check if kind is installed
if ! command -v kind &> /dev/null; then
    echo "❌ Error: kind is not installed"
    exit 1
fi

# Check if cluster exists
if ! kind get clusters 2>/dev/null | grep -q "^wrightnow$"; then
    echo "ℹ️  Cluster 'wrightnow' does not exist"
    exit 0
fi

# Confirm deletion
echo "⚠️  This will delete the 'wrightnow' cluster and all data"
read -p "Are you sure? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled"
    exit 0
fi

# Delete cluster
echo "🗑️  Deleting kind cluster 'wrightnow'..."
kind delete cluster --name wrightnow

# Verify deletion
if kind get clusters 2>/dev/null | grep -q "^wrightnow$"; then
    echo "❌ Failed to delete cluster"
    exit 1
fi

echo "✅ Cluster 'wrightnow' deleted successfully!"
echo ""
echo "Docker cleanup:"
docker ps -a | grep wrightnow || echo "  No leftover containers found"
echo ""
echo "To recreate the cluster:"
echo "  ./scripts/k8s-setup.sh"
echo ""
