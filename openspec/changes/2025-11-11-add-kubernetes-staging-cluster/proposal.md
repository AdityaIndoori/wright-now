# Proposal: Add Kubernetes Staging Cluster Configuration

**Change ID:** `2025-11-11-add-kubernetes-staging-cluster`  
**Status:** Proposed  
**Created:** 2025-11-11  
**Sprint:** Sprint 0 - Task 1.4

## Summary

Create a local Kubernetes staging cluster configuration using kind (Kubernetes in Docker) that mirrors the docker-compose development environment and provides a clear migration path to cloud providers (GKE/EKS/AKS). The cluster will use multiple namespaces for service isolation and deploy all infrastructure services (PostgreSQL, Redis, Authentik) with proper persistence, health checks, and ingress configuration.

## Motivation

### Problem Statement

Currently, WRight Now uses docker-compose for local development. While this works well for initial development, it has limitations:

1. **Production Parity Gap:** Docker Compose does not reflect production Kubernetes deployment
2. **No Horizontal Scaling:** Cannot test multi-replica deployments or load balancing
3. **Limited Service Discovery:** Basic DNS vs. Kubernetes Service mesh
4. **No Cloud Migration Path:** Requires complete reconfiguration for cloud deployment
5. **Missing Orchestration Features:** No health checks, rolling updates, resource management

### Business Value

1. **Faster Cloud Migration:** Kubernetes manifests work locally and in production with minimal changes
2. **Better Testing:** Test production-like scenarios (pod failures, scaling, rolling updates) locally
3. **Team Enablement:** Engineers learn Kubernetes in safe local environment
4. **Cost Efficiency:** Catch deployment issues locally before expensive cloud testing
5. **Self-Hosting Ready:** Same configs work for self-hosting customers

## Goals

### Primary Goals

1. ✅ Create local Kubernetes cluster using kind that runs on developer machines
2. ✅ Deploy all docker-compose services (PostgreSQL, Redis, Authentik) to Kubernetes
3. ✅ Implement multi-namespace architecture (staging-infra, staging-core, staging-ai, staging-web)
4. ✅ Configure nginx-ingress for HTTP routing to services
5. ✅ Ensure data persistence using PersistentVolumeClaims
6. ✅ Provide comprehensive documentation for setup and future service deployments

### Secondary Goals

1. ✅ Create Kustomize overlays for environment-specific configuration (local, staging, production)
2. ✅ Document cloud migration path (GKE, EKS, AKS)
3. ✅ Implement resource requests/limits for all services
4. ✅ Configure health checks and readiness probes

### Non-Goals (Out of Scope)

1. ❌ Production cluster setup (handled in later sprints)
2. ❌ ArgoCD integration (Sprint 0 Task 1.5)
3. ❌ Monitoring/logging setup (Post-MVP)
4. ❌ Service mesh (Istio/Linkerd) - not needed for MVP
5. ❌ External Secrets Operator (using basic Kubernetes Secrets)

## Success Criteria

### Acceptance Criteria

- [ ] kind cluster can be created with single command (`./scripts/k8s-setup.sh`)
- [ ] All 6 services deploy successfully to staging-infra namespace
- [ ] Services are accessible via localhost through nginx-ingress
- [ ] Data persists across pod restarts (PostgreSQL, Redis)
- [ ] Health checks pass for all services
- [ ] Documentation exists for adding new services to cluster
- [ ] Placeholder namespaces exist for future services (staging-core, staging-ai, staging-web)
- [ ] `openspec validate --strict` passes for the change

### Performance Targets

- Cluster creation: < 2 minutes
- Service deployment: < 5 minutes
- All pods healthy: < 5 minutes after deployment
- Ingress responds: < 100ms after services ready

### Quality Targets

- Zero manual configuration steps beyond .env file
- All services have health checks
- All services have resource limits
- Documentation covers 100% of setup process

## Implementation Overview

### Architecture

```
kind Cluster
├── staging-infra/          # Infrastructure services (DEPLOYED NOW)
│   ├── postgres            # Main database with pg_vector
│   ├── redis               # Cache for sessions/permissions
│   ├── authentik-postgres  # Authentik database
│   ├── authentik-redis     # Authentik cache
│   ├── authentik-server    # OIDC IdP server
│   └── authentik-worker    # Background tasks
├── staging-core/           # PLACEHOLDER for Sprint 0 Task 3.1 (Nest.js)
├── staging-ai/             # PLACEHOLDER for Sprint 0 Task 3.2 (FastAPI)
└── staging-web/            # PLACEHOLDER for Sprint 0 Task 3.3 (React)
```

### Key Technologies

- **Cluster:** kind (Kubernetes in Docker)
- **Ingress:** nginx-ingress-controller
- **Configuration:** Kustomize for environment overlays
- **Persistence:** Local PersistentVolumes (local-path-provisioner)
- **Networking:** Services (ClusterIP, LoadBalancer)

### File Structure

```
k8s/
├── README.md                              # Kubernetes setup guide
├── base/
│   ├── kustomization.yaml
│   ├── namespaces/
│   │   ├── staging-infra.yaml
│   │   ├── staging-core.yaml             # PLACEHOLDER
│   │   ├── staging-ai.yaml               # PLACEHOLDER
│   │   └── staging-web.yaml              # PLACEHOLDER
│   ├── postgres/
│   │   ├── statefulset.yaml
│   │   ├── service.yaml
│   │   ├── pvc.yaml
│   │   └── configmap.yaml
│   ├── redis/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── pvc.yaml
│   ├── authentik/
│   │   ├── postgres-statefulset.yaml
│   │   ├── redis-deployment.yaml
│   │   ├── server-deployment.yaml
│   │   ├── worker-deployment.yaml
│   │   ├── services.yaml
│   │   ├── ingress.yaml
│   │   └── secrets.yaml
│   └── ingress/
│       └── nginx-ingress-controller.yaml
├── overlays/
│   └── local/
│       ├── kustomization.yaml
│       └── kind-cluster-config.yaml
└── kustomization.yaml

scripts/
├── k8s-setup.sh                          # Create kind cluster with ingress
├── k8s-deploy.sh                         # Deploy all services
└── k8s-teardown.sh                       # Delete cluster

docs/
└── kubernetes-setup.md                   # Comprehensive setup guide
```

## Risks and Mitigations

### Risk 1: Local Machine Resources

**Risk:** kind cluster may consume significant CPU/memory on developer machines.

**Mitigation:**
- Set conservative resource limits (250m-500m CPU, 256Mi-512Mi memory per service)
- Document minimum requirements (8GB RAM, 4 CPU cores)
- Provide teardown script to easily stop cluster when not needed
- kind is more efficient than full VMs (Minikube)

### Risk 2: Docker Volume Performance

**Risk:** PersistentVolumes using local-path-provisioner may have slower I/O than native filesystem.

**Mitigation:**
- Acceptable for local development (not production)
- kind uses Docker volumes which are reasonably performant
- Document performance expectations in README
- Production will use cloud provider volumes (gce-pd, ebs)

### Risk 3: Complexity for New Developers

**Risk:** Kubernetes adds complexity compared to docker-compose.

**Mitigation:**
- Provide simple scripts (`k8s-setup.sh`, `k8s-deploy.sh`)
- Comprehensive documentation with troubleshooting
- Keep docker-compose as fallback option
- Gradual learning curve: start with pre-configured cluster

### Risk 4: Kubernetes Version Compatibility

**Risk:** kind may use different K8s version than production cloud providers.

**Mitigation:**
- Document K8s version in kind-cluster-config.yaml
- Test with multiple K8s versions if needed
- Cloud providers support wide range of K8s versions
- Use stable Kubernetes API features only

## Future Considerations

### Sprint 0 Task 3.1-3.3: Service Scaffolding

When Nest.js, FastAPI, and React services are created:
1. Placeholder namespaces (staging-core, staging-ai, staging-web) already exist
2. Follow deployment pattern from authentik services
3. Update Ingress to route traffic to new services
4. Reference `k8s/README.md` for deployment guide

### Sprint 0 Task 1.5: ArgoCD Integration

ArgoCD will:
- Monitor k8s/ directory in Git repository
- Auto-deploy changes to staging cluster
- Provide UI for deployment status
- Enable GitOps workflow

### Post-MVP: Production Cluster

Migration to cloud (GKE/EKS/AKS):
1. Create production cluster in cloud console
2. Update Kustomize overlay (`k8s/overlays/production/`)
3. Replace local-path-provisioner with cloud volumes
4. Configure cloud LoadBalancer for Ingress
5. Deploy with `kubectl apply -k k8s/overlays/production`

### Post-MVP: Advanced Features

- Horizontal Pod Autoscaling (HPA)
- Network Policies for security
- Service Mesh (Istio/Linkerd)
- Monitoring (Prometheus, Grafana)
- Logging (ELK/EFK stack)

## Related Work

### Dependencies

- ✅ **Sprint 0 Task 1.1:** GitHub repository (provides Git hosting for ArgoCD)
- ✅ **Sprint 0 Task 1.2:** CI/CD pipeline (will be extended to deploy to K8s)
- ✅ **Sprint 0 Task 1.3:** Docker Compose (source of truth for service configuration)

### Dependents

- ⏳ **Sprint 0 Task 1.5:** ArgoCD GitOps deployment (requires K8s cluster)
- ⏳ **Sprint 0 Task 3.1:** Nest.js Core Backend (will deploy to staging-core namespace)
- ⏳ **Sprint 0 Task 3.2:** FastAPI AI Service (will deploy to staging-ai namespace)
- ⏳ **Sprint 0 Task 3.3:** React Web Client (will deploy to staging-web namespace)

## References

- [kind documentation](https://kind.sigs.k8s.io/)
- [Kubernetes documentation](https://kubernetes.io/docs/)
- [nginx-ingress documentation](https://kubernetes.github.io/ingress-nginx/)
- [Kustomize documentation](https://kustomize.io/)
- WRight Now Project Requirements (ProjectDocs/ProjectRequirementsDoc.md)
- WRight Now Sprint Plan (ProjectDocs/SprintPlan.md)
