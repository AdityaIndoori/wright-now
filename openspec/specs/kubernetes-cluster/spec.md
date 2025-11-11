# kubernetes-cluster Specification

## Purpose
TBD - created by archiving change 2025-11-11-add-kubernetes-staging-cluster. Update Purpose after archive.
## Requirements
### Requirement: Cluster Creation and Management

The system SHALL provide automated scripts for creating, managing, and destroying local kind clusters with minimal manual configuration.

#### Scenario: First-time cluster creation
- **GIVEN** a developer has Docker and kind installed
- **AND** they have cloned the repository
- **WHEN** they execute `./scripts/k8s-setup.sh`
- **THEN** a kind cluster named "wrightnow" SHALL be created successfully
- **AND** nginx-ingress controller SHALL be installed and ready
- **AND** the cluster SHALL be accessible via kubectl
- **AND** the entire setup SHALL complete in under 2 minutes

#### Scenario: Cluster already exists
- **GIVEN** a kind cluster named "wrightnow" already exists
- **WHEN** the developer executes `./scripts/k8s-setup.sh`
- **THEN** the script SHALL detect the existing cluster
- **AND** either reuse the existing cluster OR prompt for confirmation to recreate
- **AND** no data loss SHALL occur if reusing existing cluster

#### Scenario: Cluster teardown
- **GIVEN** a kind cluster named "wrightnow" is running
- **WHEN** the developer executes `./scripts/k8s-teardown.sh`
- **THEN** the cluster SHALL be deleted completely
- **AND** all Docker containers associated with the cluster SHALL be removed
- **AND** verification SHALL confirm cluster no longer exists

#### Scenario: Cluster with custom configuration
- **GIVEN** the kind cluster configuration at `k8s/overlays/local/kind-cluster-config.yaml`
- **WHEN** the cluster is created
- **THEN** port 80 and 443 SHALL be mapped from host to cluster
- **AND** the specified Kubernetes version SHALL be used
- **AND** any custom node labels SHALL be applied

### Requirement: Multi-Namespace Architecture

The system SHALL organize services into multiple namespaces for isolation, security, and clarity.

#### Scenario: Namespace creation on deployment
- **GIVEN** the Kustomize configuration includes namespace definitions
- **WHEN** the developer executes `kubectl apply -k k8s/overlays/local`
- **THEN** four namespaces SHALL be created: staging-infra, staging-core, staging-ai, staging-web
- **AND** each namespace SHALL have appropriate labels (environment, service)
- **AND** placeholder namespaces SHALL have `status: placeholder` label

#### Scenario: Placeholder namespace annotations
- **GIVEN** a placeholder namespace (staging-core, staging-ai, or staging-web)
- **WHEN** a developer inspects the namespace metadata
- **THEN** annotations SHALL reference the corresponding Sprint task
- **AND** annotations SHALL reference the deployment guide in k8s/README.md
- **AND** labels SHALL indicate the namespace is a placeholder

#### Scenario: Service deployment to namespace
- **GIVEN** a service is deployed to a specific namespace
- **WHEN** the service queries for other services
- **THEN** DNS resolution SHALL work within the same namespace using short names
- **AND** cross-namespace resolution SHALL require fully qualified names
- **AND** network policies (if configured) SHALL enforce namespace isolation

### Requirement: PostgreSQL Database Deployment

The system SHALL deploy PostgreSQL database with pg_vector extension using StatefulSet for stable identity and data persistence.

#### Scenario: PostgreSQL deployment
- **GIVEN** the PostgreSQL manifests exist in `k8s/base/postgres/`
- **WHEN** the manifests are applied to the cluster
- **THEN** a StatefulSet named "postgres" SHALL be created in staging-infra namespace
- **AND** one pod named "postgres-0" SHALL be running
- **AND** the pod SHALL use image `pgvector/pgvector:pg15`
- **AND** resource requests SHALL be 250m CPU and 256Mi memory
- **AND** resource limits SHALL be 500m CPU and 512Mi memory

#### Scenario: PostgreSQL data persistence
- **GIVEN** PostgreSQL is running with a PersistentVolumeClaim
- **AND** data has been written to the database
- **WHEN** the postgres-0 pod is deleted
- **THEN** Kubernetes SHALL automatically recreate the pod
- **AND** the new pod SHALL mount the same PersistentVolume
- **AND** all database data SHALL be intact and accessible

#### Scenario: PostgreSQL health checks
- **GIVEN** PostgreSQL pod is starting
- **WHEN** the liveness probe executes `pg_isready -U postgres`
- **THEN** the probe SHALL return success when PostgreSQL accepts connections
- **AND** if the probe fails repeatedly, Kubernetes SHALL restart the pod
- **AND** the readiness probe SHALL prevent traffic routing until PostgreSQL is ready

#### Scenario: PostgreSQL service discovery
- **GIVEN** PostgreSQL Service exists in staging-infra namespace
- **WHEN** another service queries DNS for "postgres"
- **THEN** the DNS SHALL resolve to the postgres-0 pod IP
- **AND** the service SHALL be accessible on port 5432
- **AND** the service type SHALL be ClusterIP (internal only)

### Requirement: Redis Cache Deployment

The system SHALL deploy Redis cache using Deployment with PersistentVolumeClaim for AOF persistence.

#### Scenario: Redis deployment
- **GIVEN** the Redis manifests exist in `k8s/base/redis/`
- **WHEN** the manifests are applied to the cluster
- **THEN** a Deployment named "redis" SHALL be created in staging-infra namespace
- **AND** one pod SHALL be running
- **AND** the pod SHALL use image `redis:7-alpine`
- **AND** Redis SHALL be configured with `--appendonly yes --appendfsync everysec`
- **AND** resource requests SHALL be 100m CPU and 128Mi memory
- **AND** resource limits SHALL be 250m CPU and 256Mi memory

#### Scenario: Redis data persistence
- **GIVEN** Redis is running with AOF enabled
- **AND** keys have been set in Redis
- **WHEN** the redis pod is deleted
- **THEN** Kubernetes SHALL recreate the pod
- **AND** Redis SHALL replay the AOF log on startup
- **AND** previously set keys SHALL be restored

#### Scenario: Redis health checks
- **GIVEN** Redis pod is running
- **WHEN** the liveness probe executes `redis-cli ping`
- **THEN** the probe SHALL return "PONG"
- **AND** if the probe fails, Kubernetes SHALL restart the pod
- **AND** the readiness probe SHALL prevent traffic routing until Redis responds

### Requirement: Authentik Identity Provider Deployment

The system SHALL deploy Authentik OIDC identity provider with separate PostgreSQL and Redis instances, plus server and worker components.

#### Scenario: Authentik PostgreSQL deployment
- **GIVEN** the Authentik PostgreSQL manifests exist
- **WHEN** the manifests are applied
- **THEN** a StatefulSet named "authentik-postgres" SHALL be created
- **AND** the pod SHALL use image `postgres:15-alpine`
- **AND** a PersistentVolumeClaim of 5Gi SHALL be provisioned
- **AND** health checks SHALL verify PostgreSQL readiness

#### Scenario: Authentik Redis deployment
- **GIVEN** the Authentik Redis manifests exist
- **WHEN** the manifests are applied
- **THEN** a Deployment named "authentik-redis" SHALL be created
- **AND** the pod SHALL use image `redis:7-alpine`
- **AND** Redis SHALL be configured with RDB persistence (`--save 60 1`)
- **AND** a PersistentVolumeClaim of 1Gi SHALL be provisioned

#### Scenario: Authentik server deployment
- **GIVEN** the Authentik server manifests exist
- **WHEN** the manifests are applied
- **THEN** a Deployment named "authentik-server" SHALL be created
- **AND** two replicas SHALL be running (high availability)
- **AND** the pods SHALL use image `ghcr.io/goauthentik/server:latest`
- **AND** startup probe SHALL allow 60s for slow initialization
- **AND** environment variables SHALL be sourced from Secret
- **AND** authentik-media PVC SHALL be mounted at /media

#### Scenario: Authentik worker deployment
- **GIVEN** the Authentik worker manifests exist
- **WHEN** the manifests are applied
- **THEN** a Deployment named "authentik-worker" SHALL be created
- **AND** one replica SHALL be running
- **AND** the pod SHALL execute background tasks
- **AND** the same authentik-media PVC SHALL be mounted (shared with server)

#### Scenario: Authentik service dependencies
- **GIVEN** Authentik server depends on authentik-postgres and authentik-redis
- **WHEN** the deployments are created
- **THEN** Kubernetes SHALL NOT mark server as ready until dependencies are healthy
- **AND** server SHALL be able to connect to postgres via service name "authentik-postgres"
- **AND** server SHALL be able to connect to redis via service name "authentik-redis"

### Requirement: Ingress Configuration

The system SHALL configure nginx-ingress controller to route HTTP traffic from localhost to services inside the cluster.

#### Scenario: nginx-ingress installation
- **GIVEN** a kind cluster is created
- **WHEN** the setup script installs nginx-ingress
- **THEN** the ingress controller SHALL be deployed in ingress-nginx namespace
- **AND** the controller SHALL be ready within 90 seconds
- **AND** a LoadBalancer service SHALL expose ports 80 and 443

#### Scenario: Authentik ingress routing
- **GIVEN** nginx-ingress is installed
- **AND** Authentik server is running
- **WHEN** an Ingress resource routes /auth/ to authentik-server
- **THEN** requests to http://localhost/auth/ SHALL be forwarded to authentik-server:9000
- **AND** URL rewriting SHALL remove /auth/ prefix before forwarding
- **AND** responses SHALL be returned to the client

#### Scenario: Ingress health verification
- **GIVEN** all services are deployed
- **WHEN** the developer executes `curl http://localhost/auth/api/v3/`
- **THEN** the request SHALL receive a valid JSON response from Authentik
- **AND** the response time SHALL be under 100ms
- **AND** no ingress errors SHALL be logged

### Requirement: Data Persistence Strategy

The system SHALL ensure all stateful services persist data across pod restarts and (optionally) cluster recreation.

#### Scenario: PersistentVolumeClaim provisioning
- **GIVEN** a service requires persistent storage
- **WHEN** a PersistentVolumeClaim is created
- **THEN** kind's local-path-provisioner SHALL automatically provision a PersistentVolume
- **AND** the PV SHALL be bound to the PVC
- **AND** the PV SHALL use local storage (Docker volumes)

#### Scenario: Data survives pod deletion
- **GIVEN** a pod is using a PersistentVolumeClaim
- **AND** data has been written to the volume
- **WHEN** the pod is deleted
- **THEN** the PVC SHALL remain intact
- **AND** when a new pod mounts the same PVC, data SHALL be accessible
- **AND** no data loss SHALL occur

#### Scenario: PVC retention policy
- **GIVEN** a PersistentVolume with reclaimPolicy: Retain
- **WHEN** the corresponding PVC is deleted
- **THEN** the PV SHALL NOT be deleted automatically
- **AND** data SHALL remain in Docker volumes
- **AND** manual deletion SHALL be required to fully clean up

#### Scenario: Storage sizes
- **GIVEN** the storage requirements for each service
- **THEN** postgres PVC SHALL request 10Gi
- **AND** redis PVC SHALL request 2Gi
- **AND** authentik-postgres PVC SHALL request 5Gi
- **AND** authentik-redis PVC SHALL request 1Gi
- **AND** authentik-media PVC SHALL request 2Gi

### Requirement: Configuration Management

The system SHALL use ConfigMaps for non-sensitive configuration and Secrets for sensitive data.

#### Scenario: ConfigMap for PostgreSQL init script
- **GIVEN** PostgreSQL requires initialization with pg_vector extension
- **WHEN** a ConfigMap contains the init-db.sh script
- **THEN** the script SHALL be mounted as a volume in the postgres pod
- **AND** PostgreSQL SHALL execute the script on first startup
- **AND** pg_vector extension SHALL be enabled

#### Scenario: Secret creation from examples
- **GIVEN** secret example files exist (e.g., `secrets.example.yaml`)
- **WHEN** a developer creates real secrets
- **THEN** they SHALL base64 encode all values
- **AND** they SHALL save as `secrets.yaml` (gitignored)
- **AND** they SHALL apply with `kubectl apply -f secrets.yaml`

#### Scenario: Secret consumption by pods
- **GIVEN** a Secret contains database credentials
- **WHEN** a pod references the Secret in environment variables
- **THEN** the pod SHALL receive decoded values at runtime
- **AND** the values SHALL NOT be visible in pod spec
- **AND** secret changes SHALL require pod restart to take effect

### Requirement: Resource Management

The system SHALL define resource requests and limits for all services to ensure fair scheduling and prevent resource starvation.

#### Scenario: Resource requests for scheduling
- **GIVEN** a deployment specifies resource requests
- **WHEN** Kubernetes schedules a pod
- **THEN** the scheduler SHALL ensure the node has sufficient available resources
- **AND** the pod SHALL be guaranteed the requested CPU and memory
- **AND** if resources are unavailable, the pod SHALL remain Pending

#### Scenario: Resource limits for protection
- **GIVEN** a deployment specifies resource limits
- **WHEN** a pod attempts to exceed memory limit
- **THEN** Kubernetes SHALL kill the pod (OOMKilled)
- **AND** when a pod attempts to exceed CPU limit
- **THEN** Kubernetes SHALL throttle the CPU usage

#### Scenario: Resource allocation for local development
- **GIVEN** the total resource requests across all services
- **THEN** the cluster SHALL be runnable on machines with 8GB RAM and 4 CPU cores
- **AND** all services SHALL fit within these constraints
- **AND** resource limits SHALL allow burst capacity when needed

### Requirement: Health Checks and Readiness Probes

The system SHALL configure liveness and readiness probes for all services to ensure reliability and proper traffic routing.

#### Scenario: Liveness probe restarts unhealthy pod
- **GIVEN** a pod has a liveness probe configured
- **WHEN** the probe fails more than failureThreshold times
- **THEN** Kubernetes SHALL kill the pod
- **AND** Kubernetes SHALL restart the pod
- **AND** the restart count SHALL increment

#### Scenario: Readiness probe controls traffic routing
- **GIVEN** a pod has a readiness probe configured
- **WHEN** the probe is failing
- **THEN** the pod's IP SHALL be removed from Service endpoints
- **AND** no traffic SHALL be routed to the pod
- **AND** when the probe succeeds, traffic SHALL resume

#### Scenario: Startup probe for slow-starting services
- **GIVEN** Authentik server has a slow startup time
- **WHEN** a startup probe is configured with long initialDelaySeconds
- **THEN** Kubernetes SHALL not execute liveness checks until startup succeeds
- **AND** this SHALL prevent premature pod restarts during initialization
- **AND** once startup succeeds, normal liveness checks SHALL begin

### Requirement: Kustomize Configuration

The system SHALL use Kustomize for managing base manifests and environment-specific overlays.

#### Scenario: Base manifests
- **GIVEN** base manifests exist in `k8s/base/`
- **WHEN** a developer applies the base with `kubectl apply -k k8s/base`
- **THEN** all resources SHALL be created in the cluster
- **AND** commonLabels SHALL be applied to all resources
- **AND** the base SHALL be reusable across environments

#### Scenario: Local overlay
- **GIVEN** a local overlay exists in `k8s/overlays/local/`
- **WHEN** the overlay references the base
- **THEN** Kustomize SHALL merge base manifests with overlay patches
- **AND** local-specific configurations SHALL override base values
- **AND** the result SHALL be a complete, environment-specific manifest

#### Scenario: Future cloud overlays
- **GIVEN** the base and local overlay structure
- **WHEN** a developer creates `k8s/overlays/staging/` for GKE
- **THEN** they SHALL reference the same base
- **AND** they SHALL patch storageClassName to "gce-pd"
- **AND** they SHALL increase resource limits for production workloads
- **AND** the base manifests SHALL remain unchanged

### Requirement: Documentation and Onboarding

The system SHALL provide comprehensive documentation enabling new developers to set up and use the cluster with minimal friction.

#### Scenario: Quick start guide
- **GIVEN** a new developer has cloned the repository
- **WHEN** they read `k8s/README.md`
- **THEN** they SHALL find clear setup instructions
- **AND** they SHALL understand the three-command workflow: setup, deploy, teardown
- **AND** they SHALL be able to complete setup in under 10 minutes

#### Scenario: Placeholder namespace documentation
- **GIVEN** placeholder namespaces exist for future services
- **WHEN** a developer reads `k8s/README.md`
- **THEN** they SHALL find dedicated sections for deploying to each namespace
- **AND** each section SHALL reference the corresponding Sprint task
- **AND** each section SHALL provide deployment pattern examples
- **AND** each section SHALL explain Ingress routing configuration

#### Scenario: Troubleshooting guide
- **GIVEN** a developer encounters an issue
- **WHEN** they consult the troubleshooting section in `k8s/README.md`
- **THEN** they SHALL find solutions for common problems
- **AND** solutions SHALL include: pods not starting, ingress not working, PVC issues
- **AND** each solution SHALL include diagnostic commands

#### Scenario: Cloud migration guide
- **GIVEN** a developer needs to deploy to GKE, EKS, or AKS
- **WHEN** they read `docs/kubernetes-setup.md`
- **THEN** they SHALL find step-by-step migration instructions
- **AND** they SHALL understand which components need cloud-specific configuration
- **AND** they SHALL be able to create a cloud cluster and deploy successfully

### Requirement: Cluster Validation and Testing

The system SHALL provide scripts and procedures for validating cluster functionality after deployment.

#### Scenario: YAML syntax validation
- **GIVEN** all Kubernetes manifests have been created
- **WHEN** the developer runs `kubectl apply --dry-run=client -k k8s/base`
- **THEN** kubectl SHALL parse all YAML files successfully
- **AND** no syntax errors SHALL be reported
- **AND** all resources SHALL be validated against Kubernetes schema

#### Scenario: Deployment validation
- **GIVEN** the deployment script has completed
- **WHEN** the developer runs `kubectl get pods -n staging-infra`
- **THEN** all pods SHALL show status "Running"
- **AND** all pods SHALL show "1/1" or "2/2" in READY column
- **AND** no pods SHALL show CrashLoopBackOff or Error status

#### Scenario: Service connectivity testing
- **GIVEN** all services are deployed
- **WHEN** the developer executes database connection tests
- **THEN** PostgreSQL SHALL accept connections and list databases
- **AND** Redis SHALL respond to PING commands
- **AND** Authentik API SHALL return valid JSON responses
- **AND** all tests SHALL complete successfully

#### Scenario: OpenSpec validation
- **GIVEN** the OpenSpec proposal is complete
- **WHEN** the developer runs `openspec validate 2025-11-11-add-kubernetes-staging-cluster --strict`
- **THEN** all requirements SHALL have corresponding scenarios
- **AND** no validation errors SHALL be reported
- **AND** the proposal SHALL be ready for review and approval

### Requirement: Service Discovery and Networking

The system SHALL provide DNS-based service discovery and ClusterIP services for internal communication.

#### Scenario: DNS resolution within namespace
- **GIVEN** two services exist in the same namespace (e.g., authentik-server and authentik-postgres)
- **WHEN** authentik-server queries DNS for "authentik-postgres"
- **THEN** DNS SHALL resolve to the ClusterIP of authentik-postgres Service
- **AND** the connection SHALL succeed on port 5432

#### Scenario: DNS resolution across namespaces
- **GIVEN** services exist in different namespaces
- **WHEN** a service queries DNS with fully qualified name "postgres.staging-infra.svc.cluster.local"
- **THEN** DNS SHALL resolve to the postgres Service ClusterIP
- **AND** cross-namespace communication SHALL work if allowed by NetworkPolicies

#### Scenario: Service type selection
- **GIVEN** different service types (ClusterIP, LoadBalancer)
- **THEN** databases and caches SHALL use ClusterIP (internal only)
- **AND** application services SHALL use ClusterIP (accessed via Ingress)
- **AND** only nginx-ingress SHALL use LoadBalancer (external access point)

### Requirement: Cloud Migration Path

The system SHALL provide a clear, documented path for migrating from local kind cluster to cloud providers (GKE, EKS, AKS).

#### Scenario: GKE migration
- **GIVEN** the local kind cluster is working
- **WHEN** a developer creates a GKE cluster
- **AND** applies `k8s/overlays/staging/` (GKE-specific overlay)
- **THEN** all services SHALL deploy to GKE successfully
- **AND** storageClassName SHALL be "gce-pd"
- **AND** LoadBalancer SHALL use Google Cloud Load Balancer
- **AND** no application code changes SHALL be required

#### Scenario: EKS migration
- **GIVEN** the local kind cluster is working
- **WHEN** a developer creates an EKS cluster
- **AND** applies `k8s/overlays/staging/` (EKS-specific overlay)
- **THEN** all services SHALL deploy to EKS successfully
- **AND** storageClassName SHALL be "ebs-csi"
- **AND** LoadBalancer SHALL use AWS Elastic Load Balancer
- **AND** IAM roles MAY be configured via annotations

#### Scenario: AKS migration
- **GIVEN** the local kind cluster is working
- **WHEN** a developer creates an AKS cluster
- **AND** applies `k8s/overlays/staging/` (AKS-specific overlay)
- **THEN** all services SHALL deploy to AKS successfully
- **AND** storageClassName SHALL be "azure-disk"
- **AND** LoadBalancer SHALL use Azure Load Balancer

### Requirement: Future Service Deployment

The system SHALL provide clear guidance and namespace infrastructure for deploying future services created in Sprint 0 Tasks 3.1-3.3.

#### Scenario: Core Backend deployment preparation
- **GIVEN** staging-core namespace exists as placeholder
- **WHEN** Sprint 0 Task 3.1 implements Nest.js Core Backend
- **THEN** the namespace SHALL already exist with proper labels
- **AND** k8s/README.md SHALL provide detailed deployment instructions
- **AND** the developer SHALL copy the deployment pattern from authentik-server
- **AND** Ingress SHALL be updated to route /api/ to the new service

#### Scenario: AI Service deployment preparation
- **GIVEN** staging-ai namespace exists as placeholder
- **WHEN** Sprint 0 Task 3.2 implements FastAPI AI Service
- **THEN** the namespace SHALL already exist with proper labels
- **AND** k8s/README.md SHALL provide detailed deployment instructions
- **AND** Ingress SHALL be updated to route /ai/ to the new service

#### Scenario: Web Client deployment preparation
- **GIVEN** staging-web namespace exists as placeholder
- **WHEN** Sprint 0 Task 3.3 implements React Web Client
- **THEN** the namespace SHALL already exist with proper labels
- **AND** k8s/README.md SHALL provide detailed deployment instructions
- **AND** Ingress SHALL be updated to route / to the new service

