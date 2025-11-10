# docker-environment Specification

## Purpose
TBD - created by archiving change add-docker-compose-dev-environment. Update Purpose after archive.
## Requirements
### Requirement: Local Development Environment Orchestration
The system SHALL provide a Docker Compose configuration that orchestrates all required infrastructure services for local development.

#### Scenario: Starting the development environment
- **GIVEN** a developer has Docker and Docker Compose installed
- **AND** they have cloned the repository
- **WHEN** they run `docker-compose up -d`
- **THEN** all services (PostgreSQL, Redis, Authentik) shall start successfully
- **AND** all services shall be reachable within 60 seconds
- **AND** no manual configuration steps shall be required beyond copying `.env.example` to `.env`

#### Scenario: Stopping the development environment
- **GIVEN** the development environment is running
- **WHEN** the developer runs `docker-compose down`
- **THEN** all services shall stop cleanly without errors
- **AND** persistent data shall remain in named volumes
- **AND** no orphaned containers shall remain

#### Scenario: Restarting with persisted data
- **GIVEN** the development environment was previously running
- **AND** the developer has stopped the services with `docker-compose down`
- **WHEN** they run `docker-compose up -d` again
- **THEN** all services shall start with previously persisted data intact
- **AND** PostgreSQL shall contain the same databases as before shutdown
- **AND** Redis shall restore any persisted data from RDB/AOF

### Requirement: PostgreSQL Database with Vector Extension
The system SHALL provide a PostgreSQL 15+ database with the pg_vector extension enabled for vector similarity search.

#### Scenario: PostgreSQL accessibility
- **GIVEN** the development environment is running
- **WHEN** a developer connects to `localhost:5432` with credentials from `.env`
- **THEN** the connection shall succeed
- **AND** the database specified in `POSTGRES_DB` shall exist
- **AND** the user shall have full permissions on the database

#### Scenario: pg_vector extension availability
- **GIVEN** the development environment is running
- **AND** a developer has connected to PostgreSQL
- **WHEN** they execute `SELECT * FROM pg_extension WHERE extname = 'vector';`
- **THEN** the pg_vector extension shall be listed as installed
- **AND** vector operations (e.g., `CREATE TABLE test (embedding vector(768));`) shall succeed

#### Scenario: Database initialization
- **GIVEN** the development environment is starting for the first time
- **WHEN** PostgreSQL initializes
- **THEN** the initialization script (`init-db.sh`) shall run automatically
- **AND** the pg_vector extension shall be enabled
- **AND** any required initial schema shall be created

### Requirement: Redis Cache Service
The system SHALL provide a Redis 7+ cache service for session management and permission caching.

#### Scenario: Redis accessibility
- **GIVEN** the development environment is running
- **WHEN** a developer connects to `localhost:6379`
- **THEN** the connection shall succeed
- **AND** basic Redis commands (SET, GET, PING) shall work

#### Scenario: Redis persistence
- **GIVEN** the development environment is running
- **AND** a developer has set keys in Redis
- **WHEN** the services are stopped with `docker-compose down`
- **AND** restarted with `docker-compose up -d`
- **THEN** RDB snapshot shall restore persisted keys
- **AND** AOF log shall replay recent operations
- **AND** data loss shall be minimal (< 1 second of operations)

### Requirement: Authentik OIDC Provider
The system SHALL provide an Authentik identity provider configured for OIDC authentication.

#### Scenario: Authentik UI accessibility
- **GIVEN** the development environment is running
- **WHEN** a developer navigates to `http://localhost:9000`
- **THEN** the Authentik web interface shall load successfully
- **AND** the initial setup wizard shall be presented on first access
- **AND** the developer shall be able to create an admin account

#### Scenario: Authentik API availability
- **GIVEN** the development environment is running
- **AND** Authentik has completed initialization
- **WHEN** a request is made to `http://localhost:9000/api/v3/`
- **THEN** the API shall respond with a valid JSON response
- **AND** the response shall indicate successful API availability

#### Scenario: OIDC endpoint availability
- **GIVEN** the development environment is running
- **AND** Authentik is configured with an OIDC provider
- **WHEN** a request is made to `http://localhost:9000/application/o/.well-known/openid-configuration`
- **THEN** the OIDC discovery document shall be returned
- **AND** the document shall contain valid JWKS, authorization, and token endpoints

### Requirement: Service Health Monitoring
The system SHALL provide health checks for all services to ensure reliability and correct startup ordering.

#### Scenario: PostgreSQL health check
- **GIVEN** the PostgreSQL service is starting
- **WHEN** the health check executes `pg_isready -U postgres`
- **THEN** the health check shall return success when PostgreSQL accepts connections
- **AND** dependent services shall wait for healthy status before starting
- **AND** `docker-compose ps` shall show "healthy" status for PostgreSQL

#### Scenario: Redis health check
- **GIVEN** the Redis service is starting
- **WHEN** the health check executes `redis-cli ping`
- **THEN** the health check shall return success when Redis responds with PONG
- **AND** dependent services shall wait for healthy status before starting
- **AND** `docker-compose ps` shall show "healthy" status for Redis

#### Scenario: Authentik health check
- **GIVEN** the Authentik server is starting
- **WHEN** the health check performs HTTP request to `/api/v3/`
- **THEN** the health check shall return success when the API responds
- **AND** the worker service shall wait for server healthy status
- **AND** `docker-compose ps` shall show "healthy" status for Authentik server

#### Scenario: Service dependency ordering
- **GIVEN** the development environment is starting
- **WHEN** Docker Compose processes the `depends_on` directives
- **THEN** PostgreSQL and Redis shall start first (no dependencies)
- **AND** Authentik server shall wait for authentik-postgres and authentik-redis to be healthy
- **AND** Authentik worker shall wait for authentik-server to be healthy
- **AND** no service shall fail due to premature connection attempts

### Requirement: Service Network Communication
The system SHALL provide a dedicated Docker network enabling service-to-service communication via DNS.

#### Scenario: DNS-based service discovery
- **GIVEN** the development environment is running
- **AND** a service container needs to connect to another service
- **WHEN** the service uses the service name as hostname (e.g., `postgres`, `redis`)
- **THEN** the hostname shall resolve to the correct container IP address
- **AND** the connection shall succeed

#### Scenario: Network isolation
- **GIVEN** the development environment is running
- **WHEN** services communicate over the `wrightnow` network
- **THEN** all communication shall occur within the isolated Docker network
- **AND** external access shall only be available via exposed ports (5432, 6379, 9000)
- **AND** services shall not be accessible from other Docker networks

#### Scenario: Service connectivity testing
- **GIVEN** the development environment is running
- **WHEN** a developer executes `docker exec -it postgres ping redis -c 1`
- **THEN** the ping shall succeed, confirming network connectivity
- **AND** the resolved IP shall be the Redis container's internal address

### Requirement: Data Persistence Strategy
The system SHALL provide named volumes for all persistent data to ensure data survives container recreation.

#### Scenario: PostgreSQL data persistence
- **GIVEN** the development environment is running
- **AND** a developer has created tables and inserted data
- **WHEN** the developer runs `docker-compose down` (without `-v` flag)
- **AND** then runs `docker-compose up -d`
- **THEN** the PostgreSQL data shall be intact
- **AND** all tables and rows shall be preserved
- **AND** the volume `postgres-data` shall contain the persisted data

#### Scenario: Redis data persistence
- **GIVEN** the development environment is running
- **AND** a developer has set keys in Redis
- **WHEN** the developer runs `docker-compose down` and `docker-compose up -d`
- **THEN** the Redis data shall be restored from RDB snapshot
- **AND** the volume `redis-data` shall contain the RDB file

#### Scenario: Authentik data persistence
- **GIVEN** the development environment is running
- **AND** Authentik has been configured with users and applications
- **WHEN** the developer restarts the services
- **THEN** all Authentik configuration shall persist
- **AND** the volumes `authentik-postgres-data`, `authentik-media`, `authentik-templates` shall preserve data

#### Scenario: Complete environment reset
- **GIVEN** the development environment is running or stopped
- **WHEN** the developer runs `docker-compose down -v`
- **THEN** all named volumes shall be deleted
- **AND** the next `docker-compose up -d` shall start with a fresh environment
- **AND** all databases shall be re-initialized

### Requirement: Environment Variable Management
The system SHALL provide a secure and flexible environment variable configuration system.

#### Scenario: Environment template availability
- **GIVEN** a new developer has cloned the repository
- **WHEN** they inspect the root directory
- **THEN** a `.env.example` file shall be present
- **AND** the file shall contain all required environment variables with example values
- **AND** the file shall include security warnings about development-only credentials

#### Scenario: Environment variable loading
- **GIVEN** a developer has copied `.env.example` to `.env`
- **AND** they have customized values in `.env`
- **WHEN** they run `docker-compose up -d`
- **THEN** all services shall load environment variables from `.env`
- **AND** PostgreSQL shall use the `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD` values
- **AND** Authentik shall use the `AUTHENTIK_SECRET_KEY` and database connection values

#### Scenario: Security of credentials
- **GIVEN** the repository has a `.gitignore` file
- **WHEN** a developer creates a `.env` file with real credentials
- **THEN** the `.env` file shall not be tracked by Git
- **AND** no credentials shall be committed to the repository
- **AND** `.env.example` shall only contain placeholder values

### Requirement: Developer Documentation
The system SHALL provide comprehensive documentation enabling new developers to set up the environment quickly.

#### Scenario: Quick start documentation
- **GIVEN** a new developer has cloned the repository
- **WHEN** they read `docs/local-development.md`
- **THEN** they shall find clear step-by-step setup instructions
- **AND** the instructions shall include prerequisites (Docker version requirements)
- **AND** the instructions shall include troubleshooting for common issues
- **AND** the developer shall be able to complete setup in under 10 minutes

#### Scenario: Service access documentation
- **GIVEN** the development environment is running
- **WHEN** a developer refers to the documentation
- **THEN** they shall find the connection details for each service
- **AND** example connection commands shall be provided for PostgreSQL, Redis, and Authentik

### Requirement: CI/CD Pipeline Integration
The system SHALL integrate with the GitHub Actions CI/CD pipeline to enable integration testing.

#### Scenario: CI/CD environment startup
- **GIVEN** a GitHub Actions workflow is executing
- **WHEN** the workflow runs `docker-compose up -d`
- **THEN** all services shall start successfully in the CI environment
- **AND** the workflow shall be able to execute `./scripts/wait-for-services.sh`
- **AND** integration tests shall be able to connect to PostgreSQL and Redis

#### Scenario: CI/CD environment cleanup
- **GIVEN** a GitHub Actions workflow has completed integration tests
- **WHEN** the workflow runs `docker-compose down -v`
- **THEN** all services shall stop cleanly
- **AND** all volumes shall be removed
- **AND** no orphaned resources shall remain for the next workflow run

#### Scenario: Test isolation
- **GIVEN** multiple CI/CD workflow runs are executing concurrently
- **WHEN** each workflow starts its own Docker Compose environment
- **THEN** each environment shall be isolated from others
- **AND** port conflicts shall be avoided
- **AND** tests shall not interfere with each other

