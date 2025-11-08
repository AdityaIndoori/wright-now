# WRight Now

[![Lint](https://github.com/AdityaIndoori/wright-now/actions/workflows/lint.yml/badge.svg)](https://github.com/AdityaIndoori/wright-now/actions/workflows/lint.yml)
[![Test](https://github.com/AdityaIndoori/wright-now/actions/workflows/test.yml/badge.svg)](https://github.com/AdityaIndoori/wright-now/actions/workflows/test.yml)
[![Build Docker Images](https://github.com/AdityaIndoori/wright-now/actions/workflows/build.yml/badge.svg)](https://github.com/AdityaIndoori/wright-now/actions/workflows/build.yml)

**All your team's knowledge, instantly searchable. No setup required.**

WRight Now is a fast, simple, and secure SaaS knowledge base platform designed to replace clunky incumbents like Confluence and Notion. Built with 100% FOSS (Free and Open-Source Software) for complete data ownership and zero vendor lock-in.

## ✨ Key Features

- **🚀 AI Command Bar (Cmd+K):** Sub-100ms RAG search using Retrieval-Augmented Generation
- **📝 "No-Blocks" Editor:** Fast, Google Docs-style collaborative editing without block complexity
- **🔒 Zero-Trust Security:** Permissions-first architecture where all data is inaccessible by default
- **🤖 AI-Powered Organization:** Auto-tagging and smart folder suggestions
- **💻 100% FOSS Backend:** Complete data ownership, control, and self-hosting capability
- **🌐 Offline-First:** Work seamlessly across Web, Desktop, and Mobile platforms

## 🏗️ Tech Stack

### Frontend
- **Web:** React with modern hooks and functional components
- **Desktop:** Electron (Windows, macOS, Linux)
- **Mobile:** React Native (iOS & Android)
- **Real-time:** Yjs CRDT for conflict-free document collaboration
- **Offline Storage:** IndexedDB (Web), SQLite (Desktop/Mobile)

### Backend Services
- **Core Backend:** Nest.js (TypeScript) - AuthZ, CRUD, permissions, teams, notifications
- **AI Service:** FastAPI (Python) - RAG search, embeddings, folder suggestions, auto-tagging
- **Real-time Service:** Nest.js WebSocket Gateway + y-websocket
- **API Gateway:** Nest.js - JWT validation, routing, rate limiting

### Data Layer
- **Database:** PostgreSQL with pg_vector extension
- **Cache:** Redis (session management, permission caching)
- **Authentication:** OIDC-based FOSS IdP (Authentik or Keycloak)
- **Communication:** gRPC with Protocol Buffers

### AI/ML Stack
- **Embeddings:** Open-source text vectorization models
- **LLM:** Open-source models (e.g., Llama 3 8B) for RAG synthesis
- **Vector Search:** PostgreSQL pg_vector

### DevOps
- **Containers:** Docker
- **Orchestration:** Kubernetes
- **CI/CD:** GitHub Actions + ArgoCD (GitOps)
- **Testing:** Jest, Pytest, Vitest, Playwright

## 🚀 Quick Start

### Prerequisites
- Node.js 18+ and npm/yarn
- Python 3.11+
- Docker & Docker Compose
- Git

### Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-org/wright-now.git
   cd wright-now
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Start infrastructure services**
   ```bash
   docker-compose up -d
   ```

4. **Run development servers**
   ```bash
   # Terminal 1: Core Backend
   cd services/core-backend
   npm run dev

   # Terminal 2: AI Service
   cd services/ai-service
   python -m uvicorn main:app --reload

   # Terminal 3: Web Client
   cd clients/web
   npm run dev
   ```

5. **Open your browser**
   Navigate to `http://localhost:3000`

## 📖 Documentation

- **[Sprint Plan](ProjectDocs/SprintPlan.md)** - 6-month MVP development roadmap
- **[Technical Design](ProjectDocs/TechnicalDesignDoc.md)** - Architecture and system design
- **[Requirements](ProjectDocs/ProjectRequirementsDoc.md)** - Detailed product requirements
- **[Contributing](CONTRIBUTING.md)** - How to contribute to WRight Now

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for:
- Git workflow and branching strategy
- Commit conventions
- Pull request process
- Code style guidelines
- Testing requirements

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🌟 Project Status

**Current Phase:** Sprint 0 - Foundation & Infrastructure  
**Target:** Production-ready MVP in 6 months (12 sprints)  
**Launch Goal:** Founder's LTD with 1,000+ sales @ $99

## 🔗 Links

- **Website:** Coming soon
- **Documentation:** Coming soon
- **Community:** Coming soon

---

Built with ❤️ by the WRight Now team. Making knowledge management fast, simple, and secure.
