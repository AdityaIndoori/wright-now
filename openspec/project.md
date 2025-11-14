# Project Context

## Purpose

**WRight Now** is a fast, simple, and secure SaaS knowledge base platform designed to replace clunky incumbents like Confluence and Notion. Our core value proposition is: "All your team's knowledge, instantly searchable. No setup required."

### Goals
- Build the fastest internal knowledge base for modern teams (sub-100ms search response)
- Deliver a zero-trust, permissions-first architecture ensuring enterprise-grade security
- Provide a lightweight, intuitive user experience that requires zero training
- Build on 100% FOSS (Free and Open-Source Software) to ensure data privacy, cost control, and zero vendor lock-in
- Enable offline-first collaboration across all platforms (Web, Desktop, Mobile)

### Key Differentiators
1. **AI Command Bar (RAG Search):** Sub-100ms Cmd/Ctrl+K search using Retrieval-Augmented Generation
2. **"No-Blocks" Editor:** Fast, Google Docs-style collaborative editor without block complexity
3. **Permissions-First Security:** Zero-trust architecture where all data is inaccessible by default
4. **AI-Powered Organization:** Auto-tagging and smart folder suggestions
5. **100% FOSS Backend:** Complete data ownership and control

## Tech Stack

### Frontend (Finalized Nov 2025)
- **Web:** React 18 + TypeScript with Vite build tool - Modern hooks, functional components, and Yjs CRDT for real-time collaboration
- **Mobile & Desktop:** Flutter 3.x (Dart) - Single codebase for iOS, Android, Windows, macOS, and Linux with native performance
- **Real-time Collaboration:** Yjs (CRDT library) for conflict-free document merging (web-native, Flutter uses custom sync)
- **Offline Storage:** 
  - Web: IndexedDB (y-indexeddb)
  - Mobile/Desktop (Flutter): Hive or Isar for local storage

**Architecture Decision Record (Nov 2025):**
- **Why React for Web:** Mature ecosystem, best-in-class Yjs integration, performance meets NFRs (<100ms modal open), large talent pool, rich component libraries
- **Why Flutter for Mobile/Desktop:** Single codebase across 5 platforms (vs 3 separate Electron + React Native codebases), native performance, consistent UI/UX, reduced maintenance overhead, estimated 1-2 weeks time savings in Sprint 11

### Backend Services
- **Core Backend:** Nest.js (TypeScript) - Handles AuthZ, CRUD, permissions, teams, notifications
- **AI Service:** FastAPI (Python 3.11+) with LangChain - Handles RAG search, embeddings, folder suggestions, auto-tagging
- **Real-time Service:** Nest.js WebSocket Gateway + y-websocket for live document collaboration
- **API Gateway:** Nest.js - JWT validation, routing, rate limiting

### Data Layer
- **Primary Database:** PostgreSQL with pg_vector extension for vector similarity search
- **Cache:** Redis - For session management and permission-check caching (p99 <10ms target)
- **Authentication:** Pluggable OIDC-based FOSS IdP (Authentik or Keycloak)
- **Inter-Service Communication:** gRPC with Protocol Buffers (proto3)

### AI/ML Stack
- **Embeddings:** sentence-transformers or OpenAI API for text vectorization (self-hosted preferred for cost savings)
- **LLM:** Open-source models (e.g., Llama 3 8B) for RAG synthesis and content analysis, or OpenAI/Anthropic APIs
- **Vector Search:** PostgreSQL pg_vector for semantic search
- **Framework:** LangChain for RAG pipeline orchestration

**AI Stack Rationale (Nov 2025):**
- **Why FastAPI + Python:** Superior AI/ML ecosystem (LangChain, transformers, sentence-transformers), self-hosted embeddings reduce costs vs API-only approach, faster AI feature development, industry standard for AI microservices

### DevOps & Infrastructure
- **Containerization:** Docker
- **Orchestration:** Kubernetes
- **CI/CD:** GitHub Actions + ArgoCD (GitOps)
- **Testing:** Jest (Backend), Pytest (AI Service), Vitest (Web), flutter test (Mobile/Desktop), Playwright (E2E)

## Project Conventions

### Code Style

#### TypeScript/JavaScript (Nest.js, React)
- **Principles:** SOLID design principles, Dependency Injection
- **Style:** ESLint with strict configuration, Prettier for formatting
- **Naming:**
  - Classes: PascalCase (e.g., `PermissionsService`)
  - Functions/Variables: camelCase (e.g., `getUserPermissions`)
  - Constants: UPPER_SNAKE_CASE (e.g., `MAX_CACHE_TTL`)
  - Interfaces: PascalCase prefixed with `I` (e.g., `IPermissionCheck`)
- **Imports:** Absolute imports using path aliases (`@/services/...`)

#### Python (FastAPI AI Service)
- **Style:** Black formatter (strict), Pylint for linting
- **Type Hints:** Required for all function signatures
- **Naming:**
  - Classes: PascalCase
  - Functions/Variables: snake_case
  - Constants: UPPER_SNAKE_CASE

#### General Rules
- Maximum line length: 100 characters
- No unused imports or variables
- Prefer functional programming patterns where appropriate
- All exports must be explicit (no default exports in TypeScript modules)

### Architecture Patterns

#### Microservices Architecture
- **Core Service:** Handles all relational data, AuthZ, and business logic
- **AI Service:** Stateless, handles all AI/LLM operations
- **Real-time Service:** Manages WebSocket connections and CRDT synchronization
- **API Gateway:** Single entry point for all client requests

#### Zero-Trust Security (Permissions-First)
- **Default Deny:** All resources are inaccessible by default
- **Explicit Grants:** Permissions must be explicitly granted at user/team/guest level
- **Privilege Calculation:** Highest privilege wins (Read + Write = Write)
- **Hot Path Optimization:** Permission checks cached in Redis (p99 <10ms)
- **Scope Filtering:** All queries must include org_id to prevent cross-organization data leakage

#### CRDT-Based Collaboration
- **Library:** Yjs for all document state management
- **Conflict Resolution:** Automatic, mathematically guaranteed conflict-free merging
- **Offline-First:** All edits work offline, sync automatically on reconnection
- **Persistence:** Server-side Yjs state periodically persisted to PostgreSQL

#### gRPC Service Communication
- **Protocol:** Protocol Buffers (proto3) for type-safe contracts
- **Services:**
  - `permissions.proto`: Core AuthZ checks (Can, GetReadableDocs)
  - `ai.proto`: AI operations (GetSearchAnswer, GetFolderSuggestion, IndexDocument)
- **Error Handling:** Structured error codes, no raw exceptions across service boundaries

### Testing Strategy

#### Test-Driven Development (TDD)
- **Mandatory Cycle:** Red (failing test) → Green (minimal code) → Refactor
- **Coverage Target:** Minimum 80% code coverage for all services
- **No Exceptions:** Every feature PR must include tests that define the feature

#### Testing Pyramid

**Level 1: Unit Tests (Fast & Isolated)**
- **Backend (Jest):** Mock all dependencies (DB, Cache, gRPC clients)
  - Test: `PermissionsService.can()` logic, privilege calculation, cache behavior
- **AI Service (Pytest):** Mock gRPC calls, mock LLM responses
  - Test: Query builders, vector search pipelines, permission filtering
- **Web Client (Vitest):** Mock props, hooks, context
  - Test: React component rendering, user interactions, state management
- **Mobile/Desktop Client (flutter test):** Mock services and state
  - Test: Flutter widget behavior, navigation, offline sync logic

**Level 2: Integration Tests (Connected)**
- **Testcontainers:** Spin up ephemeral PostgreSQL, Redis, and IdP instances
  - Test: Real database queries, cache integration, gRPC contracts
- **gRPC Tests:** Validate proto contracts between services
- **WebSocket Tests:** Test real-time collaboration handshake and sync

**Level 3: End-to-End Tests (Real-World)**
- **Framework:** Playwright
- **Scope:** Full user journeys from browser
- **Example:** Create doc as User A → Share with User B → Verify User B can access
- **Environment:** Full Docker Compose stack in CI

#### Test Organization
- Unit tests: Co-located with source files (`*.spec.ts`, `*_test.py`)
- Integration tests: `tests/integration/` directory
- E2E tests: `tests/e2e/` directory
- Test fixtures: `tests/fixtures/` for shared test data

### Git Workflow

#### Branching Strategy (GitFlow-lite)
- **main:** Production branch (protected, requires PR approval)
- **feature/feature-name:** All development work
- **hotfix/issue-name:** Critical production fixes
- **No direct commits to main**

#### Pull Request Process
1. Create feature branch from main
2. Write failing tests (TDD Red phase)
3. Implement feature (TDD Green phase)
4. Refactor and ensure all tests pass
5. Push and create PR with descriptive title
6. PR must pass all CI checks:
   - Linting (ESLint/Black)
   - Unit tests with coverage
   - Integration tests
   - Build validation
7. Require 1 peer review approval
8. Squash merge to main

#### Commit Conventions
- **Format:** `type(scope): description`
- **Types:** feat, fix, docs, style, refactor, test, chore
- **Examples:**
  - `feat(permissions): add team-based permission calculation`
  - `fix(editor): resolve cursor position sync issue`
  - `test(ai): add unit tests for RAG pipeline`

#### CI/CD Pipeline
- **CI (GitHub Actions):**
  1. Lint & format check
  2. Run unit tests with coverage report
  3. Run integration tests (with Testcontainers)
  4. Run E2E tests (Playwright)
  5. Build Docker images
  6. Push images to registry (on main branch only)

- **CD (ArgoCD - GitOps):**
  - **Staging:** Auto-deploy from main branch
  - **Production:** Manual promotion (merge main → production branch)
  - ArgoCD monitors Git and syncs to Kubernetes cluster

## Domain Context

### Knowledge Management Domain
- **Documents:** Markdown-based content with real-time collaboration
- **Spaces:** Top-level organizational containers (e.g., Engineering, HR, Marketing)
- **Folders:** Nested organization within Spaces
- **Hierarchy:** Simple tree structure (Spaces → Folders → Documents)

### RAG (Retrieval-Augmented Generation)
- **Purpose:** Answer natural language queries using company knowledge
- **Process:**
  1. User query → Embed query vector
  2. Perform permission-filtered vector similarity search
  3. Retrieve top-k relevant document chunks
  4. Pass (query + context) to LLM for synthesis
  5. Return direct answer + source citations
- **Constraints:** Must only search documents user has explicit read access to

### Permissions Model
- **Principals:** Users, Teams, Guests (external)
- **Resources:** Documents, Spaces
- **Levels:** Read, Write, Share
- **Inheritance:** Space-level permissions cascade to documents within
- **Priority:** Highest privilege wins when user has multiple permission paths

### Real-Time Collaboration
- **CRDT (Conflict-Free Replicated Data Type):** Mathematical guarantee of eventual consistency
- **Yjs Specifics:**
  - Multi-user cursors with colors
  - Character-by-character synchronization
  - Automatic conflict resolution
  - No "save" button needed (auto-persisted)

## Important Constraints

### Performance Requirements (Non-Functional Requirements)
- **NFR 2.1:** Permission checks (hot path) must resolve in p99 <10ms
  - Achieved via Redis caching with 5-minute TTL
- **NFR 2.2:** All standard API endpoints must respond in p95 <200ms
- **NFR 2.3:** Cmd+K modal must open in <100ms
  - Modal UI is pre-rendered, only search results are fetched on demand
- **NFR 3.1:** Backend services must be stateless and horizontally scalable

### Security Requirements
- **NFR 1.1:** Zero-Trust Architecture
  - All API endpoints protected by AuthN middleware (JWT validation)
  - All resource access protected by AuthZ checks (PermissionsService)
  - No data accessible without explicit permission grant
- **NFR 1.2:** Data Encryption
  - At-rest: PostgreSQL Transparent Data Encryption (TDE)
  - In-transit: TLS 1.3 for all connections
  - Offline: Client-side databases encrypted (native OS encryption)
- **NFR 1.3:** Data Isolation
  - Hard org_id filtering on all database queries
  - No cross-organization data leakage possible

### Reliability Requirements
- **NFR 4.1:** System uptime target of 99.9%
- **NFR 4.2:** Yjs CRDT guarantees no data loss during offline sync
- **NFR 4.3:** Graceful degradation (offline mode when network unavailable)

### FOSS Commitment
- **Backend:** 100% open-source stack (no proprietary dependencies)
- **Self-Hosting:** Full product must be self-hostable without feature loss
- **Licensing:** Backend code released under permissive open-source license
- **No Vendor Lock-In:** Standard protocols (OIDC, gRPC, PostgreSQL)

## External Dependencies

### Authentication Provider (IdP)
- **Type:** OIDC-compatible open-source IdP
- **Options:** Authentik (preferred) or Keycloak
- **Purpose:** 
  - User authentication (sign-up, sign-in)
  - JWT token issuance
  - Optional: SCIM for user/group provisioning
- **Integration:** JWT validation via JWKS endpoint
- **Stored Data:** Users table syncs `idp_subject_id` (sub claim) for linking

### LLM/Embedding Models
- **Embedding Model:** Open-source text embedding model (e.g., sentence-transformers)
- **LLM for RAG:** Open-source instruction-tuned model (e.g., Llama 3 8B)
- **Deployment:** Self-hosted via containers (no external API calls)
- **Constraint:** Model must fit in reasonable compute budget for self-hosters

### Yjs Collaboration
- **Library:** Yjs (npm package)
- **Server:** y-websocket provider (runs in Real-time Service)
- **Protocol:** WebSocket-based binary protocol
- **Storage:** Yjs state persisted to PostgreSQL as binary blob

### PostgreSQL Extensions
- **pg_vector:** Vector similarity search extension
  - Required for semantic search functionality
  - Must be installed on PostgreSQL instance

### Development & CI Tools
- **GitHub Actions:** CI pipeline execution
- **Testcontainers:** Ephemeral infrastructure for integration tests
- **Docker Registry:** Container image storage
- **Kubernetes Cluster:** Production deployment target (can be self-hosted)

### Monitoring & Observability (Post-MVP)
- **Metrics:** Prometheus (planned)
- **Logs:** Structured JSON logging to stdout (container-native)
- **Tracing:** OpenTelemetry (planned)
