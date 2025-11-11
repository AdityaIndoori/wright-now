# Design Document: Kubernetes Staging Cluster Configuration

**Change ID:** `2025-11-11-add-kubernetes-staging-cluster`  
**Status:** Proposed  
**Created:** 2025-11-11

## Overview

This design document details the architectural decisions for implementing a local Kubernetes staging cluster using kind (Kubernetes in Docker). The cluster will mirror the existing docker-compose development environment while providing a clear path to cloud production deployment.

## Design Principles

1. **Local-First Development:** Optimize for fast local development with minimal setup
2. **Production Parity:** Maintain consistency between local and cloud deployments
3. **Gradual Complexity:** Start simple, add sophistication as needed
4. **Documentation-First:** Every decision documented for future team members
5. **Cloud-Agnostic:** Support migration to GKE, EKS, or AKS with minimal changes

## Key Architectural Decisions

### Decision 1: kind (Kubernetes in Docker) over Alternatives

**Context:**  
Need a local Kubernetes solution that balances ease of use, performance, and production fidelity.

**Options Considered:**

| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| **kind** | ✅ Official K8s SIG project<br>✅ Fast startup (~30s)<br>✅ Docker-native<br>✅ CI-friendly<br>✅ Multi-node support | ⚠️ Requires Docker | **SELECTED** |
| **Minikube** | ✅ Most mature<br>✅ Multiple drivers | ❌ Slower startup<br>❌ VM overhead<br>❌ Heavier resource usage | Rejected |
| **k3d** | ✅ Lightweight<br>✅ Fast | ❌ Less official support<br>❌ k3s != k8s | Rejected |
| **Docker Desktop K8s** | ✅ Built-in | ❌ Limited control<br>❌ Single-node only<br>❌ Not CI-friendly | Rejected |

**Decision:** kind (Kubernetes in Docker)

**Rationale:**
- Official Kubernetes SIG project ensures compatibility
- Docker-native means no VM overhead
- Excellent CI/CD support (GitHub Actions, GitLab CI)
- Can simulate multi-node production scenarios
- Same Kubernetes API as GKE/EKS/AKS

### Decision 2: Multi-Namespace Architecture

**Context:**  
Need to organize services for isolation, security, and clarity.

**Namespace Strategy:**

```
staging-infra/      # Infrastructure services (PostgreSQL, Redis, Authentik)
├── postgres
├── redis  
├── authentik-postgres
├── authentik-redis
├── authentik-server
└── authentik-worker

staging-core/       # Core Backend service (Nest.js) - Sprint 0 Task 3.1
staging-ai/         # AI Service (FastAPI) - Sprint 0 Task 3.2
staging-web/        # Web Client (React) - Sprint 0 Task 3.3
```

**Rationale:**
1. **Clear Separation of Concerns:** Infrastructure vs. application services
2. **Independent RBAC:** Different teams can have different permissions
3. **Resource Quotas:** Can limit resources per namespace
4. **Monitoring:** Easier to track metrics by namespace
5. **Future-Ready:** Placeholder namespaces signal architectural intent

**Alternative Considered:** Single namespace for all services  
**Rejected Because:** Violates separation of concerns, harder to manage at scale

### Decision 3: Placeholder Namespaces for Future Services

**Context:**  
Services (Nest.js, FastAPI, React) don't exist yet but will be created in Sprint 0 Tasks 3.1-3.3.

**Decision:** Create placeholder namespaces (staging-core, staging-ai, staging-web) NOW

**Rationale:**
1. **Architectural Documentation:** Namespaces declare intended structure
2. **Prevents Mistakes:** Engineers know where to deploy new services
3. **Consistency:** Ensures naming conventions are followed
4. **Minimal Cost:** 3 YAML files (~10 lines each)
5. **Faster Implementation:** Future sprints don't need to create namespaces

**Documentation Strategy:**
- Label each placeholder namespace: `status: placeholder`
- Add annotations with Sprint task references
- Document in k8s/README.md with clear instructions
- Include deployment examples for each service type

**Example Namespace:**
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: staging-core
  labels:
    environment: staging
    service: core-backend
    status: placeholder
  annotations:
    description: "Core Backend service (Nest.js) - Sprint 0 Task 3.1"
    deployment-guide: "See k8s/README.md#deploying-core-backend"
```

### Decision 4: nginx-ingress Controller

**Context:**  
Need HTTP routing from localhost to services inside Kubernetes cluster.

**Options Considered:**

| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| **nginx-ingress** | ✅ Most popular<br>✅ Battle-tested<br>✅ WebSocket support<br>✅ Cloud-compatible | ⚠️ Requires setup | **SELECTED** |
| **Traefik** | ✅ Modern<br>✅ Auto-discovery | ❌ Less mature<br>❌ Different config style | Rejected |
| **HAProxy** | ✅ High performance | ❌ Complex config<br>❌ Less K8s-native | Rejected |
| **Port Forwarding** | ✅ Simple | ❌ No routing<br>❌ Manual per service | Rejected |

**Decision:** nginx-ingress-controller

**Rationale:**
- Industry standard with extensive documentation
- Works seamlessly with kind (LoadBalancer support)
- Compatible with all cloud providers (GKE, EKS, AKS)
- Supports WebSocket (critical for real-time collaboration in Sprint 4)
- Familiar to most developers

**Ingress Routing Design:**
```
http://localhost/          → staging-web (React app) - Future
http://localhost/api/      → staging-core (API Gateway) - Future
http://localhost/auth/     → authentik-server (OIDC IdP)
http://localhost/ai/       → staging-ai (AI Service) - Future
```

### Decision 5: StatefulSet vs. Deployment Strategy

**Context:**  
Different services have different persistence and identity requirements.

**Service Classification:**

| Service | Type | Rationale |
|---------|------|-----------|
| **postgres** | StatefulSet | Requires stable network identity and persistent storage |
| **authentik-postgres** | StatefulSet | Same as above |
| **redis** | Deployment + PVC | Stateless replicas, but needs persistence for AOF |
| **authentik-redis** | Deployment + PVC | Same as above |
| **authentik-server** | Deployment | Stateless, horizontally scalable |
| **authentik-worker** | Deployment | Stateless background tasks |

**StatefulSet Characteristics:**
- Stable pod name (postgres-0, postgres-1)
- Ordered startup/shutdown
- Stable network identity via Headless Service
- PersistentVolumeClaim per pod

**Deployment Characteristics:**
- Random pod names (redis-7d8f6c-xz9s)
- Parallel startup/shutdown
- Load balanced via Service
- Optional PersistentVolumeClaim (shared)

**Decision Rationale:**
- Databases require StatefulSet for stable identity
- Caches can use Deployment (simpler, faster rollouts)
- Application services use Deployment (enables rolling updates)

### Decision 6: Kustomize for Configuration Management

**Context:**  
Need to manage environment-specific configurations (local, staging, production).

**Options Considered:**

| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| **Kustomize** | ✅ Built into kubectl<br>✅ Declarative patches<br>✅ No templating | ⚠️ Learning curve | **SELECTED** |
| **Helm** | ✅ Package manager<br>✅ Mature | ❌ Templating complexity<br>❌ Overkill for our needs | Rejected |
| **Jsonnet** | ✅ Powerful | ❌ New language<br>❌ Complex | Rejected |
| **Manual YAML** | ✅ Simple | ❌ Copy-paste errors<br>❌ Hard to maintain | Rejected |

**Decision:** Kustomize

**Kustomize Structure:**
```
k8s/
├── base/                   # Reusable base manifests
│   ├── kustomization.yaml
│   ├── namespaces/
│   ├── postgres/
│   ├── redis/
│   └── authentik/
├── overlays/
│   ├── local/              # Local development (kind)
│   │   ├── kustomization.yaml
│   │   └── kind-cluster-config.yaml
│   ├── staging/            # Cloud staging (GKE/EKS/AKS) - Future
│   │   └── kustomization.yaml
│   └── production/         # Production - Future
│       └── kustomization.yaml
└── kustomization.yaml
```

**Rationale:**
- Native kubectl support (`kubectl apply -k`)
- DRY principle: Write once, patch for environments
- No templating language to learn (pure YAML)
- Industry standard for Kubernetes configuration
- Easy to understand for new developers

**Example Local Overlay:**
```yaml
# k8s/overlays/local/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

bases:
  - ../../base

# Override resource limits for local development
patches:
  - target:
      kind: Deployment
    patch: |-
      - op: replace
        path: /spec/template/spec/containers/0/resources/limits/memory
        value: 512Mi
```

### Decision 7: Secrets Management - Kubernetes Secrets (Basic)

**Context:**  
Need to manage credentials (database passwords, API keys) securely.

**Options Considered:**

| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| **Kubernetes Secrets** | ✅ Built-in<br>✅ Simple<br>✅ No dependencies | ⚠️ Base64 only (not encrypted) | **SELECTED for MVP** |
| **External Secrets Operator** | ✅ Syncs from external vaults | ❌ Adds complexity<br>❌ Requires external service | Rejected for now |
| **HashiCorp Vault** | ✅ Enterprise-grade | ❌ Complex setup<br>❌ Overkill for MVP | Rejected for now |
| **Cloud Provider Secrets** | ✅ Native integration | ❌ Vendor lock-in<br>❌ Not local-friendly | Rejected for now |

**Decision:** Kubernetes Secrets (basic) for MVP

**Rationale:**
- Simple to implement and understand
- No external dependencies
- Sufficient for local development
- Can migrate to External Secrets Operator post-MVP

**Security Model:**
```yaml
# k8s/base/authentik/secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: authentik-secrets
  namespace: staging-infra
type: Opaque
data:
  AUTHENTIK_SECRET_KEY: <base64-encoded>
  AUTHENTIK_POSTGRES_PASSWORD: <base64-encoded>
```

**Security Practices:**
- `.gitignore` all Secret YAML files with real credentials
- Provide `.example` files with placeholder values
- Document rotation process in k8s/README.md
- Plan migration to External Secrets Operator post-MVP

### Decision 8: Resource Requests and Limits

**Context:**  
Need to prevent resource starvation and enable proper scheduling.

**Resource Strategy:**

| Service | CPU Request | CPU Limit | Memory Request | Memory Limit |
|---------|-------------|-----------|----------------|--------------|
| postgres | 250m | 500m | 256Mi | 512Mi |
| redis | 100m | 250m | 128Mi | 256Mi |
| authentik-postgres | 250m | 500m | 256Mi | 512Mi |
| authentik-redis | 100m | 250m | 128Mi | 256Mi |
| authentik-server | 250m | 500m | 256Mi | 512Mi |
| authentik-worker | 100m | 250m | 128Mi | 256Mi |

**Rationale:**
1. **Prevent Resource Starvation:** Guaranteed minimum resources
2. **Enable Scheduling:** Kubernetes can optimize pod placement
3. **Cost Control:** Prevents runaway resource usage
4. **HPA Foundation:** Required for Horizontal Pod Autoscaling (future)
5. **Conservative Values:** Safe for 8GB RAM, 4-core machines

**Request vs. Limit:**
- **Request:** Guaranteed minimum (used for scheduling)
- **Limit:** Maximum allowed (pod killed if exceeded)

**Local Development Considerations:**
- Conservative limits allow running full stack on laptop
- Production overlays can increase limits

### Decision 9: Health Checks and Readiness Probes

**Context:**  
Need to ensure services are healthy and ready to receive traffic.

**Probe Strategy:**

| Service | Liveness Probe | Readiness Probe | Startup Probe |
|---------|----------------|-----------------|---------------|
| postgres | `pg_isready -U postgres` | `pg_isready -U postgres` | None (fast startup) |
| redis | `redis-cli ping` | `redis-cli ping` | None (fast startup) |
| authentik-server | HTTP /api/v3/ | HTTP /api/v3/ | HTTP /api/v3/ (slow) |
| authentik-worker | None (worker) | None (worker) | None |

**Probe Types Explained:**
- **Liveness:** Is the service alive? (Restart if failing)
- **Readiness:** Is the service ready for traffic? (Don't route if not ready)
- **Startup:** Special probe for slow-starting services (e.g., Authentik)

**Example Configuration:**
```yaml
livenessProbe:
  exec:
    command: ["pg_isready", "-U", "postgres"]
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3

readinessProbe:
  exec:
    command: ["pg_isready", "-U", "postgres"]
  initialDelaySeconds: 5
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 2
```

**Rationale:**
- Kubernetes automatically restarts unhealthy pods
- Traffic only routes to ready pods
- Prevents cascading failures

### Decision 10: Data Persistence Strategy

**Context:**  
Need to persist data across pod restarts and cluster recreation.

**Persistence Design:**

| Service | Storage Type | Size | Retention |
|---------|--------------|------|-----------|
| postgres | PersistentVolumeClaim | 10Gi | Retained (manual delete) |
| redis | PersistentVolumeClaim | 2Gi | Retained (manual delete) |
| authentik-postgres | PersistentVolumeClaim | 5Gi | Retained (manual delete) |
| authentik-redis | PersistentVolumeClaim | 1Gi | Retained (manual delete) |
| authentik-media | PersistentVolumeClaim | 2Gi | Retained (manual delete) |

**PersistentVolumeClaim Behavior:**
- **Local (kind):** Uses local-path-provisioner (Docker volumes)
- **Cloud (GKE):** Uses gce-pd (Google Persistent Disk)
- **Cloud (EKS):** Uses ebs-csi-driver (AWS Elastic Block Store)
- **Cloud (AKS):** Uses azure-disk (Azure Managed Disk)

**Retention Policy:**
- `persistentVolumeReclaimPolicy: Retain`
- PVCs survive pod/deployment deletion
- Must manually delete PVCs to reset state
- Prevents accidental data loss

**Example PVC:**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-data
  namespace: staging-infra
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: standard  # kind default
```

### Decision 11: Service Discovery and Networking

**Context:**  
Services need to communicate with each other inside the cluster.

**Service Types:**

| Service | Type | Purpose |
|---------|------|---------|
| postgres | ClusterIP | Internal only (no external access) |
| redis | ClusterIP | Internal only |
| authentik-server | ClusterIP | Accessed via Ingress |
| authentik-worker | None | No service needed (worker) |
| nginx-ingress | LoadBalancer | External access point |

**Service Discovery:**
- DNS: `<service-name>.<namespace>.svc.cluster.local`
- Short form: `<service-name>` (within same namespace)
- Example: `postgres.staging-infra.svc.cluster.local`

**ClusterIP vs. LoadBalancer:**
- **ClusterIP:** Internal cluster IP (default)
- **LoadBalancer:** External IP (only for ingress)

**Rationale:**
- ClusterIP for all internal services (security)
- LoadBalancer only for ingress controller (single entry point)
- DNS-based discovery (no hardcoded IPs)

### Decision 12: Cloud Migration Path

**Context:**  
Need clear path from local kind cluster to cloud production.

**Migration Strategy:**

**Step 1: Create Cloud Cluster**
```bash
# GKE
gcloud container clusters create wrightnow-staging \
  --zone us-central1-a \
  --num-nodes 3

# EKS
eksctl create cluster --name wrightnow-staging \
  --region us-west-2 \
  --nodes 3

# AKS
az aks create --resource-group wrightnow \
  --name wrightnow-staging \
  --node-count 3
```

**Step 2: Update Kustomize Overlay**
```yaml
# k8s/overlays/staging/kustomization.yaml
bases:
  - ../../base

# Cloud-specific patches
patches:
  - target:
      kind: PersistentVolumeClaim
    patch: |-
      - op: replace
        path: /spec/storageClassName
        value: gce-pd  # or ebs-csi, azure-disk
  
  - target:
      kind: Deployment
    patch: |-
      - op: replace
        path: /spec/template/spec/containers/0/resources/limits/memory
        value: 1Gi  # Increase for production
```

**Step 3: Deploy**
```bash
kubectl apply -k k8s/overlays/staging
```

**Key Differences:**
| Aspect | Local (kind) | Cloud (GKE/EKS/AKS) |
|--------|-------------|---------------------|
| Storage | local-path-provisioner | gce-pd / ebs / azure-disk |
| LoadBalancer | MetalLB (kind) | Cloud LoadBalancer |
| Resources | Small (laptop) | Large (cloud VMs) |
| HA | Single node | Multi-node |

**Rationale:**
- Same Kubernetes manifests work everywhere
- Only environment-specific details in overlays
- No application code changes required

## Testing Strategy

### Unit Testing (Pre-deployment)

- Validate YAML syntax: `kubectl apply --dry-run=client -k k8s/base`
- Validate against K8s schema: `kubeval k8s/base/**/*.yaml`
- Security scanning: `kubesec scan k8s/base/**/*.yaml`

### Integration Testing (Post-deployment)

```bash
# All pods running
kubectl get pods -n staging-infra

# Services accessible
kubectl exec -it postgres-0 -n staging-infra -- psql -U postgres -c "\l"
kubectl exec -it redis-0 -n staging-infra -- redis-cli ping

# Ingress working
curl http://localhost/auth/api/v3/
```

### E2E Testing (Full Workflow)

1. Create cluster: `./scripts/k8s-setup.sh`
2. Deploy services: `./scripts/k8s-deploy.sh`
3. Verify all pods healthy: `kubectl get pods -A`
4. Test Authentik UI: Open http://localhost/auth/
5. Teardown: `./scripts/k8s-teardown.sh`

## Future Enhancements (Post-MVP)

### Phase 1: Observability
- Prometheus for metrics
- Grafana for dashboards
- ELK/EFK for logging
- Jaeger for distributed tracing

### Phase 2: Advanced Orchestration
- Horizontal Pod Autoscaling (HPA)
- Vertical Pod Autoscaling (VPA)
- PodDisruptionBudgets for HA
- Network Policies for security

### Phase 3: Service Mesh
- Istio or Linkerd
- mTLS between services
- Traffic shaping
- Circuit breakers

## References

- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [kind Best Practices](https://kind.sigs.k8s.io/docs/user/quick-start/)
- [Kustomize Documentation](https://kustomize.io/)
- [12-Factor App Methodology](https://12factor.net/)

## Appendix: Decision Log

| Date | Decision | Rationale | Status |
|------|----------|-----------|--------|
| 2025-11-11 | Use kind over Minikube | Faster, Docker-native, better CI support | ✅ Approved |
| 2025-11-11 | Multi-namespace architecture | Separation of concerns, better organization | ✅ Approved |
| 2025-11-11 | Create placeholder namespaces | Document intent, prevent mistakes | ✅ Approved |
| 2025-11-11 | nginx-ingress over Traefik | Industry standard, better docs | ✅ Approved |
| 2025-11-11 | Kustomize over Helm | Simpler, no templating, built-in | ✅ Approved |
| 2025-11-11 | Basic K8s Secrets | Simple, no dependencies, good for MVP | ✅ Approved |
