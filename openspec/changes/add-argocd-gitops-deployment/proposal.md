# Proposal: Add ArgoCD GitOps Deployment Automation

**Change ID:** `add-argocd-gitops-deployment`  
**Date:** 2025-12-07  
**Status:** Proposed  
**Sprint:** Sprint 0, Task 1.5

## Why

Manual Kubernetes deployments via scripts are error-prone and lack visibility. ArgoCD provides automated GitOps continuous deployment, ensuring cluster state matches Git, with drift detection, easy rollback, and a visual dashboard for deployment status.

## What Changes

- Install ArgoCD in Kubernetes cluster with Ingress access
- Create ArgoCD Application for infrastructure resources
- Configure auto-sync and self-healing policies
- Implement RBAC with admin and read-only roles
- Integrate with GitHub Actions CI/CD pipeline
- Add comprehensive documentation and usage guides

## Impact

- **Affected specs:** New `gitops-deployment` capability
- **Affected code:** 
  - `k8s/base/argocd/` - New ArgoCD manifests
  - `k8s/overlays/staging/` - Staging environment overlays
  - `.github/workflows/` - CD workflow updates
  - `scripts/` - ArgoCD setup scripts
  - `docs/` - ArgoCD documentation

## Overview

This proposal adds ArgoCD-based GitOps continuous deployment to automate Kubernetes resource synchronization from Git to the cluster. Currently, deployments are manual via `scripts/k8s-deploy.sh`. ArgoCD will enable automatic, declarative, and auditable deployments.

## Motivation

### Current Pain Points
- **Manual deployments:** Require running `./scripts/k8s-deploy.sh` after every change
- **No drift detection:** Manual kubectl changes go unnoticed
- **Difficult rollback:** Requires manual reversion and redeployment
- **Poor visibility:** No dashboard showing deployment status
- **No audit trail:** Hard to track who deployed what and when

### Benefits of ArgoCD
- **Automated deployment:** Git push → automatic sync to Kubernetes
- **Drift detection:** Self-healing reverts manual changes to match Git
- **Easy rollback:** `git revert` + `git push` instantly rolls back
- **Visual dashboard:** Real-time view of all deployments and health
- **Audit trail:** Complete deployment history in Git log
- **GitOps workflow:** Git as single source of truth

## Current State

**Existing Infrastructure:**
- ✅ Kubernetes cluster (kind for local, cloud-ready)
- ✅ GitHub Actions CI/CD pipeline
- ✅ Kustomize-based manifests (`k8s/base/`, `k8s/overlays/`)
- ✅ Manual deployment scripts

**What's Missing:**
- ❌ GitOps automation
- ❌ Continuous deployment from Git
- ❌ Deployment dashboard
- ❌ Automatic rollback capability

## Proposed Solution

### Architecture

```
Developer → Git push → GitHub Actions (CI) → Update manifests → ArgoCD watches → Auto-deploy
                            ↓                                         ↓
                    Build & test                              Self-healing sync
```

### Components to Install

1. **ArgoCD Namespace** - Isolated namespace for ArgoCD components
2. **ArgoCD Server** - Web UI and API server
3. **Application Controller** - Monitors Git and syncs to Kubernetes
4. **Repo Server** - Fetches manifests from Git repository
5. **Redis** - Caching layer for performance

### ArgoCD Applications

1. **infrastructure-app** - Deploys PostgreSQL, Redis, Authentik, Ingress
2. **core-backend-app** - Deploys Core Backend service (Sprint 3+)
3. **ai-service-app** - Deploys AI Service (Sprint 5+)
4. **web-client-app** - Deploys React web client (Sprint 3+)

### Integration with CI/CD

```yaml
# .github/workflows/cd.yml (new workflow)
on:
  push:
    branches: [main]

jobs:
  update-manifests:
    steps:
      - name: Update image tags
        run: |
          cd k8s/overlays/staging
          kustomize edit set image core-backend=ghcr.io/org/core-backend:${{ github.sha }}
      
      - name: Commit and push
        run: |
          git commit -am "chore(deploy): update image tags"
          git push
      
      # ArgoCD watches and auto-deploys!
```

## Scope

### In Scope
- Install ArgoCD in Kubernetes cluster
- Configure Ingress for ArgoCD UI
- Create ArgoCD Application for infrastructure
- Configure auto-sync and self-healing
- RBAC configuration (admin + read-only roles)
- Documentation and usage guide

### Out of Scope
- ArgoCD High Availability (HA) setup (post-MVP)
- ArgoCD ApplicationSets (advanced, not needed yet)
- Image Updater integration (covered by CI/CD)
- SSO integration with Authentik (post-MVP)
- Multi-cluster deployments (single cluster for now)

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| ArgoCD pod crashes during deployment | High | Use ArgoCD's built-in retry logic |
| Accidental production deploy | Critical | Require manual approval for prod syncs |
| Extra resource usage | Low | Monitor and scale cluster if needed |
| Team learning curve | Medium | Provide comprehensive documentation |
| Sync conflicts with manual changes | Medium | Enable self-healing to revert manual changes |

## Success Criteria

- [ ] ArgoCD installed and accessible via Ingress
- [ ] Infrastructure Application syncs automatically from main branch
- [ ] Self-healing reverts manual kubectl changes within 3 minutes
- [ ] Rollback works via Git revert
- [ ] RBAC protects ArgoCD with admin and read-only roles
- [ ] Documentation complete (installation, usage, troubleshooting)
- [ ] All OpenSpec validation passes

## Timeline

**Estimated Effort:** 6-9 hours

- Phase 1: Installation (1-2 hours)
- Phase 2: Application Configuration (2-3 hours)
- Phase 3: CI/CD Integration (1-2 hours)
- Phase 4: RBAC & Security (1 hour)
- Phase 5: Documentation (1 hour)
- Phase 6: Validation (30 minutes)

## Related Changes

- Builds on: `add-kubernetes-staging-cluster` (Sprint 0 Task 1.4)
- Integrates with: `add-cicd-pipeline-github-actions` (Sprint 0 Task 1.2)
- Enables: Future service deployments (Sprint 3+)

## References

- [ArgoCD Official Documentation](https://argo-cd.readthedocs.io/)
- [GitOps Principles](https://www.gitops.tech/)
- [Kubernetes GitOps Best Practices](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/)
