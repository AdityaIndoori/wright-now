# Design: ArgoCD GitOps Deployment Automation

**Change ID:** `add-argocd-gitops-deployment`  
**Date:** 2025-12-07

## Architecture Overview

This design document captures the architectural decisions for implementing GitOps continuous deployment using ArgoCD.

## System Context

```
┌─────────────────────────────────────────────────────────────────┐
│                         Developer Workflow                       │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                      GitHub Repository                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  Source Code │  │   K8s YAML   │  │  Kustomize   │          │
│  │   (Sprint 1+)│  │  (k8s/base/) │  │  (overlays/) │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘
                                │
                ┌───────────────┴────────────────┐
                ▼                                ▼
┌───────────────────────────┐   ┌──────────────────────────────┐
│   GitHub Actions (CI)     │   │      ArgoCD (CD)             │
│  ┌─────────────────────┐  │   │  ┌────────────────────────┐ │
│  │ Lint & Test         │  │   │  │  Application           │ │
│  │ Build Docker Images │  │   │  │  Controller            │ │
│  │ Update Manifests    │  │   │  │  (Watches Git Repo)    │ │
│  │ Push to Registry    │  │   │  └────────────────────────┘ │
│  └─────────────────────┘  │   │            │                 │
└───────────────────────────┘   │            ▼                 │
                                │  ┌────────────────────────┐ │
                                │  │  Sync Engine           │ │
                                │  │  (kubectl apply logic) │ │
                                │  └────────────────────────┘ │
                                └──────────────┬───────────────┘
                                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Kubernetes Cluster                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ PostgreSQL   │  │    Redis     │  │  Authentik   │          │
│  │              │  │              │  │              │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│  ┌──────────────────────────────────────────────────┐          │
│  │         Future: Application Services              │          │
│  │  (Core Backend, AI Service, Web Client)           │          │
│  └──────────────────────────────────────────────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

## Key Design Decisions

### Decision 1: ArgoCD vs. Flux CD

**Options Considered:**
1. **ArgoCD** - Declarative GitOps CD tool with web UI
2. **Flux CD** - Declarative GitOps CD tool (CLI-focused)
3. **Jenkins X** - CI/CD platform with GitOps
4. **Manual kubectl apply** - Continue with manual deployments

**Decision:** ArgoCD

**Rationale:**
- **Better UX:** ArgoCD provides an intuitive web UI for visualizing deployments
- **Larger community:** More active development, better documentation, more examples
- **Ease of use:** Simpler to configure and operate than Flux CD
- **Feature completeness:** Has everything we need (auto-sync, rollback, RBAC)
- **Industry adoption:** Used by many companies similar to our target market

**Trade-offs:**
- ❌ Slightly higher resource usage than Flux CD
- ❌ More opinionated about project structure
- ✅ Better developer experience
- ✅ Easier onboarding for team members

### Decision 2: Sync Frequency (3 minutes)

**Options Considered:**
1. **Real-time (webhook-based)** - Instant sync on Git push
2. **3 minutes** - ArgoCD default polling interval
3. **5 minutes** - Less frequent polling
4. **Manual only** - No automatic sync

**Decision:** 3 minutes (default)

**Rationale:**
- **Fast feedback:** 3 minutes is acceptable for most changes
- **Resource efficiency:** Not too aggressive on API server
- **Proven default:** ArgoCD's recommended starting point
- **Tunable:** Can be adjusted later if needed

**Trade-offs:**
- ❌ Not instant (max 3-minute delay)
- ✅ Lower API server load than webhooks
- ✅ Simple configuration
- ✅ Reliable (no webhook failures)

### Decision 3: Auto-Sync Strategy

**Options Considered:**
1. **Manual sync only** - Require human approval for every deploy
2. **Auto-sync with prune** - Automatic deployment and cleanup
3. **Auto-sync without prune** - Automatic deployment, manual cleanup
4. **Hybrid** - Auto-sync for staging, manual for production

**Decision:** Auto-sync with prune (staging), manual sync (production)

**Rationale:**
- **Staging environment:** Full automation for fast iteration
- **Production environment:** Manual approval for safety
- **True GitOps:** Staging matches Git automatically
- **Orphan cleanup:** Prune removes deleted resources automatically

**Implementation:**
```yaml
# Staging (auto-sync enabled)
spec:
  syncPolicy:
    automated:
      prune: true       # Delete resources removed from Git
      selfHeal: true    # Revert manual changes
    syncOptions:
      - CreateNamespace=true

# Production (manual sync)
spec:
  syncPolicy:
    syncOptions:
      - CreateNamespace=true
  # No automated: field = manual sync required
```

### Decision 4: Self-Healing Configuration

**Options Considered:**
1. **Self-healing enabled** - Revert manual kubectl changes
2. **Self-healing disabled** - Allow manual changes
3. **Conditional** - Enable for some resources, disable for others

**Decision:** Self-healing enabled for staging

**Rationale:**
- **Prevents drift:** Ensures cluster matches Git state
- **Enforces GitOps:** Discourages manual kubectl changes
- **Auditable:** All changes tracked in Git history
- **Consistent state:** No surprise manual modifications

**Trade-offs:**
- ❌ Cannot make temporary manual fixes
- ✅ Enforces best practices
- ✅ Prevents configuration drift
- ✅ Git is single source of truth

**Note:** For local development (kind cluster), self-healing can be disabled to allow experimentation.

### Decision 5: ArgoCD Installation Method

**Options Considered:**
1. **Official manifest (kubectl apply)** - Single YAML file
2. **Helm chart** - More configurable, version-managed
3. **Operator** - Kubernetes-native, custom resources
4. **ArgoCD CLI** - Command-line installation

**Decision:** Official manifest (kubectl apply)

**Rationale:**
- **Simplicity:** Single command to install
- **Reproducibility:** Version-locked manifest file
- **No dependencies:** Doesn't require Helm or Operator framework
- **Official support:** Maintained by ArgoCD team
- **GitOps-friendly:** Manifest can be committed to Git

**Installation command:**
```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### Decision 6: Ingress Configuration

**Options Considered:**
1. **NodePort** - Expose on cluster node IP:port
2. **LoadBalancer** - Cloud provider load balancer
3. **Ingress (path-based)** - Use existing NGINX Ingress at `/argocd`
4. **Port-forward** - Local-only access via kubectl

**Decision:** Ingress (path-based) at `/argocd`

**Rationale:**
- **Reuse existing Ingress:** Already have NGINX Ingress installed
- **Clean URLs:** `http://localhost/argocd` (local) or `https://staging.example.com/argocd` (cloud)
- **TLS support:** NGINX Ingress handles SSL termination
- **No extra costs:** No additional load balancer needed

**Configuration:**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
  annotations:
    nginx.ingress.kubernetes.io/ssl-passthrough: "true"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
spec:
  rules:
    - http:
        paths:
          - path: /argocd
            pathType: Prefix
            backend:
              service:
                name: argocd-server
                port:
                  name: https
```

### Decision 7: RBAC Model

**Options Considered:**
1. **Single admin user** - Everyone shares one account
2. **Admin + Developer roles** - Two-tier access
3. **Fine-grained per-app** - Different permissions per Application
4. **SSO integration** - Authentik/Keycloak integration

**Decision:** Admin + Read-Only roles (phase 1), SSO later (post-MVP)

**Rationale:**
- **Simple to start:** Two roles cover most use cases
- **Secure enough:** Admins can deploy, developers can view
- **Extensible:** Can add more roles later
- **No SSO complexity:** Defer Authentik integration to post-MVP

**RBAC Policy:**
```csv
# Admin role
p, role:admin, applications, *, */*, allow
p, role:admin, clusters, *, *, allow
p, role:admin, repositories, *, *, allow

# Read-only role
p, role:readonly, applications, get, */*, allow
p, role:readonly, applications, sync, */*, deny
p, role:readonly, repositories, get, *, allow

# User assignments
g, admin-user, role:admin
g, developer-user, role:readonly
```

### Decision 8: Application Structure

**Options Considered:**
1. **Monolithic app** - Single Application for all resources
2. **Per-namespace apps** - One Application per namespace
3. **Per-service apps** - One Application per service
4. **Logical grouping** - Group by function (infra, backend, frontend)

**Decision:** Logical grouping by function

**Rationale:**
- **Clear separation:** Infrastructure vs application services
- **Independent sync:** Can sync infrastructure without services
- **Scalable:** Easy to add new applications
- **Matches project structure:** Aligns with Kustomize overlays

**Applications:**
```
infrastructure-app     → k8s/overlays/staging (PostgreSQL, Redis, Authentik)
core-backend-app      → k8s/overlays/staging (Core Backend service)
ai-service-app        → k8s/overlays/staging (AI Service)
web-client-app        → k8s/overlays/staging (React web client)
```

## Integration Points

### 1. GitHub Actions (CI)

**Current CI workflow:**
- Runs on: Push to any branch
- Actions: Lint, test, build, push images

**New CD workflow:**
- Runs on: Push to `main` branch only
- Actions: Update Kustomize image tags, commit, push
- Triggers: ArgoCD auto-sync (via polling)

### 2. Kustomize Manifests

**Current structure:**
```
k8s/
├── base/           # Base manifests
└── overlays/
    └── local/      # Local (kind) environment
```

**New structure:**
```
k8s/
├── base/           # Base manifests
│   └── argocd/     # NEW: ArgoCD manifests
│       ├── install.yaml
│       ├── ingress.yaml
│       └── applications/
│           └── infrastructure-app.yaml
└── overlays/
    ├── local/      # Local (kind) environment
    └── staging/    # NEW: Staging environment (cloud)
```

### 3. Kubernetes Cluster

**Namespaces:**
- `argocd` - ArgoCD components (new)
- `staging-infra` - Infrastructure services (existing)
- `staging-core` - Core Backend service (future)
- `staging-ai` - AI Service (future)
- `staging-web` - Web client (future)

## Security Considerations

### 1. ArgoCD Server Access

- **Authentication:** Built-in local users (admin + read-only)
- **Authorization:** RBAC policies enforced
- **Transport:** HTTPS via Ingress (TLS termination)
- **Secrets:** Admin password stored in Kubernetes Secret

### 2. Git Repository Access

- **Method:** HTTPS with personal access token (PAT)
- **Token scope:** Read-only access to manifests
- **Stored in:** ArgoCD repository credentials (Kubernetes Secret)
- **Rotation:** Manual rotation required (document in guide)

### 3. Kubernetes API Access

- **Method:** ServiceAccount with ClusterRole
- **Permissions:** Full access to manage resources (ArgoCD controller)
- **Scoped by:** Namespace restrictions in Application manifests
- **Auditing:** All actions logged in K8s audit log

## Performance Considerations

### Resource Requirements

**ArgoCD components:**
- `argocd-server`: 128Mi-256Mi RAM, 50m-100m CPU
- `argocd-repo-server`: 128Mi-256Mi RAM, 50m-100m CPU
- `argocd-application-controller`: 256Mi-512Mi RAM, 100m-250m CPU
- `argocd-redis`: 128Mi RAM, 50m CPU

**Total overhead:** ~1GB RAM, ~0.5 CPU

**Impact:** Minimal for most clusters; may need to scale up kind cluster nodes for local development.

### Sync Performance

- **Polling interval:** 3 minutes
- **Sync time:** 10-30 seconds for typical changes
- **Max applications:** 100+ (well beyond our needs)
- **Scalability:** Horizontal scaling via replica count

## Monitoring and Observability

### ArgoCD Metrics

ArgoCD exposes Prometheus metrics:
- `argocd_app_sync_total` - Total syncs per Application
- `argocd_app_sync_status` - Current sync status
- `argocd_app_health_status` - Application health status

**Note:** Prometheus integration is post-MVP.

### Logs

- **ArgoCD server logs:** `kubectl logs -n argocd deployment/argocd-server`
- **Application controller logs:** `kubectl logs -n argocd deployment/argocd-application-controller`
- **Sync operation logs:** Visible in ArgoCD UI per Application

## Disaster Recovery

### Backup Strategy

- **Git as backup:** All manifests in Git (primary backup)
- **ArgoCD state:** Can be restored from Git
- **Secrets:** Not in Git; must be backed up separately

### Recovery Procedure

1. Reinstall ArgoCD in new cluster
2. Configure repository credentials
3. Create Applications pointing to Git
4. ArgoCD syncs all resources from Git
5. Restore secrets from secure backup

**Recovery Time:** ~30 minutes

## Future Enhancements (Post-MVP)

### Phase 2 (Post-Sprint 12)

- **ArgoCD High Availability:** Multiple replicas for production
- **SSO Integration:** Authentik OIDC for single sign-on
- **Prometheus Monitoring:** Metrics and alerting
- **ApplicationSets:** Dynamic Application generation

### Phase 3 (V1.1)

- **Image Updater:** Auto-update image tags on new builds
- **Webhooks:** Replace polling with push-based sync
- **Multi-cluster:** Deploy to multiple environments
- **Progressive Delivery:** Canary deployments with Argo Rollouts

## References

- [ArgoCD Architecture Documentation](https://argo-cd.readthedocs.io/en/stable/operator-manual/architecture/)
- [ArgoCD Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)
- [GitOps Principles](https://opengitops.dev/)
