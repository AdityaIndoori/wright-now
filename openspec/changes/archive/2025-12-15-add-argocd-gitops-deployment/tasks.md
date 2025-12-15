# Tasks: Add ArgoCD GitOps Deployment Automation

**Change ID:** `add-argocd-gitops-deployment`  
**Estimated Total Time:** 6-9 hours

## Phase 1: Installation (1-2 hours)

- [ ] Download ArgoCD installation manifest (stable version)
- [ ] Create `k8s/base/argocd/` directory structure
- [ ] Apply ArgoCD installation manifest to cluster
- [ ] Verify all ArgoCD pods are running in `argocd` namespace
- [ ] Create Ingress manifest for ArgoCD UI at `/argocd`
- [ ] Apply Ingress manifest
- [ ] Access ArgoCD UI and retrieve initial admin password
- [ ] Change default admin password to secure password
- [ ] Test ArgoCD CLI login

## Phase 2: Application Configuration (2-3 hours)

- [ ] Create `k8s/base/argocd/applications/` directory
- [ ] Write `infrastructure-app.yaml` ArgoCD Application manifest
  - Set source repo URL to GitHub repository
  - Set path to `k8s/overlays/staging`
  - Set destination cluster to `https://kubernetes.default.svc`
  - Set destination namespace to appropriate namespaces
- [ ] Configure sync policy (automated vs manual)
- [ ] Enable auto-sync for infrastructure Application
- [ ] Enable self-healing to revert manual changes
- [ ] Set sync options (prune orphaned resources)
- [ ] Apply infrastructure Application manifest
- [ ] Verify Application shows "Synced" status in ArgoCD UI
- [ ] Test manual sync from ArgoCD UI
- [ ] Verify all infrastructure resources deployed correctly

## Phase 3: CI/CD Integration (1-2 hours)

- [ ] Create `.github/workflows/cd.yml` workflow file
- [ ] Add trigger for `push` to `main` branch
- [ ] Add job to update Kustomize image tags
- [ ] Add step to commit and push manifest changes
- [ ] Configure Git credentials for GitHub Actions
- [ ] Test workflow by pushing a dummy change
- [ ] Verify ArgoCD detects and syncs the change
- [ ] Confirm end-to-end flow: code push → CI build → manifest update → ArgoCD deploy

## Phase 4: RBAC & Security (1 hour)

- [ ] Create ArgoCD RBAC ConfigMap
- [ ] Define admin role with full permissions
- [ ] Define read-only role with view-only permissions
- [ ] Apply RBAC ConfigMap to ArgoCD
- [ ] Create test admin user account
- [ ] Create test read-only user account
- [ ] Test admin user can sync Applications
- [ ] Test read-only user cannot sync Applications
- [ ] Document RBAC policy in comments

## Phase 5: Documentation (1 hour)

- [ ] Create `docs/argocd-guide.md` usage guide
- [ ] Document ArgoCD installation procedure
- [ ] Document how to access ArgoCD UI
- [ ] Document how to create new Applications
- [ ] Document rollback procedure (Git revert)
- [ ] Add troubleshooting section to `docs/kubernetes-setup.md`
- [ ] Add ArgoCD troubleshooting common issues
- [ ] Document ArgoCD CLI usage examples
- [ ] Update main `README.md` with ArgoCD information

## Phase 6: Validation (30 minutes)

- [ ] Run `openspec validate add-argocd-gitops-deployment --strict`
- [ ] Fix any validation errors reported
- [ ] Verify all spec requirements have scenarios
- [ ] Confirm all tasks in this file are completed
- [ ] Test complete GitOps workflow end-to-end:
  - Make code change
  - Push to main branch
  - Verify CI builds and updates manifests
  - Verify ArgoCD syncs automatically
  - Verify application deploys successfully
- [ ] Test rollback procedure:
  - Revert last commit
  - Push to main branch
  - Verify ArgoCD rolls back automatically
- [ ] Test self-healing:
  - Make manual kubectl change to a resource
  - Wait 3 minutes
  - Verify ArgoCD reverts the manual change

## Post-Implementation Validation

- [ ] ArgoCD UI accessible at configured URL
- [ ] Infrastructure Application status shows "Synced"
- [ ] All infrastructure pods are healthy
- [ ] Auto-sync is enabled and working
- [ ] Self-healing reverts manual changes
- [ ] RBAC enforces access controls
- [ ] Documentation is complete and accurate
- [ ] Team members can access and use ArgoCD

## Notes

- Each task should be completed sequentially within its phase
- Phases can be worked on sequentially or with some parallelization
- Mark tasks with `[x]` as they are completed
- Add notes below tasks if issues arise
- Estimated times are guidelines; actual time may vary
