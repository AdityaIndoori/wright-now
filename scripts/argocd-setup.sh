#!/bin/bash
# ArgoCD Setup Script
# This script installs and configures ArgoCD for GitOps continuous deployment

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo ""
    echo "======================================"
    echo "$1"
    echo "======================================"
    echo ""
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    print_info "✓ kubectl is installed"
    
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Unable to connect to Kubernetes cluster. Please check your kubeconfig."
        exit 1
    fi
    print_info "✓ Connected to Kubernetes cluster"
}

# Install ArgoCD
install_argocd() {
    print_header "Installing ArgoCD"
    
    # Create argocd namespace
    if kubectl get namespace argocd &> /dev/null; then
        print_warn "Namespace 'argocd' already exists. Skipping creation."
    else
        print_info "Creating namespace 'argocd'..."
        kubectl create namespace argocd
    fi
    
    # Apply ArgoCD installation manifest
    print_info "Applying ArgoCD installation manifest..."
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    # Wait for ArgoCD to be ready
    print_info "Waiting for ArgoCD pods to be ready (this may take a few minutes)..."
    kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s
    
    print_info "✓ ArgoCD installed successfully"
}

# Apply ArgoCD configuration
apply_config() {
    print_header "Applying ArgoCD Configuration"
    
    # Apply Ingress
    print_info "Applying Ingress configuration..."
    kubectl apply -f k8s/base/argocd/ingress.yaml
    
    # Apply RBAC
    print_info "Applying RBAC configuration..."
    kubectl apply -f k8s/base/argocd/rbac-cm.yaml
    
    # Wait for ArgoCD server to restart with new config
    print_info "Waiting for ArgoCD server to restart..."
    kubectl rollout status deployment/argocd-server -n argocd
    
    print_info "✓ Configuration applied successfully"
}

# Deploy infrastructure application
deploy_infrastructure() {
    print_header "Deploying Infrastructure Application"
    
    print_info "Applying infrastructure Application manifest..."
    kubectl apply -f k8s/base/argocd/applications/infrastructure-app.yaml
    
    print_info "✓ Infrastructure Application created"
    print_info "ArgoCD will sync infrastructure resources within 3 minutes"
}

# Get initial admin password
get_admin_password() {
    print_header "Retrieving Admin Credentials"
    
    print_info "ArgoCD admin credentials:"
    echo ""
    echo "  Username: admin"
    echo -n "  Password: "
    
    if kubectl get secret argocd-initial-admin-secret -n argocd &> /dev/null; then
        kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
        echo ""
        echo ""
        print_warn "⚠️  Please change the admin password after first login!"
        print_info "Use: argocd account update-password"
    else
        print_error "Unable to retrieve admin password. Secret not found."
    fi
}

# Print access information
print_access_info() {
    print_header "Access Information"
    
    echo "ArgoCD UI Access:"
    echo ""
    echo "  Local (kind cluster):"
    echo "    http://localhost/argocd"
    echo ""
    echo "  Port-forward (alternative):"
    echo "    kubectl port-forward svc/argocd-server -n argocd 8080:443"
    echo "    https://localhost:8080"
    echo ""
    echo "ArgoCD CLI:"
    echo ""
    echo "  Install CLI:"
    echo "    # Linux"
    echo "    curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"
    echo "    sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd"
    echo ""
    echo "    # macOS"
    echo "    brew install argocd"
    echo ""
    echo "    # Windows"
    echo "    choco install argocd-cli"
    echo ""
    echo "  Login:"
    echo "    argocd login localhost:8080 --username admin --insecure"
    echo ""
    echo "  List applications:"
    echo "    argocd app list"
    echo ""
    echo "  Sync application:"
    echo "    argocd app sync infrastructure"
    echo ""
}

# Main execution
main() {
    print_header "ArgoCD Setup for WRight Now"
    
    check_prerequisites
    install_argocd
    apply_config
    deploy_infrastructure
    get_admin_password
    print_access_info
    
    print_header "Setup Complete!"
    print_info "✅ ArgoCD is now managing your Kubernetes deployments"
    print_info "📊 Check the ArgoCD UI to see deployment status"
    print_info "🔄 Any changes pushed to main branch will auto-deploy"
}

# Run main function
main
