# Contributing to WRight Now

Thank you for your interest in contributing to WRight Now! This document provides guidelines and workflows for contributing to the project.

## 🌳 Git Workflow (GitFlow-lite)

We use a simplified GitFlow strategy for branch management.

### Branch Structure

- **`main`** - Production-ready code (protected)
- **`feature/*`** - All development work
- **`hotfix/*`** - Critical production fixes

### Branch Protection Rules

The `main` branch is protected with the following rules:
- ✅ Pull request required before merging
- ✅ At least 1 approval review required
- ✅ All CI checks must pass (linting, tests, build)
- ✅ Squash merge strategy enforced (linear history)
- ❌ No direct commits allowed

## 🔄 Development Workflow

### 1. Starting New Work

```bash
# Ensure you're on main and up to date
git checkout main
git pull origin main

# Create a feature branch
git checkout -b feature/your-feature-name

# Or for a hotfix
git checkout -b hotfix/issue-description
```

### 2. Making Changes

Follow Test-Driven Development (TDD):

```bash
# Red: Write failing tests first
npm test

# Green: Write minimal code to pass tests
# Implement your feature

# Refactor: Clean up code while keeping tests green
npm test
```

### 3. Committing Changes

We use **Conventional Commits** format:

```
type(scope): description

[optional body]

[optional footer]
```

#### Types
- **feat:** New feature
- **fix:** Bug fix
- **docs:** Documentation changes
- **style:** Code style changes (formatting, no logic change)
- **refactor:** Code refactoring (no behavior change)
- **test:** Adding or updating tests
- **chore:** Build process, tooling, dependencies

#### Examples

```bash
git commit -m "feat(editor): add real-time cursor synchronization"
git commit -m "fix(permissions): resolve team permission inheritance bug"
git commit -m "docs(readme): update quick start instructions"
git commit -m "test(auth): add integration tests for OIDC flow"
```

### 4. Pushing Changes

```bash
# Push your feature branch
git push origin feature/your-feature-name
```

### 5. Creating a Pull Request

1. Go to GitHub and create a PR from your feature branch to `main`
2. Fill out the PR template:
   - **Title:** Use conventional commit format
   - **Description:** Explain what and why
   - **Testing:** Describe how you tested
   - **Screenshots:** If UI changes

3. Ensure all CI checks pass:
   - ✅ Linting (ESLint/Black)
   - ✅ Unit tests with coverage (>80%)
   - ✅ Integration tests
   - ✅ Build validation

4. Request review from at least 1 team member

### 6. Review Process

**As an Author:**
- Address all review comments
- Update code based on feedback
- Re-request review when ready

**As a Reviewer:**
- Review code for correctness, clarity, and best practices
- Test changes locally if needed
- Approve when satisfied

### 7. Merging

Once approved and all checks pass:
- Use **Squash and Merge** (enforced by branch protection)
- Ensure commit message follows conventional format
- Delete feature branch after merge

## 🧪 Testing Requirements

All code changes must include tests:

### Unit Tests
- **Backend (Jest):** Test business logic in isolation
- **AI Service (Pytest):** Test AI operations with mocked dependencies
- **Frontend (Vitest):** Test components and hooks

```bash
# Run unit tests
npm test                    # Backend/Frontend
pytest                      # AI Service
```

### Integration Tests
- Use Testcontainers for real database/cache testing
- Test gRPC contracts between services
- Validate API endpoints end-to-end

```bash
# Run integration tests
npm run test:integration
```

### E2E Tests
- Use Playwright for full user journey testing
- Test critical paths (create doc, share, search)

```bash
# Run E2E tests
npm run test:e2e
```

### Coverage Requirements
- Minimum 80% code coverage for all services
- Coverage reports generated in CI

## 📝 Code Style

### TypeScript/JavaScript (Nest.js, React)

**Principles:**
- SOLID design principles
- Dependency Injection
- Functional programming patterns where appropriate

**Naming:**
- Classes: `PascalCase` (e.g., `PermissionsService`)
- Functions/Variables: `camelCase` (e.g., `getUserPermissions`)
- Constants: `UPPER_SNAKE_CASE` (e.g., `MAX_CACHE_TTL`)
- Interfaces: `PascalCase` with `I` prefix (e.g., `IPermissionCheck`)

**Imports:**
- Use absolute imports with path aliases: `@/services/...`
- Group imports: external → internal → types

**Formatting:**
- ESLint with strict configuration
- Prettier for auto-formatting
- Max line length: 100 characters

```bash
# Lint and format
npm run lint
npm run format
```

### Python (FastAPI AI Service)

**Style:**
- Black formatter (strict)
- Pylint for linting
- Type hints required for all function signatures

**Naming:**
- Classes: `PascalCase`
- Functions/Variables: `snake_case`
- Constants: `UPPER_SNAKE_CASE`

```bash
# Format and lint
black .
pylint src/
```

## 🏗️ Architecture Patterns

### Backend Services
- **Repository Pattern:** Data access layer abstraction
- **Dependency Injection:** Use Nest.js DI container
- **Zero-Trust Authorization:** Permission checks at every endpoint

### Frontend
- **Component Composition:** Break down into small, reusable components
- **Hooks:** Use React hooks for state and side effects
- **Context:** Global state management

### Testing
- **TDD:** Test-Driven Development (Red → Green → Refactor)
- **Arrange-Act-Assert:** Structured test format
- **Test Doubles:** Mocks/Stubs for external dependencies

## 🚫 What NOT to Do

- ❌ Don't commit directly to `main`
- ❌ Don't push code without tests
- ❌ Don't ignore linting errors
- ❌ Don't merge your own PRs without review
- ❌ Don't use `any` type in TypeScript
- ❌ Don't leave commented-out code
- ❌ Don't commit secrets or credentials

## 🐛 Bug Fixes

For bugs that restore intended behavior (not new features):

1. Create a `fix/*` branch
2. Add regression test that fails
3. Fix the bug
4. Verify test passes
5. Create PR with `fix:` commit

## 🔥 Hotfixes

For critical production issues:

1. Create `hotfix/*` branch from `main`
2. Implement minimal fix
3. Add test to prevent regression
4. Create PR with expedited review
5. Merge to `main` immediately after approval

## 📚 Documentation

Update documentation for:
- New features or APIs
- Configuration changes
- Breaking changes
- Migration guides

Documentation locations:
- **Inline:** Code comments for complex logic
- **README.md:** Project overview and quick start
- **API Docs:** OpenAPI/Swagger specs
- **ADRs:** `docs/adr/` for architectural decisions

## 🤝 Code Review Guidelines

### For Authors
- Keep PRs focused and small (<500 lines)
- Write clear PR descriptions
- Respond to feedback promptly
- Don't take feedback personally

### For Reviewers
- Be constructive and respectful
- Focus on code, not the person
- Suggest improvements, don't demand
- Approve when code meets standards

## 🎯 Best Practices

1. **Simplicity First:** Default to simple solutions, add complexity only when needed
2. **Test Everything:** Every feature must have tests
3. **Document Decisions:** Use ADRs for significant architectural choices
4. **Performance Matters:** Monitor and optimize hot paths
5. **Security Always:** Zero-trust, explicit permissions, input validation

## 📞 Getting Help

- **Questions:** Open a discussion on GitHub
- **Bugs:** Report via GitHub Issues
- **Chat:** Join our community (coming soon)

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for making WRight Now better! 🚀
