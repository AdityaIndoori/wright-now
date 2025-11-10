# Change: Docker Compose Development Environment

## Why
Sprint 0, Task 1.3 requires a local development environment with infrastructure services (PostgreSQL with pg_vector, Redis, and Authentik IdP) to enable all subsequent development tasks. Without this foundation, developers cannot run services locally, write integration tests, or validate features against real infrastructure.

This change is critical because:
- It unblocks Sprint 0 Tasks 2.1-2.4 (infrastructure setup)
- It unblocks Sprint 0 Tasks 3.1-3.6 (service scaffolding)
- It enables integration testing with Testcontainers (Sprint 0 Task 5.1-5.3)
- It provides a consistent development environment across the team
- It meets the TDD requirement (NFR 5.1) by enabling database-backed tests

## What Changes
- Create `docker-compose.yml` with PostgreSQL, Redis, and Authentik services
- Create `docker-compose.override.yml` for development-specific configurations
- Create `.env.example` template for environment variables
- Add database initialization scripts (`scripts/init-db.sh`)
- Add service health check utilities (`scripts/wait-for-services.sh`)
- Create developer documentation (`docs/local-development.md`)
- Configure networks for service communication
- Configure volumes for data persistence
- Add health checks for all services

## Impact
- **Affected capabilities:** Docker Development Environment (new capability)
- **Affected code:** Root-level infrastructure files, scripts/, docs/
- **Dependencies:** 
  - Requires Sprint 0, Task 1.1 (GitHub repository) ✅
  - Requires Sprint 0, Task 1.2 (CI/CD pipeline) ✅
  - Enables Sprint 0, Tasks 2.1-2.4 (infrastructure services will run in Docker)
  - Enables Sprint 0, Tasks 3.1-3.6 (services need infrastructure to develop against)
  - Enables Sprint 0, Tasks 5.1-5.3 (integration tests need real infrastructure)
- **Breaking:** None (new capability)

## Technical Decisions

### PostgreSQL Configuration
- **Image:** `pgvector/pgvector:pg15` - Pre-built with pg_vector extension
- **Rationale:** Reduces setup complexity, ensures pg_vector is available for RAG functionality
- **Configuration:** Development-optimized settings (max_connections=100, shared_buffers=256MB)

### Redis Configuration
- **Image:** `redis:7-alpine` - Latest stable with minimal image size
- **Rationale:** Alpine base reduces disk usage, Redis 7 provides latest features
- **Persistence:** RDB + AOF enabled for development safety

### Authentik vs Keycloak
- **Choice:** Authentik
- **Rationale:**
  - Modern UI/UX better suited for developer onboarding
  - Native Python implementation aligns with AI service stack
  - Simpler Docker setup (fewer configuration files)
  - Better OIDC support out of the box
  - Recommended in Technical Design Document

### Network Architecture
- **Strategy:** Single bridge network (`wrightnow`)
- **Rationale:**
  - Services communicate via DNS (service names)
  - Simpler than multiple networks for development
  - Easier debugging and troubleshooting
  - Mirrors production Kubernetes service mesh pattern

### Volume Strategy
- **Strategy:** Named volumes for all persistent data
- **Rationale:**
  - Survives `docker-compose down`
  - Better performance than bind mounts on Windows/Mac
  - Easier backup and migration
  - Cleaner project directory

## Security Considerations
- Default credentials are **development-only** and documented as insecure
- `.env` file is already in `.gitignore` (from Task 1.1)
- Production credentials will be managed via Kubernetes secrets (Task 1.4)
- Authentik admin password must be changed on first login
- Services are not exposed to internet (localhost only)

## Validation Criteria
- [ ] `docker-compose up -d` starts all services without errors
- [ ] PostgreSQL is accessible at `localhost:5432` with pg_vector extension enabled
- [ ] Redis is accessible at `localhost:6379`
- [ ] Authentik UI is accessible at `http://localhost:9000`
- [ ] All services pass health checks within 60 seconds
- [ ] Data persists across `docker-compose down` and `docker-compose up`
- [ ] Services can communicate via internal network (e.g., ping postgres from redis)
- [ ] Documentation enables new developer onboarding in <10 minutes
- [ ] `openspec validate add-docker-compose-dev-environment --strict` passes
