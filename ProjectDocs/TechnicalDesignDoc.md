# **WRight Now \- Technical Design Document**

## **1\. Introduction and Overview**

### **1.1 Purpose**

This document outlines the technical architecture, component design, data models, and interfaces required to build the Minimum Viable Product (MVP) of "WRight Now." It translates the "what" from the Product Requirements Document (PRD v2.4) into the "how" for the engineering team.

### **1.2 Scope (MVP)**

The scope is the implementation of all features defined in PRD v2.4, including:

* A "permissions-first" microservices architecture.  
* A FOSS-based backend (Nest.js, FastAPI, Postgres) integrated with a FOSS IdP for AuthN.  
* An AI-powered RAG Command Bar (Cmd+K) (Epic 1).  
* A real-time "No-Blocks" collaborative editor (Epic 2).  
* AI-powered Auto-Tagging & Folder Suggestions (Epic 2 & 3).  
* Granular Permissions, User & Team Management (Epic 4, 5).  
* @Mentions & Notifications (Epic 6).  
* Bi-Directional Linking (Epic 7).  
* Cross-platform clients (Web, Desktop, Mobile) with full offline sync (Section 4).

### **1.3 Core Non-Functional Requirements (NFRs)**

Our design is driven by these non-negotiable targets from PRD v5:

* **NFR 1.1:** Zero-Trust Security (all requests are unauthorized by default).  
* **NFR 2.1:** p99 \< 10ms for all permission checks.  
* **NFR 2.2:** p95 \< 200ms for all standard API endpoints.  
* **NFR 2.3:** \< 100ms for the Cmd+K modal to open.  
* **NFR 5.1:** All code must follow Test-Driven Development (TDD).  
* **NFR 5.2:** All features must pass a CI/CD pipeline.

## **2\. System Architecture**

A microservices architecture is chosen to meet the requirements of scalability, maintainability, and technological separation (e.g., Python for AI, TypeScript for backend).

### **2.1 Technology Stack**

* **Identity & AuthN:** Pluggable Open-Source IdP via OIDC. **(e.g., Authentik, Keycloak)**. Manages user sign-up, sign-in, and issues JWTs. (Per PRD Tier 5 SAML requirement).  
* **Core Backend (AuthZ):** **Nest.js** (TypeScript) \- For robust, TDD-friendly, and structured enterprise-grade code.  
* **AI Service:** **FastAPI** (Python) \- For its high performance and native integration with Python-based LLM libraries.  
* **Real-time Service:** **Nest.js** (WebSocket Adapter) \- Managing WebSocket connections and Yjs-based CRDT state.  
* **Database (Relational):** **PostgreSQL** (PRD 1.8) \- For robust relational data.  
* **Database (Vector):** **PostgreSQL** with pg\_vector extension (PRD 1.8) \- For storing and querying text embeddings.  
* **Cache:** **Redis** \- For caching sessions and, most critically, permission-check results (to meet NFR 2.1).  
* **Clients (Web/Desktop):** **React** (or similar) bundled with **Electron** (PRD 4.2).  
* **Clients (Mobile):** **React Native** (PRD 4.3).  
* **CRDT Library:** **Yjs** (PRD 1.8) \- For all real-time collaboration and offline-first sync.

### **2.2 High-Level Architecture (C2)**

This diagram illustrates the flow of requests. The client *first* authenticates (AuthN) with the external IdP to get a JWT. This JWT is then passed to the API Gateway on every request. The Gateway validates the JWT (AuthN) and then proxies to downstream services, which perform fine-grained authorization (AuthZ).

*                  \[User on Web/Desktop/Mobile Client\]  
*                       |        ^  
*                       | (OIDC) | (JWT)  
*                       v        |  
*            \[AuthN IdP (e.g., Authentik)\]  
*                  (Handles Login/Signup)  
*   
*                                  |  
*  \[Client with JWT\]               v  
*                        \[Load Balancer / CDN\]  
*                                  |  
*                                  v  
*                      \[API Gateway (Nest.js)\]  
*                  (JWT Validation, Routing, Rate-Limit)  
*                         |       |       |  
*       \+-----------------+-------+-------+-----------------+  
*       |                 |               |                 |  
*       v                 v               v                 v  
* \[Core Service\]    \[AI Service\]    \[Real-time Svc\]     \[Cache\]  
* (Nest.js)         (FastAPI)       (WebSockets)        (Redis)  
* (App-level AuthZ, (RAG, Search,    (Yjs Sync)  
*  Docs, Teams)     Suggestions)  
*       |                 |               |  
*       \+-----------------+---------------+  
*                         |  
*                         v  
*                  \[Database (PostgreSQL)\]  
*                  (Relational \+ pg\_vector)

## **3\. Detailed Component Design**

This section details the logic, core classes, and TDD approach for each microservice.

### **3.1 Core-Backend-Service (Nest.js)**

This is the stateful brain of the application, managing all relational data and application-level authorization.

* **Structure:** Built with Nest.js modules (OrgModule, UserModule, TeamModule, DocModule, PermissionsModule).  
* **Design Principle:** SOLID. Services are injected via Dependency Injection (DI).

#### **3.1.1 PermissionsModule (The "Permissions-First" Core)**

This module is the heart of our Zero-Trust (NFR 1.1) architecture.

* **Note:** This service handles *fine-grained application-level authorization* (AuthZ), which is distinct from *authentication* (AuthN) handled by the IdP. The IdP determines *who* a user is; this service determines *what* they can do.  
* **PermissionsService (Core Class):**  
* // permissions.service.ts  
* @Injectable()  
* export class PermissionsService {  
*   constructor(  
*     @Inject(CACHE\_MANAGER) private cache: Cache,  
*     private db: PrismaService // or TypeORM  
*   ) {}  
*   
*   /\*\*  
*    \* Checks if a user has a specific permission for a resource.  
*    \* This is the hot-path function, must meet p99 \< 10ms (NFR 2.1).  
*    \* The 'userId' is the trusted 'sub' (subject) from the validated JWT.  
*    \*/  
*   async can(  
*     userId: string, // This is the IdP Subject ID  
*     action: 'read' | 'write' | 'share',  
*     resourceType: 'doc' | 'space',  
*     resourceId: string  
*   ): Promise\<boolean\> {  
*     const cacheKey \= \`perm:${userId}:${resourceId}\`;  
*     const cachedLevel \= await this.cache.get\<string\>(cacheKey);  
*   
*     if (cachedLevel) {  
*       return this.hasSufficientPermission(cachedLevel, action);  
*     }  
*   
*     // 1\. Get user's direct permission on the resource  
*     const directPermission \= await this.db.permission.findFirst(...);  
*   
*     // 2\. Get user's team memberships (from our local synced table)  
*     const teamIds \= await this.db.teamMembership.findMany(...);  
*   
*     // 3\. Get team permissions on the resource  
*     const teamPermissions \= await this.db.permission.findMany(...);  
*   
*     // 4\. Calculate highest privilege (FR 4.3)  
*     const highestLevel \= this.calculateHighestLevel(directPermission, teamPermissions);  
*   
*     // 5\. Cache the result  
*     await this.cache.set(cacheKey, highestLevel, { ttl: 300 }); // 5-min cache  
*   
*     return this.hasSufficientPermission(highestLevel, action);  
*   }  
*   
*   /\*\*  
*    \* Retrieves all readable doc IDs for a user.  
*    \* Used by the AI service for RAG.  
*    \*/  
*   async getReadableDocs(userId: string, orgId: string): Promise\<string\[\]\> {  
*     // Complex query to join user\_permissions and team\_permissions  
*     // This is not on the hot path, so it can be a heavier DB query.  
*     const readableDocs \= await this.db.$queryRaw\<...\>(...);  
*     return readableDocs.map(doc \=\> doc.id);  
*   }  
*   
*   // ... private helper functions  
* }  
* 

#### **3.1.2 DocModule**

* **DocService:** Handles CRUD for documents (create, move, rename).  
* **DocLinksService:** Handles bi-directional linking (Epic 7).  
  * POST /docs (Create):  
    1. Create the doc entry.  
    2. Call PermissionsService to grant owner write access.  
    3. Asynchronously call AI-Service (/v1/suggest-folder) (FR 3.5).  
  * GET /docs/:id/backlinks (FR 7.1):  
    1. SELECT \* FROM doc\_links WHERE target\_doc\_id \= :id.  
    2. For each source\_doc\_id, *must* call PermissionsService.can(userId, 'read', 'doc', source\_doc\_id).  
    3. Return only the list of backlinks the user can *actually read*.

#### **3.1.3 InboxModule (Epic 6\)**

* Handles @mentions.  
* **MentionsService:**  
  * @Mentions in the editor (FR 2.8) trigger an API call: POST /docs/:id/mention.  
  * This service creates an entry in the notifications table for the target user/team.  
  * GET /inbox: Returns notifications for userId, sets read \= true (FR 6.3).

### **3.2 AI-Service (FastAPI)**

This service is stateless and handles all AI/LLM-related computation.

* **POST /v1/search (RAG Search \- Epic 1):**  
  * **Workflow:**  
    1. **Input:** (query: string, userId: string) (userId is the trusted JWT sub)  
    2. **Auth & Permissions (CRITICAL):** The API Gateway *must* inject the userId. The service *first* makes a gRPC call: List\<string\> allowedDocIds \= CoreService.PermissionsService.getReadableDocs(userId) (FR 1.5).  
    3. **Embed Query:** query\_vector \= embed\_model.embed(query)  
    4. **Vector Search (Permissions-First):** SELECT id, content\_chunk FROM doc\_vectors WHERE id IN (allowedDocIds) ORDER BY embedding\_vector \<-\> query\_vector LIMIT 5  
    5. **Context Assembly:** Collate content\_chunks into a context.  
    6. **LLM Synthesis:** Pass (query, context) to LLM (e.g., Llama 3 8B) for synthesis (FR 1.4).  
    7. **Return:** (answer: string, sources: List\[doc\_id\])  
* **POST /v1/index-doc (Async):**  
  * Triggered on doc save.  
  * Chunks doc content, embeds it, and stores it in doc\_vectors.  
  * Also generates and stores keyword tags in the index (FR 2.10).  
* **POST /v1/suggest-folder (Async, FR 3.5):**  
  * Analyzes doc content and returns List\[space\_id, folder\_id, relevance\]

### **3.3 Real-time-Service (WebSockets)**

* **Technology:** Nest.js WebSocket Gateway \+ y-websocket library.  
* **DocSyncGateway (Core Class):**  
  * **Connection Handshake (CRITICAL):**  
    1. Client connects: ws://wrightnow.com/doc/doc\_id\_123  
    2. Client sends **JWT (from IdP)** in connection headers or initial auth message.  
    3. **AuthN:** The Gateway first **validates the JWT signature** against the IdP's public key (JWKS).  
    4. If AuthN fails, disconnect.  
    5. **AuthZ:** On success, extract userId (sub) and call PermissionsService.can(userId, 'write', 'doc', doc\_id\_123) (FR 2.1).  
    6. If true (AuthZ success): Yjs connection is established and CRDTs are synced.  
    7. If false (AuthZ failure): Send error: 'forbidden' message and disconnect.  
  * **Persistence:** The server-side Yjs document is periodically persisted to the docs table (as a content\_crdt\_blob).

## **4\. Data Design & Schema**

Atlassian Section: "Data Design"

This is the low-level schema for the PostgreSQL database. Note the users table no longer contains passwords.

* organizations  
  * id (uuid, pk), name (text)  
* users  
  * id (uuid, pk), org\_id (fk, users.id), email (text, unique), name (text)  
  * **idp\_subject\_id (text, unique, not\_null):** The "sub" claim from the IdP. This is our link to the external IdP user.  
* teams  
  * id (uuid, pk), org\_id (fk, org.id), name (text)  
  * **idp\_group\_id (text, nullable, unique):** Link to an IdP group (for SCIM/OIDC group sync).  
* team\_memberships  
  * user\_id (fk, users.id), team\_id (fk, teams.id) \- (pk: user\_id, team\_id)  
* spaces  
  * id (uuid, pk), org\_id (fk, org.id), name (text)  
* docs  
  * id (uuid, pk), org\_id (fk, org.id), space\_id (fk, spaces.id), parent\_doc\_id (fk, docs.id, nullable \- for nesting), title (text), content\_crdt\_blob (bytea)  
* doc\_vectors (For pg\_vector)  
  * id (uuid, pk), doc\_id (fk, docs.id), content\_chunk (text), embedding (vector(768)), tags (text\[\])  
* permissions (The core of FR 4.1)  
  * id (uuid, pk)  
  * principal\_type (enum: 'user', 'team')  
  * principal\_id (uuid)  
  * resource\_type (enum: 'doc', 'space')  
  * resource\_id (uuid)  
  * level (enum: 'read', 'write', 'share')  
* notifications (For Epic 6\)  
  * id (uuid, pk), user\_id (fk, users.id), doc\_id (fk, docs.id), type (enum: 'mention'), read (boolean, default: false), created\_at (timestamp)  
* doc\_links (For Epic 7\)  
  * source\_doc\_id (fk, docs.id), target\_doc\_id (fk, docs.id) \- (pk: source, target)

## **5\. Interface & API Design**

*Atlassian Section: "Interface Design"*

### **5.1 External API (REST)**

All requests go to the API Gateway. All routes are protected by a middleware chain.

* **Middleware Chain:**  
  1. **AuthN Middleware:** Validates the Authorization: Bearer \<JWT\> token against the IdP's JWKS. If valid, attaches user (with idp\_subject\_id) to the request. If invalid, returns 401 Unauthorized.  
  2. **AuthZ Middleware (Permission-Check):** (Applied on specific routes) Calls PermissionsService.can(...) to check for resource-level access. If invalid, returns 4.03 Forbidden.  
* GET /spaces: Returns all spaces user has read access to.  
* POST /spaces: Create a new space.  
* GET /spaces/:id/docs: Returns docs & folders in a space (filtered by permissions).  
* POST /docs: Create a new doc.  
* GET /docs/:id: Get doc metadata (title, etc.). (Content is synced via WebSocket).  
* PUT /docs/:id: Update doc metadata (title, move).  
* GET /docs/:id/backlinks: (FR 7.1) Returns permission-filtered backlinks.  
* POST /docs/:id/mention: (FR 2.8) Creates a notification.  
* GET /inbox: (FR 6.3) Gets unread notifications.  
* POST /share/doc/:id: (FR 4.2) Sets permissions for a doc.  
* GET /admin/users: (FR 5.1) Admin-only route.

### **5.2 Internal API (gRPC)**

This section defines the synchronous, low-latency communication contracts between our microservices. We use gRPC with Protocol Buffers (proto3) for high performance and strict type-safety.

#### **5.2.1 permissions.proto**

* **File:** protos/permissions.proto  
* **Defines:** The contract for the PermissionsService within the Core-Backend-Service.  
* **Consumers:** AI-Service, Real-time-Service, API-Gateway.  
* syntax \= "proto3";  
*   
* package wrightnow.permissions;  
*   
* // Defines the core service for AuthZ (Authorization) checks  
* service Permissions {  
*   /\*\*  
*    \* Checks if a principal (user) has a specific permission for a resource.  
*    \* This is the hot-path, must meet p99 \< 10ms (NFR 2.1).  
*    \*/  
*   rpc Can (CanRequest) returns (CanResponse);  
*   
*   /\*\*  
*    \* Retrieves a list of all doc\_ids a user has 'read' access to.  
*    \* Used by the AI-Service to create a permission-filtered search context.  
*    \*/  
*   rpc GetReadableDocs (GetReadableDocsRequest) returns (GetReadableDocsResponse);  
* }  
*   
* // \=== Messages for Can \===  
*   
* enum Action {  
*   ACTION\_UNSPECIFIED \= 0;  
*   ACTION\_READ \= 1;  
*   ACTION\_WRITE \= 2;  
*   ACTION\_SHARE \= 3;  
* }  
*   
* enum ResourceType {  
*   RESOURCE\_TYPE\_UNSPECIFIED \= 0;  
*   RESOURCE\_TYPE\_DOC \= 1;  
*   RESOURCE\_TYPE\_SPACE \= 2;  
* }  
*   
* message CanRequest {  
*   string user\_id \= 1; // The IdP Subject ID  
*   Action action \= 2;  
*   ResourceType resource\_type \= 3;  
*   string resource\_id \= 4; // UUID of the doc or space  
* }  
*   
* message CanResponse {  
*   bool allowed \= 1; // True if the action is permitted, false otherwise  
* }  
*   
* // \=== Messages for GetReadableDocs \===  
*   
* message GetReadableDocsRequest {  
*   string user\_id \= 1; // The IdP Subject ID  
*   string org\_id \= 2;  // Org context to scope the query  
* }  
*   
* message GetReadableDocsResponse {  
*   // A list of all document UUIDs the user can read  
*   repeated string readable\_doc\_ids \= 1;  
* }

#### **5.2.2 ai.proto**

* **File:** protos/ai.proto  
* **Defines:** The contract for the AI-Service.  
* **Consumers:** Core-Backend-Service, API-Gateway (potentially).  
* syntax \= "proto3";  
*   
* package wrightnow.ai;  
*   
* // Defines the core service for AI and RAG operations  
* service AI {  
*   /\*\*  
*    \* Gets a direct, synthesized answer for a natural language query.  
*    \* This is the primary function for the Cmd+K bar.  
*    \*/  
*   rpc GetSearchAnswer (SearchRequest) returns (SearchResponse);  
*   
*   /\*\*  
*    \* Suggests the top 3 relevant folders to save a document in.  
*    \* Used on doc creation/move (FR 3.5).  
*    \*/  
*   rpc GetFolderSuggestion (SuggestRequest) returns (SuggestResponse);  
*   
*   /\*\*  
*    \* Asynchronously indexes a document for search (RAG \+ keywords).  
*    \* This is a fire-and-forget call.  
*    \*/  
*   rpc IndexDocument (IndexDocumentRequest) returns (IndexDocumentResponse);  
* }  
*   
* // \=== Messages for GetSearchAnswer \===  
*   
* message SearchRequest {  
*   string user\_id \= 1; // IdP Subject ID (for permission filtering)  
*   string org\_id \= 2;  // Org context  
*   string query \= 3;   // The natural language query  
* }  
*   
* message SearchResponse {  
*   string synthesized\_answer \= 1;  
*   repeated SearchSource sources \= 2;  
* }  
*   
* message SearchSource {  
*   string doc\_id \= 1;    // UUID of the source doc  
*   string title \= 2;     // Title of the source doc  
*   string snippet \= 3;   // A short snippet from the content  
* }  
*   
* // \=== Messages for GetFolderSuggestion \===  
*   
* message SuggestRequest {  
*   string user\_id \= 1;       // IdP Subject ID (for permission filtering)  
*   string org\_id \= 2;        // Org context  
*   string doc\_content \= 3;   // The full text content of the doc to analyze  
*   // The service must filter suggestions based on the user's 'write' access  
* }  
*   
* message SuggestResponse {  
*   repeated FolderSuggestion suggestions \= 1;  
* }  
*   
* message FolderSuggestion {  
*   string space\_id \= 1;  
*   string space\_name \= 2;  
*   string folder\_id \= 3;   // UUID of the suggested folder  
*   string folder\_name \= 4; // Name of the suggested folder  
*   float relevance\_score \= 5; // Confidence score  
* }  
*   
* // \=== Messages for IndexDocument \===  
*   
* message IndexDocumentRequest {  
*   string doc\_id \= 1;  
*   string org\_id \= 2;  
*   string doc\_content \= 3; // The full text content to be chunked and indexed  
*   string doc\_title \= 4;  
* }  
*   
* message IndexDocumentResponse {  
*   bool success \= 1; // True if indexing was successfully queued  
* }

## **6\. Cross-Platform & Offline Sync Design**

* **Core Principle:** The Yjs CRDT model (PRD 1.8) *is* the offline model.  
* **Auth Model:** The client (Web, Desktop, Mobile) is responsible for the OIDC flow. It must securely store the **Refresh Token** (in localStorage for web, native Keychain for Mobile/Desktop). The Access Token (JWT) is short-lived.  
* **Offline Storage (PRD 4.2, 4.3):**  
  1. **Web:** IndexedDB (using y-indexeddb)  
  2. **Desktop (Electron):** SQLite (using y-leveldb or similar)  
  3. **Mobile (RN):** SQLite (using y-sqlite)  
* **Sync Workflow (TDD-minded):**  
  1. **Test Case:** User edits Doc A offline. User B edits Doc A online. User A comes back online.  
  2. **User A (Offline):** Edits are saved *only* to the local Yjs store (IndexedDB).  
  3. **User A (Online):** App status changes to "online."  
  4. **Auth Refresh:** Client uses its stored Refresh Token to get a new, valid Access Token (JWT) from the IdP.  
  5. **Connect:** Client attempts WebSocket connection to Real-time-Service, passing the new JWT.  
  6. **Auth:** Performs WebSocket Auth Handshake (Section 3.3).  
  7. **Merge:** Yjs automatically handles merging the local (offline) CRDT state with the server's CRDT state. Because CRDTs are mathematically conflict-free, this "just works" and guarantees no data loss (NFR 4.2).  
  8. **Propagate:** The server's merged state is then propagated to User B.  
* **Offline Search:** A local, keyword-based search (e.g., MiniSearch.js) will run on the locally synced docs. Full RAG search (FR 1.4) will require an internet connection.

## **7\. TDD & Deployment Strategy (DevOps)**

This section details the philosophy and practical implementation of our testing, build, and deployment pipelines, in accordance with **NFR 5.1 (TDD)** and **NFR 5.2 (CI/CD)**.

### **7.1 Testing Philosophy (TDD)**

Our development process follows a strict "Red-Green-Refactor" TDD cycle.

1. **Red:** Write a failing test that defines a new feature or bug.  
2. **Green:** Write the *minimum* amount of code required to make the failing test pass.  
3. **Refactor:** Clean up the new code to improve its structure, ensuring all tests *still* pass.

This applies to all services. No feature pull request will be approved unless it includes the tests that define it.

### **7.2 The Testing Pyramid**

* **Level 1: Unit Tests (Fast & Isolated)**  
  * **Goal:** Test individual functions/classes in isolation.  
  * **Core-Service (Jest):** Mock dependencies (DB, Cache). Test PermissionsService logic (highest privilege, cache hits, etc.).  
  * **AI-Service (Pytest):** Mock gRPC calls, mock LLMs. Test query builders and pipeline logic.  
  * **Frontend (Vitest):** Mock props and hooks. Test component rendering.  
* **Level 2: Integration Tests (Slower & Connected)**  
  * **Goal:** Test the "seams" between services or a service and its real infrastructure.  
  * **Backend (Testcontainers):** Spin up ephemeral Postgres, Redis, and IdP instances. Test that PermissionsService can *actually* query the DB and cache.  
  * **gRPC Tests:** Test the gRPC contract (protos) between AI-Service and Core-Service.  
* **Level 3: End-to-End (E2E) Tests (Slowest & Real-World)**  
  * **Goal:** Simulate a real user journey from the browser.  
  * **Framework:** **Playwright**.  
  * **Workflow:** CI spins up the *entire application* in a Docker network.  
  * **Example Test:**  
    1. Programmatically log in as User A.  
    2. Create "Doc Foo."  
    3. Log in as User B (who has no perms).  
    4. Assert User B *cannot* see "Doc Foo" in search.  
    5. As User A, share "Doc Foo" with User B.  
    6. As User B, assert "Doc Foo" *is* now in search.

### **7.3 Branching Strategy**

* **GitFlow-lite:**  
  * main: The production branch. Protected.  
  * feature/my-new-feature: All work is done on feature branches.  
  * **PR Process:** A branch must pass all CI checks (lint, test, build) and receive one peer review before merging to main.

### **7.4 Continuous Integration (CI) Pipeline**

* **Tool:** GitHub Actions  
* **Workflow:**  
  1. **Lint & Check:** npm run lint, black . \--check.  
  2. **Unit Tests:** npm test \-- \--coverage.  
  3. **Integration Tests:** docker-compose up \-d postgres redis, npm run test:integration.  
  4. **E2E Tests:** docker-compose up \-d \--build, npx playwright test.  
  5. **Build:** docker build . \-t core-backend:sha-123...

### **7.5 Continuous Deployment (CD) Strategy**

* **Philosophy:** **GitOps**. The main branch is the source of truth.  
* **Tool:** **ArgoCD** (or similar) in Kubernetes.  
* **Environments:**  
  1. **Staging:** ArgoCD monitors the main branch. Auto-deploys on every merge.  
  2. **Production:** ArgoCD monitors a production branch. Deployment is a manual promotion (merge main \-\> production).

## **8\. Glossary**

* **ArgoCD:** A declarative, GitOps continuous delivery tool for Kubernetes.  
* **CI/CD:** Continuous Integration / Continuous Deployment.  
* **CRDT:** Conflict-free Replicated Data Type.  
* **E2E:** End-to-End (testing).  
* **FOSS:** Free and Open-Source Software.  
* **GitOps:** Managing infrastructure and applications where Git is the single source of truth.  
* **IdP:** Identity Provider. A service that manages user identity (e.t., Authentik).  
* **JWT:** JSON Web Token.  
* **NFR:** Non-Functional Requirement.  
* **OIDC:** OpenID Connect. An authentication layer on top of OAuth 2.0.  
* **PRD:** Product Requirements Document.  
* **RAG:** Retrieval-Augmented Generation.  
* **TDD:** Test-Driven Development.  
* **Yjs:** A high-performance CRDT library for real-time collaboration.  
* **pg\_vector:** A PostgreSQL extension for vector similarity search.