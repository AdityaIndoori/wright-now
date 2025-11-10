# Design: Docker Compose Development Environment

## Overview
This document captures the architectural reasoning and trade-offs for the Docker Compose development environment. It explains the "why" behind technical decisions that impact the project's development experience, testing strategy, and future scalability.

## Architecture Context

### Problem Statement
The WRight Now MVP requires a complex microservices architecture with:
- Multiple databases (PostgreSQL with pg_vector)
- Caching layer (Redis)
- External authentication provider (OIDC-compliant IdP)
- Multiple backend services (Core, AI, Real-time)
- Cross-platform clients (Web, Desktop, Mobile)

Developers need a way to:
1. Run all infrastructure services locally without complex manual setup
2. Test integration between services with real infrastructure
3. Match production-like behavior as closely as possible
4. Onboard new team members quickly (<10 minutes)
5. Enable TDD with database-backed tests (NFR 5.1)

### Solution Approach
Docker Compose provides:
- Declarative infrastructure configuration (infrastructure as code)
- Consistent environment across developer machines
- Isolated network for service communication
- Volume persistence for data across restarts
- Easy integration with CI/CD pipelines

## Key Design Decisions

### Decision 1: Docker Compose vs Alternatives

**Options Considered:**
1. **Docker Compose** (chosen)
2. **Kubernetes (minikube/kind) locally**
3. **Individual Docker run commands**
4. **Native installations (brew/apt/choco)**

**Decision:** Docker Compose

**Rationale:**
- **Simplicity:** Single `docker-compose up` command vs complex K8s manifests
- **Development-optimized:** Faster iteration than K8s (no pod restart delays)
- **Resource efficiency:** Lower overhead than full K8s cluster locally
- **Learning curve:** Team already knows Docker, K8s is overkill for local dev
- **CI/CD alignment:** GitHub Actions has excellent Docker Compose support

**Trade-offs:**
- ✅ **Pro:** Fast, simple, resource-efficient
- ✅ **Pro:** Matches production patterns (services, networks, volumes)
- ❌ **Con:** Not identical to production (K8s in production, Compose in dev)
- ❌ **Con:** Limited orchestration features vs K8s
- **Mitigation:** K8s staging environment (Sprint 0, Task 1.4) will catch environment-specific issues

### Decision 2: Authentik vs Keycloak

**Options Considered:**
1. **Authentik** (chosen)
2. **Keycloak**
3. **Ory Hydra**

**Decision:** Authentik

**Rationale:**
- **Modern UX:** Better developer onboarding experience
- **Python-native:** Aligns with AI service stack, easier debugging
- **Docker-first:** Simpler compose setup (official images, good docs)
- **OIDC support:** Excellent OIDC/OAuth2 implementation out of the box
- **TDD recommendation:** Mentioned in Technical Design Document
- **Active development:** Faster feature releases, better community support

**Keycloak weaknesses:**
- Java-based (JVM overhead ~500MB RAM)
- Complex configuration (realm exports, arcane XML)
- Slower startup time (~60s vs Authentik's ~20s)

**Trade-offs:**
- ✅ **Pro:** Faster, lighter, easier to configure
- ✅ **Pro:** Better developer experience (modern UI)
- ❌ **Con:** Less enterprise adoption than Keycloak
- ❌ **Con:** Smaller plugin ecosystem
- **Mitigation:** Both are OIDC-compliant; switching later is possible via interface

### Decision 3: Network Architecture (Single vs Multiple Networks)

**Options Considered:**
1. **Single bridge network** (chosen)
2. **Multiple isolated networks** (e.g., frontend-net, backend-net, db-net)
3. **Host networking**

**Decision:** Single bridge network (`wrightnow`)

**Rationale:**
- **Simplicity:** All services can discover each other via DNS
- **Development-friendly:** Easier debugging (can exec into any container, ping any service)
- **Production pattern:** Mirrors Kubernetes pod networking (flat network with policies)
- **No isolation needed:** Development environment, all services are trusted

**Why not multiple networks:**
- Adds complexity without security benefit (local dev is already trusted)
- Makes debugging harder (need to understand network topology)
- Production security is handled by Kubernetes network policies (Sprint 0, Task 1.4)

**Trade-offs:**
- ✅ **Pro:** Simple, predictable, easy to debug
- ✅ **Pro:** Mirrors production pod networking semantics
- ❌ **Con:** No network isolation between tiers (not needed for dev)
- **Mitigation:** Production uses K8s network policies for isolation

### Decision 4: Volume Strategy (Named Volumes vs Bind Mounts)

**Options Considered:**
1. **Named volumes** (chosen)
2. **Bind mounts** (e.g., `./data/postgres:/var/lib/postgresql/data`)
3. **Anonymous volumes**

**Decision:** Named volumes for all persistent data

**Rationale:**
- **Performance:** On Windows/Mac, named volumes are 10-100x faster than bind mounts (Docker volume is Linux VM-native)
- **Portability:** Works identically on Linux, Mac, Windows
- **Cleanliness:** Doesn't clutter project directory with data files
- **Docker-managed:** Easy backup (`docker volume export`), migration, inspection
- **Survives restarts:** Data persists across `docker-compose down` and `up`

**Why not bind mounts:**
- Terrible performance on Mac/Windows (filesystem translation layer)
- Ownership/permission issues (UID/GID mismatches)
- Clutters git repo (need .gitignore for data folders)

**Trade-offs:**
- ✅ **Pro:** Fast, portable, clean
- ✅ **Pro:** Easier to reset (docker-compose down -v)
- ❌ **Con:** Harder to inspect data directly (need docker exec)
- **Mitigation:** Use `docker exec -it postgres psql` for database inspection

### Decision 5: PostgreSQL Configuration (Single vs Separate for Authentik)

**Options Considered:**
1. **Separate PostgreSQL instances** (chosen: `postgres` + `authentik-postgres`)
2. **Single shared PostgreSQL instance** (multiple databases)

**Decision:** Separate PostgreSQL instances

**Rationale:**
- **Isolation:** Authentik cannot affect application data
- **Version independence:** Can upgrade app DB independently of Authentik DB
- **Authentik best practice:** Authentik docs recommend dedicated database
- **Failure isolation:** If Authentik DB corrupts, app data is unaffected
- **Resource-realistic:** Production would have separate RDS instances

**Trade-offs:**
- ✅ **Pro:** Safer, more production-like
- ✅ **Pro:** Easier troubleshooting (separate logs)
- ❌ **Con:** Uses more resources (~200MB extra RAM)
- ❌ **Con:** Two databases to manage
- **Mitigation:** Development machines have sufficient RAM; automation handles both

### Decision 6: Health Checks Strategy

**Options Considered:**
1. **Built-in Docker health checks** (chosen)
2. **wait-for-it.sh scripts only**
3. **No health checks**

**Decision:** Built-in Docker health checks for all services

**Rationale:**
- **Dependency management:** `depends_on` with `condition: service_healthy` ensures correct startup order
- **CI/CD reliability:** GitHub Actions can wait for services before running tests
- **Developer feedback:** `docker-compose ps` shows health status clearly
- **Production parity:** K8s uses readiness/liveness probes (similar concept)

**Health check implementations:**
- **PostgreSQL:** `pg_isready -U postgres` (fast, official tool)
- **Redis:** `redis-cli ping` (simple, reliable)
- **Authentik:** `wget --no-verbose --tries=1 --spider http://localhost:9000/api/v3/` (HTTP endpoint)

**Trade-offs:**
- ✅ **Pro:** Reliable, clear, production-like
- ✅ **Pro:** Prevents "database connection refused" errors
- ❌ **Con:** Slightly slower startup (waits for healthy state)
- **Mitigation:** Health checks are fast (<5s), worth the reliability

### Decision 7: Environment Variable Management

**Options Considered:**
1. **.env.example + .env (gitignored)** (chosen)
2. **Hardcoded in docker-compose.yml**
3. **External secrets manager (Vault)**

**Decision:** .env.example committed, .env gitignored

**Rationale:**
- **Security:** No credentials in git history
- **Developer-friendly:** Copy .env.example → .env, fill in values
- **Flexibility:** Each developer can customize (e.g., different ports)
- **Production-ready pattern:** Prepares team for K8s secrets workflow

**What goes in .env:**
- PostgreSQL: POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD
- Redis: (optional) REDIS_PASSWORD
- Authentik: AUTHENTIK_SECRET_KEY, AUTHENTIK_POSTGRESQL__*, AUTHENTIK_REDIS__*

**Trade-offs:**
- ✅ **Pro:** Secure, flexible, standard pattern
- ✅ **Pro:** Easy to document, easy to onboard
- ❌ **Con:** Manual step (copy .env.example)
- **Mitigation:** Documentation clearly explains this step

## Integration with Project Architecture

### Alignment with Technical Design Document

The Docker Compose setup directly implements TDD Section 7.2 (Integration Tests):
- **Testcontainers context:** Docker Compose provides the "ephemeral infrastructure" needed
- **gRPC tests:** Can spin up Core Backend + AI Service + Postgres + Redis to test contracts
- **E2E tests:** Playwright can connect to full stack running in Docker

### Service Discovery Pattern

Services communicate via DNS:
```yaml
# Core Backend connects to PostgreSQL via:
DATABASE_URL=postgresql://postgres:password@postgres:5432/wrightnow

# AI Service connects to Core Backend gRPC via:
CORE_BACKEND_GRPC=grpc://core-backend:50051
```

This mirrors Kubernetes service discovery (ServiceName.Namespace.svc.cluster.local).

### CI/CD Integration

GitHub Actions workflow will use Docker Compose:
```yaml
- name: Start infrastructure
  run: docker-compose up -d

- name: Wait for services
  run: ./scripts/wait-for-services.sh

- name: Run integration tests
  run: npm run test:integration

- name: Cleanup
  run: docker-compose down -v
```

## Performance Considerations

### Resource Requirements
- **PostgreSQL:** ~150MB RAM (with pg_vector extension)
- **Redis:** ~20MB RAM
- **Authentik stack:** ~300MB RAM (Postgres + Redis + Server + Worker)
- **Total:** ~500MB RAM, ~5GB disk

**Acceptable for development:** Modern laptops have 8-16GB RAM.

### Startup Time
- **Target:** <60 seconds from `docker-compose up -d` to all services healthy
- **Bottleneck:** Authentik server (~30s startup)
- **Optimization:** Parallel startup with `depends_on` ensures no sequential delays

### Iteration Speed
- **Code changes:** No restart needed (services will be mounted via volumes in later tasks)
- **Database schema changes:** Quick apply via migrations (Prisma/Alembic)
- **Infrastructure changes:** `docker-compose restart <service>` (fast)

## Security Considerations

### Development-Only Credentials
All default credentials are **insecure by design** for ease of development:
- PostgreSQL: `postgres` / `password`
- Authentik: Admin must set password on first login

**Warnings:**
- Clearly documented in README and .env.example
- Never exposed to internet (localhost only)
- Production uses Kubernetes secrets (Sprint 0, Task 1.4)

### Network Isolation
- Services are not exposed to the internet (no 0.0.0.0 bindings)
- Only localhost can connect
- Internal network is isolated from host

## Future Extensibility

### Adding New Services
When adding Core Backend (Sprint 0, Task 3.1):
```yaml
services:
  core-backend:
    build: ./services/core-backend
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      DATABASE_URL: postgresql://postgres:password@postgres:5432/wrightnow
    networks:
      - wrightnow
```

### Supporting Multiple Databases
If future sprints need separate databases (e.g., analytics):
```yaml
services:
  analytics-db:
    image: postgres:15-alpine
    volumes:
      - analytics-data:/var/lib/postgresql/data
    networks:
      - wrightnow
```

### Scaling for Load Testing
For performance testing (Sprint 12):
```yaml
services:
  core-backend:
    deploy:
      replicas: 3  # Simulate horizontal scaling
```

## Alternatives Considered and Rejected

### Alternative 1: Kubernetes (minikube) for Local Development
- **Rejected because:** Too heavyweight for local dev (~2GB RAM overhead)
- **Rejected because:** Slower iteration (need to build images, wait for pod scheduling)
- **Rejected because:** Steeper learning curve for team

### Alternative 2: Cloud Development Environments (GitHub Codespaces)
- **Rejected because:** Not all developers have reliable internet
- **Rejected because:** Offline development is a requirement (per project docs)
- **Rejected because:** Cost for team (billed by compute time)

### Alternative 3: Manual Installation (brew/apt/choco)
- **Rejected because:** Inconsistent across developer machines
- **Rejected because:** Nightmare to document and support
- **Rejected because:** Doesn't work in CI/CD

## Success Metrics

The design succeeds if:
1. ✅ New developers can run full stack in <10 minutes
2. ✅ Zero "works on my machine" issues
3. ✅ Integration tests pass reliably in CI/CD
4. ✅ Services start in <60 seconds
5. ✅ Zero manual configuration required (beyond copying .env.example)

## Conclusion

The Docker Compose approach provides the optimal balance of:
- **Simplicity:** Easy to understand and use
- **Reliability:** Consistent across machines and CI/CD
- **Performance:** Fast enough for development workflows
- **Extensibility:** Easy to add new services as project grows

This design directly supports the project's TDD requirements (NFR 5.1) by providing the infrastructure foundation for integration and E2E tests.
