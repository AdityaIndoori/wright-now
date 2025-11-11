# Kubernetes Configuration for WRight Now

This directory contains Kubernetes manifests for deploying WRight Now to a local kind cluster or cloud providers.

## Quick Start

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (with Kubernetes enabled)
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) - Kubernetes in Docker
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - Kubernetes CLI

### Setup & Deploy

```bash
# 1. Create the kind cluster
./scripts/k8s-setup.sh

# 2. Deploy all services
./scripts/k8s-deploy.sh

# 3. Access Authentik
open http://localhost/auth/
```

### Teardown

```bash
# Delete the cluster
./scripts/k8s-teardown.sh
```

## Architecture

```
kind Cluster (wrightnow)
├── staging-infra/          # Infrastructure services (DEPLOYED)
│   ├── postgres            # Main database with pg_vector
│   ├── redis               # Cache for sessions/permissions
│   ├── authentik-postgres  # Authentik database
│   ├── authentik-redis     # Authentik cache
│   ├── authentik-server    # OIDC IdP server (2 replicas)
│   └── authentik-worker    # Background tasks
├── staging-core/           # PLACEHOLDER for Nest.js Core Backend
├── staging-ai/             # PLACEHOLDER for FastAPI AI Service
└── staging-web/            # PLACEHOLDER for React Web Client
```

## Directory Structure

```
k8s/
├── README.md                              # This file
├── base/                                  # Base Kubernetes manifests
│   ├── kustomization.yaml                # Base Kustomize config
│   ├── namespaces/                       # Namespace definitions
│   │   ├── staging-infra.yaml           # Active infrastructure namespace
│   │   ├── staging-core.yaml            # Placeholder for Core Backend
│   │   ├── staging-ai.yaml              # Placeholder for AI Service
│   │   └── staging-web.yaml             # Placeholder for Web Client
│   ├── postgres/                         # Main PostgreSQL database
│   │   ├── statefulset.yaml
│   │   ├── service.yaml
│   │   ├── configmap.yaml               # Init scripts
│   │   └── secrets.example.yaml         # Secret template
│   ├── redis/                            # Main Redis cache
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── pvc.yaml
│   ├── authentik/                        # Authentik IdP
│   │   ├── postgres-statefulset.yaml
│   │   ├── postgres-service.yaml
│   │   ├── redis-deployment.yaml
│   │   ├── redis-service.yaml
│   │   ├── pvcs.yaml                    # PVCs for Redis and media
│   │   ├── server-deployment.yaml
│   │   ├── worker-deployment.yaml
│   │   ├── services.yaml
│   │   ├── ingress.yaml
│   │   └── secrets.example.yaml         # Secret template
│   └── ingress/
│       └── nginx-ingress-controller.yaml # Documentation
└── overlays/
    └── local/                            # Local development overlay
        ├── kind-cluster-config.yaml      # kind cluster configuration
        └── kustomization.yaml            # Local Kustomize config
```

## Deploying Application Services

### Deploying Core Backend (Sprint 0 Task 3.1)

When you're ready to deploy the Nest.js Core Backend:

1. **Create deployment manifests** in a new directory:
   ```bash
   mkdir -p k8s/base/core-backend
   ```

2. **Create `k8s/base/core-backend/deployment.yaml`**:
   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: core-backend
     namespace: staging-core
   spec:
     replicas: 2
     selector:
       matchLabels:
         app: core-backend
     template:
       metadata:
         labels:
           app: core-backend
       spec:
         containers:
           - name: core-backend
             image: wrightnow/core-backend:latest
             ports:
               - containerPort: 3000
             env:
               - name: DATABASE_URL
                 value: postgresql://postgres:postgres@postgres.staging-infra:5432/wrightnow
               - name: REDIS_URL
                 value: redis://redis.staging-infra:6379
             resources:
               requests:
                 cpu: "250m"
                 memory: "256Mi"
               limits:
                 cpu: "500m"
                 memory: "512Mi"
   ```

3. **Create `k8s/base/core-backend/service.yaml`**:
   ```yaml
   apiVersion: v1
   kind: Service
   metadata:
     name: core-backend
     namespace: staging-core
   spec:
     type: ClusterIP
     ports:
       - port: 3000
         targetPort: 3000
     selector:
       app: core-backend
   ```

4. **Update Ingress** to route `/api/` to the Core Backend:
   ```yaml
   # Add to k8s/base/ingress/app-ingress.yaml
   - path: /api(/|$)(.*)
     pathType: ImplementationSpecific
     backend:
       service:
         name: core-backend
         port:
           number: 3000
   ```

5. **Add to Kustomize** in `k8s/base/kustomization.yaml`:
   ```yaml
   resources:
     # ... existing resources
     - core-backend/deployment.yaml
     - core-backend/service.yaml
   ```

6. **Deploy**:
   ```bash
   kubectl apply -k k8s/overlays/local
   ```

### Deploying AI Service (Sprint 0 Task 3.2)

Follow the same pattern as Core Backend:

1. Create `k8s/base/ai-service/` directory
2. Create Deployment and Service manifests (namespace: `staging-ai`)
3. Update Ingress to route `/ai/` to the AI Service
4. Add to Kustomize
5. Deploy

**Example Ingress path**:
```yaml
- path: /ai(/|$)(.*)
  pathType: ImplementationSpecific
  backend:
    service:
      name: ai-service
      port:
        number: 8000
```

### Deploying Web Client (Sprint 0 Task 3.3)

For the React web client:

1. Create `k8s/base/web-client/` directory
2. Create Deployment with nginx serving static files (namespace: `staging-web`)
3. Create Service
4. Update Ingress to route `/` to the Web Client
5. Add to Kustomize
6. Deploy

**Example Ingress path**:
```yaml
- path: /
  pathType: Prefix
  backend:
    service:
      name: web-client
      port:
        number: 80
```

## Managing Secrets

### Creating Secrets

Secrets are stored as base64-encoded values in Kubernetes Secret objects.

1. **Copy example files**:
   ```bash
   cp k8s/base/postgres/secrets.example.yaml k8s/base/postgres/secrets.yaml
   cp k8s/base/authentik/secrets.example.yaml k8s/base/authentik/secrets.yaml
   ```

2. **Generate strong secrets**:
   ```bash
   # Generate a random secret key
   openssl rand -base64 32
   
   # Base64 encode a value
   echo -n "your-value" | base64
   ```

3. **Edit `secrets.yaml` files** with your base64-encoded values

4. **Apply secrets**:
   ```bash
   kubectl apply -f k8s/base/postgres/secrets.yaml
   kubectl apply -f k8s/base/authentik/secrets.yaml
   ```

**IMPORTANT**: Never commit `secrets.yaml` files to Git! They are already in `.gitignore`.

## Resource Requirements

### Minimum System Requirements

- **RAM**: 8GB (16GB recommended)
- **CPU**: 4 cores (6+ cores recommended)
- **Disk**: 20GB free space

### Per-Service Resource Usage

| Service | CPU Request | Memory Request | CPU Limit | Memory Limit |
|---------|-------------|----------------|-----------|--------------|
| PostgreSQL | 250m | 256Mi | 500m | 512Mi |
| Redis | 100m | 128Mi | 250m | 256Mi |
| Authentik Postgres | 250m | 256Mi | 500m | 512Mi |
| Authentik Redis | 100m | 128Mi | 250m | 256Mi |
| Authentik Server (×2) | 250m | 256Mi | 500m | 512Mi |
| Authentik Worker | 100m | 128Mi | 250m | 256Mi |
| **Total** | **1.3 CPU** | **1.5Gi** | **3 CPU** | **3Gi** |

## Troubleshooting

### Pods not starting

```bash
# Check pod status
kubectl get pods -n staging-infra

# Check pod logs
kubectl logs -n staging-infra <pod-name>

# Describe pod for events
kubectl describe pod -n staging-infra <pod-name>
```

### Ingress not working

```bash
# Check ingress status
kubectl get ingress -n staging-infra

# Check ingress-nginx logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller

# Verify nginx-ingress is running
kubectl get pods -n ingress-nginx
```

### Database connection issues

```bash
# Test PostgreSQL connection
kubectl exec -it postgres-0 -n staging-infra -- psql -U postgres -c "SELECT 1"

# Test Redis connection
kubectl exec -it deployment/redis -n staging-infra -- redis-cli ping
```

### Secrets not found

```bash
# Check if secrets exist
kubectl get secrets -n staging-infra

# Create secrets from example files
cp k8s/base/postgres/secrets.example.yaml k8s/base/postgres/secrets.yaml
kubectl apply -f k8s/base/postgres/secrets.yaml
```

### Cluster won't start

```bash
# Check Docker Desktop is running
docker ps

# Delete and recreate cluster
./scripts/k8s-teardown.sh
./scripts/k8s-setup.sh
```

## Cloud Migration

### Migrating to GKE (Google Kubernetes Engine)

1. **Create GKE cluster**:
   ```bash
   gcloud container clusters create wrightnow \
     --zone us-central1-a \
     --num-nodes 3 \
     --machine-type n1-standard-2
   ```

2. **Create production overlay**:
   ```bash
   mkdir -p k8s/overlays/production
   ```

3. **Update Kustomize config** (`k8s/overlays/production/kustomization.yaml`):
   ```yaml
   bases:
     - ../../base
   
   patches:
     - path: gke-storage-class.yaml
     - path: gke-ingress.yaml
   ```

4. **Replace local-path-provisioner with GCE Persistent Disks**
5. **Replace nginx-ingress with GCE Load Balancer**
6. **Deploy**:
   ```bash
   kubectl apply -k k8s/overlays/production
   ```

### Migrating to EKS (AWS Elastic Kubernetes Service)

Similar to GKE, but use:
- EBS volumes instead of local-path-provisioner
- AWS Load Balancer Controller instead of nginx-ingress

### Migrating to AKS (Azure Kubernetes Service)

Similar to GKE, but use:
- Azure Disk instead of local-path-provisioner
- Azure Application Gateway instead of nginx-ingress

## Additional Resources

- [kind Documentation](https://kind.sigs.k8s.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Kustomize Documentation](https://kustomize.io/)
- [nginx-ingress Documentation](https://kubernetes.github.io/ingress-nginx/)
- [Authentik Documentation](https://goauthentik.io/docs/)

## Next Steps

1. **Sprint 0 Task 1.5**: Set up ArgoCD for GitOps deployment
2. **Sprint 0 Task 3.1**: Deploy Nest.js Core Backend
3. **Sprint 0 Task 3.2**: Deploy FastAPI AI Service
4. **Sprint 0 Task 3.3**: Deploy React Web Client
