# Spec: GitOps Deployment

**Capability:** gitops-deployment  
**Last Updated:** 2025-12-07

## ADDED Requirements

### Requirement: ArgoCD Installation
ArgoCD MUST be installed in the Kubernetes cluster with proper RBAC configuration and secure access controls to enable GitOps continuous deployment.

#### Scenario: Install ArgoCD via Official Manifest
**Given** a Kubernetes cluster is running  
**And** kubectl is configured to access the cluster  
**When** the ArgoCD installation manifest is applied with `kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml`  
**Then** ArgoCD components are deployed in the `argocd` namespace  
**And** the following pods are created and running:
- `argocd-server`
- `argocd-repo-server`
- `argocd-application-controller`
- `argocd-redis`
- `argocd-dex-server` (optional)  
**And** all pods reach Running state within 5 minutes  
**And** the ArgoCD server service is created and listening on port 443

#### Scenario: Access ArgoCD UI via Ingress
**Given** ArgoCD is installed in the cluster  
**And** NGINX Ingress Controller is installed  
**When** an Ingress resource is created with path `/argocd` pointing to `argocd-server` service  
**And** the Ingress is applied to the cluster  
**Then** ArgoCD UI is accessible at `http://localhost/argocd` (local) or `https://<domain>/argocd` (cloud)  
**And** the initial admin password can be retrieved from the `argocd-initial-admin-secret` Secret  
**And** admin can log in with username `admin` and the retrieved password

---

### Requirement: Application Synchronization
ArgoCD MUST automatically synchronize Kubernetes resources from the Git repository to the cluster, ensuring the cluster state matches the desired state defined in Git.

#### Scenario: Create ArgoCD Application for Infrastructure
**Given** ArgoCD is installed and accessible  
**And** the Git repository contains Kubernetes manifests in `k8s/overlays/staging`  
**When** an ArgoCD Application manifest is created with:
- `repoURL`: GitHub repository URL
- `path`: `k8s/overlays/staging`
- `targetRevision`: `main`
- `destination.server`: `https://kubernetes.default.svc`
- `destination.namespace`: appropriate namespace  
**And** the Application manifest is applied with `kubectl apply -f application.yaml`  
**Then** ArgoCD creates the Application  
**And** the Application appears in the ArgoCD UI  
**And** the Application status shows "OutOfSync" initially

#### Scenario: Manual Sync Application to Deploy Resources
**Given** an ArgoCD Application exists and is OutOfSync  
**And** the Git repository contains valid Kubernetes manifests  
**When** the admin clicks "Sync" in the ArgoCD UI  
**Or** runs `argocd app sync <app-name>` via CLI  
**Then** ArgoCD applies all manifests from Git to Kubernetes  
**And** the Application status changes to "Syncing"  
**And** the Application status changes to "Synced" when complete  
**And** all resources are created in Kubernetes  
**And** the Application health status shows "Healthy" when all pods are running

#### Scenario: Auto-Sync Detects and Applies Git Changes
**Given** an ArgoCD Application exists with auto-sync enabled  
**And** the Application is currently "Synced"  
**When** a change is pushed to the `main` branch in Git  
**And** ArgoCD polls the repository (default: every 3 minutes)  
**Then** ArgoCD detects the change  
**And** the Application status changes to "OutOfSync"  
**And** ArgoCD automatically triggers a sync operation  
**And** the updated manifests are applied to Kubernetes  
**And** the Application status changes back to "Synced"  
**And** all resources reflect the new Git state

#### Scenario: Sync Failure with Invalid Manifest
**Given** an ArgoCD Application exists  
**When** a change is pushed to Git with an invalid Kubernetes manifest  
**And** ArgoCD attempts to sync the Application  
**Then** the sync operation fails  
**And** the Application status shows "OutOfSync"  
**And** the Application health status shows "Degraded"  
**And** error details are visible in the ArgoCD UI  
**And** the previous working state remains deployed in Kubernetes

---

### Requirement: Self-Healing from Manual Changes
ArgoCD MUST detect and revert manual changes made directly to Kubernetes resources, ensuring Git remains the single source of truth.

#### Scenario: Self-Healing Reverts Manual kubectl Changes
**Given** an ArgoCD Application is deployed and synced  
**And** self-healing is enabled in the Application's sync policy  
**And** a resource (e.g., Deployment) is managed by ArgoCD  
**When** a user manually modifies the resource with `kubectl edit deployment/<name>`  
**And** changes a field (e.g., replica count from 3 to 5)  
**And** ArgoCD detects the drift within 3 minutes  
**Then** ArgoCD marks the Application as "OutOfSync"  
**And** ArgoCD automatically reverts the manual change  
**And** the resource is restored to match the Git state  
**And** the Application status returns to "Synced"  
**And** the replica count is reset to 3 (as defined in Git)

#### Scenario: Self-Healing Can Be Disabled Per Application
**Given** an ArgoCD Application exists  
**When** the Application's sync policy does not include `selfHeal: true`  
**And** a user manually modifies a resource in Kubernetes  
**Then** ArgoCD detects the drift and marks Application as "OutOfSync"  
**But** ArgoCD does not automatically revert the change  
**And** the manual change persists until the next manual or auto-sync

---

### Requirement: Rollback Capability
ArgoCD MUST support easy rollback to previous deployments by reverting commits in Git, enabling quick recovery from bad deployments.

#### Scenario: Rollback via Git Revert
**Given** an ArgoCD Application is deployed and synced  
**And** a recent deployment introduced a bug  
**And** the deployment was triggered by commit SHA `abc123`  
**When** the commit is reverted in Git with `git revert abc123`  
**And** the revert commit is pushed to the `main` branch  
**And** ArgoCD polls the repository and detects the revert  
**Then** ArgoCD marks the Application as "OutOfSync"  
**And** ArgoCD syncs the Application (automatically if auto-sync enabled)  
**And** the previous working state is restored to Kubernetes  
**And** the Application status shows "Synced"  
**And** the Application health status shows "Healthy"  
**And** the rollback is complete within 5 minutes of pushing the revert

#### Scenario: View Application History in ArgoCD UI
**Given** an ArgoCD Application has been synced multiple times  
**When** the admin opens the Application in ArgoCD UI  
**And** navigates to the "History" tab  
**Then** all previous sync operations are listed with:
- Sync ID
- Git commit SHA
- Timestamp
- Sync result (success/failure)  
**And** the admin can click any previous sync to view details  
**And** the admin can rollback to a previous sync directly from the UI

---

### Requirement: Deployment Visibility
ArgoCD MUST provide a visual dashboard showing deployment status, health, and resource details to improve observability.

#### Scenario: View Application List in ArgoCD UI
**Given** ArgoCD is installed and accessible  
**And** multiple Applications have been created  
**When** a user logs into the ArgoCD UI  
**Then** all Applications are listed on the Applications page  
**And** each Application shows:
- Name
- Sync status (Synced, OutOfSync, Unknown)
- Health status (Healthy, Progressing, Degraded, Missing)
- Last sync time
- Git repository and revision  
**And** the user can filter Applications by status

#### Scenario: View Application Resource Tree
**Given** an ArgoCD Application is deployed  
**When** the user clicks on the Application in the UI  
**Then** the Application details page opens  
**And** a visual resource tree is displayed showing:
- Application (root)
- Namespaces
- Kubernetes resources (Deployments, Services, Pods, etc.)
- Resource relationships and dependencies  
**And** each resource shows its health status with color coding:
- Green: Healthy
- Yellow: Progressing
- Red: Degraded  
**And** the user can click any resource to view its live manifest

#### Scenario: View Sync Operation Logs
**Given** an ArgoCD Application has performed a sync operation  
**When** the user opens the Application in the UI  
**And** navigates to the sync operation details  
**Then** detailed logs of the sync operation are displayed  
**And** the logs show each resource that was created, updated, or deleted  
**And** any errors or warnings are highlighted  
**And** the user can download the logs for offline analysis

---

### Requirement: RBAC Protection
ArgoCD access MUST be protected with proper authentication and role-based authorization to ensure only authorized users can view and manage deployments.

#### Scenario: Admin User Has Full Permissions
**Given** ArgoCD is configured with RBAC  
**And** a user account exists with role `admin`  
**When** the admin user logs into ArgoCD  
**Then** the admin can view all Applications  
**And** the admin can manually sync Applications  
**And** the admin can modify Application configurations  
**And** the admin can create new Applications  
**And** the admin can delete Applications  
**And** the admin can manage RBAC policies  
**And** the admin can view and edit repository credentials

#### Scenario: Read-Only User Has Limited Permissions
**Given** ArgoCD is configured with RBAC  
**And** a user account exists with role `readonly`  
**When** the read-only user logs into ArgoCD  
**Then** the user can view all Applications  
**And** the user can view Application details and resource trees  
**And** the user can view sync history  
**But** the user cannot manually sync Applications  
**And** the user cannot modify Application configurations  
**And** the user cannot create or delete Applications  
**And** sync buttons are disabled in the UI for read-only users

#### Scenario: Unauthenticated Access Is Denied
**Given** ArgoCD is configured with authentication enabled  
**When** an unauthenticated user attempts to access the ArgoCD UI  
**Then** the user is redirected to the login page  
**And** the user cannot view any Applications without logging in  
**And** API requests without valid authentication tokens are rejected with 401 Unauthorized

---

### Requirement: Prune Orphaned Resources
ArgoCD MUST support pruning (deleting) Kubernetes resources that are removed from Git but still exist in the cluster, ensuring clean synchronization.

#### Scenario: Prune Resources Removed from Git
**Given** an ArgoCD Application is deployed with prune enabled  
**And** a Deployment named `old-service` exists in Kubernetes  
**And** the Deployment is defined in Git  
**When** the Deployment manifest is deleted from Git  
**And** the deletion is committed and pushed  
**And** ArgoCD syncs the Application  
**Then** ArgoCD detects the Deployment no longer exists in Git  
**And** ArgoCD deletes the Deployment from Kubernetes  
**And** the Application status shows "Synced"  
**And** the Deployment and its Pods are removed from the cluster

#### Scenario: Prune Can Be Disabled for Safety
**Given** an ArgoCD Application exists  
**When** the Application's sync policy does not include `prune: true`  
**And** a resource is removed from Git  
**And** ArgoCD syncs the Application  
**Then** ArgoCD does not delete the resource from Kubernetes  
**And** the resource remains in the cluster as an "orphan"  
**And** the Application status shows "Synced" (ignoring orphans)  
**And** the admin must manually delete orphaned resources if desired

---

### Requirement: Sync Retry on Failure
ArgoCD MUST automatically retry failed sync operations to handle transient errors and improve deployment reliability.

#### Scenario: Retry Sync After Transient Failure
**Given** an ArgoCD Application is syncing  
**And** a transient error occurs (e.g., network timeout, API server temporarily unavailable)  
**When** the sync operation fails  
**Then** ArgoCD marks the sync as failed  
**And** ArgoCD automatically retries the sync operation  
**And** the retry uses exponential backoff (e.g., 5s, 10s, 20s, 40s)  
**And** if the retry succeeds, the Application status shows "Synced"  
**And** if all retries fail, the Application status shows "Degraded"  
**And** error details are logged and visible in the UI

---

### Requirement: Multiple Sync Strategies
ArgoCD MUST support multiple sync strategies (kubectl apply, server-side apply, replace) to handle different use cases and resource types.

#### Scenario: Use kubectl Apply by Default
**Given** an ArgoCD Application is configured without explicit sync options  
**When** ArgoCD syncs the Application  
**Then** ArgoCD uses `kubectl apply` to apply manifests  
**And** resources are updated using three-way merge  
**And** existing annotations and labels are preserved unless overwritten

#### Scenario: Use Server-Side Apply for Large Resources
**Given** an ArgoCD Application has sync option `ServerSideApply=true`  
**When** ArgoCD syncs the Application  
**Then** ArgoCD uses server-side apply instead of client-side apply  
**And** large resources are applied more efficiently  
**And** field management is handled by the Kubernetes API server

---

## MODIFIED Requirements

None. This is a new capability with no modifications to existing requirements.

---

## REMOVED Requirements

None. This is a new capability with no removals.
