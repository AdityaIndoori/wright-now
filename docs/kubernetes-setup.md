# Kubernetes Setup Guide for WRight Now

Complete guide for setting up and deploying WRight Now on Kubernetes, from local development to cloud production.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Local Development Setup](#local-development-setup)
3. [Deploying to Cloud Providers](#deploying-to-cloud-providers)
4. [Configuration Management](#configuration-management)
5. [Security Best Practices](#security-best-practices)
6. [Monitoring and Logging](#monitoring-and-logging)
7. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Tools

#### Docker Desktop
- **Purpose**: Container runtime and local Kubernetes
- **Installation**: [Download Docker Desktop](https://www.docker.com/products/docker-desktop/)
- **Configuration**: Enable Kubernetes in settings (optional, we'll use kind)

#### kind (Kubernetes in Docker)
- **Purpose**: Local Kubernetes cluster for development
- **Installation**:
  ```bash
  # macOS
  brew install kind
  
  # Windows (with Chocolatey)
  choco install kind
  
  # Linux
  curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
  chmod +x ./kind
  sudo mv ./kind /usr/local/bin/kind
  ```

#### kubectl
- **Purpose**: Kubernetes command-line tool
- **Installation**:
  ```bash
  # macOS
  brew install kubectl
  
  # Windows (with Chocolatey)
  choco install kubernetes-cli
  
  # Linux
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/
  ```

#### kustomize (Optional)
- **Purpose**: Kubernetes configuration management
- **Installation**:
  ```bash
  # macOS
  brew install kustomize
  
  # Windows (with Chocolatey)
  choco install kustomize
  
  # Linux
  curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
  ```

### System Requirements

#### Minimum Requirements
- **CPU**: 4 cores
- **RAM**: 8GB
- **Disk**: 20GB free space
- **OS**: Windows 10/11, macOS 10.15+, or Linux

#### Recommended Requirements
- **CPU**: 6+ cores
- **RAM**: 16GB
- **Disk**: 50GB free space (for development data)
- **OS**: Latest stable version

## Local Development Setup

### Step 1: Clone the Repository

```bash
git clone https://github.com/yourusername/wrightnow.git
cd wrightnow
```

### Step 2: Create the kind Cluster

```bash
# Run the setup script
./scripts/k8s-setup.sh
```

**What this does:**
1. Checks for required tools (kind, kubectl)
2. Creates a kind cluster named `wrightnow`
3. Configures port mappings (80:80, 443:443)
4. Installs nginx-ingress controller
5. Waits for all components to be ready

**Expected output:**
```
🚀 Setting up WRight Now Kubernetes cluster...
📦 Creating kind cluster 'wrightnow'...
⏳ Waiting for cluster to be ready...
📦 Installing nginx-ingress controller...
⏳ Waiting for nginx-ingress to be ready...
✅ Kubernetes cluster 'wrightnow' created successfully!
```

### Step 3: Configure Secrets

```bash
# Copy secret templates
cp k8s/base/postgres/secrets.example.yaml k8s/base/postgres/secrets.yaml
cp k8s/base/authentik/secrets.example.yaml k8s/base/authentik/secrets.yaml
```

**Generate strong secrets:**

```bash
# Generate PostgreSQL password
POSTGRES_PASS=$(openssl rand -base64 32)
echo -n "$POSTGRES_PASS" | base64

# Generate Authentik secret key
AUTHENTIK_KEY=$(openssl rand -base64 32)
echo -n "$AUTHENTIK_KEY" | base64
```

**Edit the secret files** and replace the placeholder values with your generated base64-encoded secrets.

### Step 4: Deploy Services

```bash
# Deploy all infrastructure services
./scripts/k8s-deploy.sh
```

**What this does:**
1. Applies Kubernetes secrets
2. Deploys PostgreSQL with pg_vector
3. Deploys Redis cache
4. Deploys Authentik IdP (PostgreSQL, Redis, Server, Worker)
5. Configures Ingress for Authentik
6. Waits for all pods to be ready

**Expected output:**
```
🚀 Deploying WRight Now services to Kubernetes...
🔐 Applying secrets...
📦 Deploying services with Kustomize...
⏳ Waiting for pods to be ready (this may take a few minutes)...
✅ All pods are ready!
📊 Pod status:
NAME                               READY   STATUS    RESTARTS
authentik-server-...               1/1     Running   0
authentik-worker-...               1/1     Running   0
authentik-postgres-0               1/1     Running   0
authentik-redis-...                1/1     Running   0
postgres-0                         1/1     Running   0
redis-...                          1/1     Running   0
🌐 Access Authentik at: http://localhost/auth/
```

### Step 5: Verify Deployment

```bash
# Check all pods are running
kubectl get pods -n staging-infra

# Check services
kubectl get svc -n staging-infra

# Check ingress
kubectl get ingress -n staging-infra
```

### Step 6: Access Services

**Authentik IdP:**
- URL: http://localhost/auth/
- Initial setup will prompt for admin user creation

**PostgreSQL (from pod):**
```bash
kubectl exec -it postgres-0 -n staging-infra -- psql -U postgres
```

**Redis (from pod):**
```bash
kubectl exec -it deployment/redis -n staging-infra -- redis-cli
```

## Deploying to Cloud Providers

### Google Kubernetes Engine (GKE)

#### 1. Create GKE Cluster

```bash
# Set project ID
export PROJECT_ID="your-gcp-project"
gcloud config set project $PROJECT_ID

# Create cluster
gcloud container clusters create wrightnow \
  --zone us-central1-a \
  --num-nodes 3 \
  --machine-type n1-standard-2 \
  --enable-autoscaling \
  --min-nodes 3 \
  --max-nodes 10
```

#### 2. Configure kubectl

```bash
gcloud container clusters get-credentials wrightnow --zone us-central1-a
```

#### 3. Create Production Overlay

Create `k8s/overlays/production/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

bases:
  - ../../base

namespace: production

patchesStrategicMerge:
  - storage-class-patch.yaml
  - ingress-patch.yaml
  - resource-limits-patch.yaml
```

#### 4. Create Storage Class Patch

Create `k8s/overlays/production/storage-class-patch.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-data
spec:
  storageClassName: standard-rwo  # GCE Persistent Disk
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi  # Increase for production
```

#### 5. Deploy to GKE

```bash
# Create secrets in production namespace
kubectl create namespace production
kubectl apply -f k8s/base/postgres/secrets.yaml -n production
kubectl apply -f k8s/base/authentik/secrets.yaml -n production

# Deploy with Kustomize
kubectl apply -k k8s/overlays/production
```

### AWS Elastic Kubernetes Service (EKS)

#### 1. Create EKS Cluster

```bash
# Install eksctl
brew install eksctl  # macOS
# or download from https://github.com/weaveworks/eksctl

# Create cluster
eksctl create cluster \
  --name wrightnow \
  --region us-west-2 \
  --nodegroup-name standard-workers \
  --node-type t3.medium \
  --nodes 3 \
  --nodes-min 3 \
  --nodes-max 10 \
  --managed
```

#### 2. Configure kubectl

```bash
aws eks update-kubeconfig --name wrightnow --region us-west-2
```

#### 3. Install AWS Load Balancer Controller

```bash
# Install with Helm
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=wrightnow
```

#### 4. Update Storage Class

Use `gp3` (AWS EBS) instead of local-path-provisioner.

#### 5. Deploy to EKS

```bash
kubectl create namespace production
kubectl apply -f k8s/base/postgres/secrets.yaml -n production
kubectl apply -f k8s/base/authentik/secrets.yaml -n production
kubectl apply -k k8s/overlays/production
```

### Azure Kubernetes Service (AKS)

#### 1. Create AKS Cluster

```bash
# Create resource group
az group create --name wrightnow-rg --location eastus

# Create AKS cluster
az aks create \
  --resource-group wrightnow-rg \
  --name wrightnow \
  --node-count 3 \
  --enable-addons monitoring \
  --generate-ssh-keys
```

#### 2. Configure kubectl

```bash
az aks get-credentials --resource-group wrightnow-rg --name wrightnow
```

#### 3. Install Application Gateway Ingress Controller

```bash
# Follow Azure documentation
# https://docs.microsoft.com/en-us/azure/application-gateway/ingress-controller-install-new
```

#### 4. Update Storage Class

Use Azure Disk instead of local-path-provisioner.

#### 5. Deploy to AKS

```bash
kubectl create namespace production
kubectl apply -f k8s/base/postgres/secrets.yaml -n production
kubectl apply -f k8s/base/authentik/secrets.yaml -n production
kubectl apply -k k8s/overlays/production
```

## Configuration Management

### Environment-Specific Configuration

Use Kustomize overlays for different environments:

```
k8s/
├── base/              # Base configuration
└── overlays/
    ├── local/         # Local development (kind)
    ├── staging/       # Staging environment (cloud)
    └── production/    # Production environment (cloud)
```

### Secrets Management

#### For Development (Local)
- Use `secrets.example.yaml` as templates
- Store real secrets in `secrets.yaml` (gitignored)

#### For Production (Cloud)
Options:
1. **Kubernetes Secrets** (encrypted at rest)
2. **External Secrets Operator** (integrates with cloud secret managers)
3. **Sealed Secrets** (encrypted secrets in Git)

**Recommended: External Secrets Operator**

```bash
# Install External Secrets Operator
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets -n external-secrets-system --create-namespace

# Create SecretStore (example for AWS Secrets Manager)
kubectl apply -f - <<EOF
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secrets-manager
  namespace: production
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-west-2
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets
EOF
```

## Security Best Practices

### 1. Network Policies

Implement network policies to restrict pod-to-pod communication:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: postgres-network-policy
  namespace: staging-infra
spec:
  podSelector:
    matchLabels:
      app: postgres
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: core-backend
      ports:
        - protocol: TCP
          port: 5432
```

### 2. Pod Security Standards

Apply Pod Security Standards:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: staging-infra
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

### 3. RBAC

Implement Role-Based Access Control:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: staging-infra
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list"]
```

### 4. Secret Rotation

Rotate secrets regularly:

```bash
# Generate new secret
NEW_SECRET=$(openssl rand -base64 32)

# Update Kubernetes secret
kubectl create secret generic postgres-secrets \
  --from-literal=POSTGRES_PASSWORD="$NEW_SECRET" \
  --dry-run=client -o yaml | kubectl apply -f -

# Restart pods to pick up new secret
kubectl rollout restart statefulset/postgres -n staging-infra
```

## Monitoring and Logging

### Prometheus & Grafana

```bash
# Install Prometheus Operator
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring --create-namespace
```

### Logging with ELK Stack

```bash
# Install Elastic Stack
helm repo add elastic https://helm.elastic.co
helm install elasticsearch elastic/elasticsearch -n logging --create-namespace
helm install kibana elastic/kibana -n logging
helm install filebeat elastic/filebeat -n logging
```

### Custom Metrics

Expose application metrics:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: core-backend-metrics
  labels:
    app: core-backend
spec:
  ports:
    - port: 9090
      name: metrics
  selector:
    app: core-backend
```

## Troubleshooting

### Common Issues

#### Pods Stuck in Pending State

**Cause**: Insufficient resources

**Solution**:
```bash
# Check node resources
kubectl top nodes

# Describe pod to see events
kubectl describe pod <pod-name> -n staging-infra

# Scale down if needed
kubectl scale deployment authentik-server --replicas=1 -n staging-infra
```

#### ImagePullBackOff Error

**Cause**: Cannot pull container image

**Solution**:
```bash
# Check image name in deployment
kubectl get deployment <deployment-name> -o yaml | grep image

# Check image pull secrets
kubectl get secrets -n staging-infra

# Manually pull image to verify
docker pull <image-name>
```

#### CrashLoopBackOff Error

**Cause**: Application crashes on startup

**Solution**:
```bash
# Check pod logs
kubectl logs <pod-name> -n staging-infra

# Check previous logs if pod restarted
kubectl logs <pod-name> -n staging-infra --previous

# Describe pod for events
kubectl describe pod <pod-name> -n staging-infra
```

#### Ingress Not Working

**Cause**: Ingress controller not installed or misconfigured

**Solution**:
```bash
# Verify ingress controller is running
kubectl get pods -n ingress-nginx

# Check ingress resource
kubectl get ingress -n staging-infra
kubectl describe ingress <ingress-name> -n staging-infra

# Test direct service access
kubectl port-forward svc/authentik-server 9000:9000 -n staging-infra
curl http://localhost:9000/api/v3/
```

#### Database Connection Failed

**Cause**: Wrong connection string or secrets

**Solution**:
```bash
# Verify secret exists
kubectl get secret postgres-secrets -n staging-infra

# Decode secret to verify values
kubectl get secret postgres-secrets -n staging-infra -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 -d

# Test connection from pod
kubectl exec -it deployment/core-backend -n staging-core -- sh
# Inside pod:
psql -h postgres.staging-infra -U postgres -d wrightnow
```

### Debug Commands

```bash
# Get all resources in namespace
kubectl get all -n staging-infra

# Watch pod status
kubectl get pods -n staging-infra --watch

# Stream logs
kubectl logs -f <pod-name> -n staging-infra

# Execute command in pod
kubectl exec -it <pod-name> -n staging-infra -- /bin/sh

# Copy files from pod
kubectl cp staging-infra/<pod-name>:/path/to/file ./local-file

# Port forward for debugging
kubectl port-forward <pod-name> 8080:8080 -n staging-infra
```

## Next Steps

1. **Set up CI/CD** with GitHub Actions (Sprint 0 Task 1.2)
2. **Configure ArgoCD** for GitOps (Sprint 0 Task 1.5)
3. **Deploy application services** (Sprint 0 Tasks 3.1-3.3)
4. **Set up monitoring** (Post-MVP)
5. **Implement auto-scaling** (Post-MVP)

## Additional Resources

- [Kubernetes Official Documentation](https://kubernetes.io/docs/)
- [kind Documentation](https://kind.sigs.k8s.io/)
- [Kustomize Tutorial](https://kubectl.docs.kubernetes.io/guides/introduction/kustomize/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [CNCF Landscape](https://landscape.cncf.io/)
