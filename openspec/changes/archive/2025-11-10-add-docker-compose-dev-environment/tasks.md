# Tasks: Docker Compose Development Environment

This document outlines the implementation tasks for adding a Docker Compose development environment with PostgreSQL, Redis, and Authentik.

## Implementation Checklist

### Phase 1: Core Docker Compose Configuration ✅
- [x] Create `docker-compose.yml` with basic structure (version, services, networks, volumes)
- [x] Add PostgreSQL service with pgvector/pgvector:pg15 image
- [x] Configure PostgreSQL environment variables (database name, user, password)
- [x] Add PostgreSQL volume for data persistence
- [x] Add PostgreSQL health check (pg_isready command)
- [x] Add Redis service with redis:7-alpine image
- [x] Configure Redis command with configuration options
- [x] Add Redis volume for data persistence
- [x] Add Redis health check (redis-cli ping command)
- [x] Create shared network (`wrightnow`) for service communication

### Phase 2: Authentik Integration ✅
- [x] Add authentik-postgres service (separate from main PostgreSQL)
- [x] Configure authentik-postgres with required environment variables
- [x] Add authentik-postgres volume for data persistence
- [x] Add authentik-redis service (separate from main Redis)
- [x] Configure authentik-redis with required settings
- [x] Add authentik-redis volume for data persistence
- [x] Add authentik-server service with ghcr.io/goauthentik/server:latest image
- [x] Configure authentik-server environment variables (SECRET_KEY, POSTGRESQL__*, REDIS__*)
- [x] Add authentik-server volumes (media, templates)
- [x] Configure authentik-server port mappings (9000:9000, 9443:9443)
- [x] Add authentik-server health check
- [x] Add authentik-server depends_on (authentik-postgres, authentik-redis)
- [x] Add authentik-worker service
- [x] Configure authentik-worker with same environment as server
- [x] Add authentik-worker depends_on (authentik-postgres, authentik-redis, authentik-server)

### Phase 3: Configuration and Overrides ✅
- [x] Create `docker-compose.override.yml` for development-specific settings
- [x] Add port mappings in override file for debugging
- [x] Add volume mounts in override file for local development
- [x] Create `.env.example` file with all required environment variables
- [x] Document default PostgreSQL credentials (POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD)
- [x] Document default Redis configuration (optional password)
- [x] Document Authentik configuration variables (AUTHENTIK_SECRET_KEY, AUTHENTIK_ERROR_REPORTING__ENABLED)
- [x] Add security warnings for development-only credentials

### Phase 4: Database Initialization ✅
- [x] Create `scripts/` directory
- [x] Create `scripts/init-db.sh` for PostgreSQL initialization
- [x] Add pg_vector extension enablement in init-db.sh
- [x] Add initial schema creation (if needed)
- [x] Add database user setup (if needed)
- [x] Make init-db.sh executable (chmod +x)
- [x] Add init-db.sh as volume mount in PostgreSQL service
- [x] Test pg_vector extension installation

### Phase 5: Health Check and Utilities ✅
- [x] Create `scripts/wait-for-services.sh` utility script
- [x] Add PostgreSQL readiness check in wait-for-services.sh
- [x] Add Redis readiness check in wait-for-services.sh
- [x] Add Authentik readiness check in wait-for-services.sh
- [x] Make wait-for-services.sh executable (chmod +x)
- [x] Test wait-for-services.sh with full stack
- [x] Add timeout and retry logic to wait-for-services.sh

### Phase 6: Documentation ✅
- [x] Create `docs/` directory (if not exists)
- [x] Create `docs/local-development.md` documentation
- [x] Document prerequisites (Docker, Docker Compose versions)
- [x] Document quick start commands (`docker-compose up -d`)
- [x] Document how to access each service (URLs, ports, credentials)
- [x] Document Authentik initial setup steps
- [x] Document how to stop services (`docker-compose down`)
- [x] Document how to view logs (`docker-compose logs -f`)
- [x] Document how to reset environment (remove volumes)
- [x] Document common troubleshooting issues
- [x] Document integration with CI/CD pipeline

### Phase 7: Testing and Validation ✅
- [x] Test `docker-compose up -d` starts all services without errors
- [x] Verify PostgreSQL is accessible at localhost:5432
- [x] Connect to PostgreSQL and verify pg_vector extension is enabled
- [x] Verify Redis is accessible at localhost:6379
- [x] Test Redis connection with redis-cli
- [x] Verify Authentik UI is accessible at http://localhost:9000
- [x] Complete Authentik initial setup in browser
- [x] Verify all services pass health checks
- [x] Test `docker-compose down` stops all services cleanly
- [x] Test `docker-compose up -d` after down (data persistence)
- [x] Verify volumes persist data across restarts
- [x] Test network connectivity between services (e.g., ping from container to container)
- [x] Test wait-for-services.sh script execution
- [x] Verify environment variables are loaded correctly from .env

### Phase 8: CI/CD Integration (Deferred to Sprint 0 Task 1.2 completion)
- [ ] Update `.github/workflows/test.yml` to use Docker Compose for integration tests
- [ ] Add docker-compose up step in CI pipeline
- [ ] Add wait-for-services.sh execution in CI pipeline
- [ ] Verify integration tests can connect to PostgreSQL
- [ ] Verify integration tests can connect to Redis
- [ ] Add docker-compose down cleanup step in CI pipeline
- [ ] Test full CI pipeline with new Docker Compose setup

### Phase 9: OpenSpec Validation ✅
- [x] Run `openspec validate add-docker-compose-dev-environment --strict`
- [x] Fix any validation errors
- [x] Verify all spec requirements have scenarios
- [x] Verify all tasks are mapped to requirements
- [x] Update proposal.md validation criteria checklist

## Task Dependencies

```
Phase 1 (Core) → Phase 2 (Authentik) → Phase 3 (Config) → Phase 4 (Init Scripts)
                                                         ↓
Phase 5 (Health Checks) → Phase 6 (Docs) → Phase 7 (Testing) → Phase 8 (CI/CD) → Phase 9 (Validation)
```

## Implementation Complete

**Status:** COMPLETE (except Phase 8 CI/CD integration, which will be addressed separately)

**Completed:** 2025-11-10

**Verification Results:**
- ✅ All services started successfully
- ✅ PostgreSQL accessible with pg_vector extension (version 0.8.1)
- ✅ Redis accessible and responding to PING
- ✅ Authentik UI accessible at http://localhost:9000
- ✅ All core services showing healthy status
- ✅ Docker networking configured correctly
- ✅ Data persistence verified through volumes

**Phase 8 Note:** CI/CD integration tasks are intentionally left incomplete as they require updating existing GitHub Actions workflows, which should be done as part of a comprehensive CI/CD update when services are scaffolded.

## Success Criteria
All core tasks have been completed and all validation criteria from proposal.md have been met. The Docker Compose development environment is fully operational and ready for service development.
