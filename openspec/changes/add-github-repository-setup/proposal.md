# Change: GitHub Repository Setup with GitFlow-lite

## Why
WRight Now is a greenfield project starting Sprint 0. We need foundational repository infrastructure with branch protection, collaboration workflows, and commit conventions to ensure code quality and enable the CI/CD pipeline (Task 1.2) and subsequent development sprints.

## What Changes
- Initialize GitHub repository with monorepo structure
- Implement GitFlow-lite branching strategy (main + feature/* + hotfix/*)
- Configure branch protection rules for main (PR required, CI checks, review approval)
- Add foundational project files (README, CONTRIBUTING, LICENSE)
- Establish conventional commits format for consistency

## Impact
- **Affected capabilities:** Repository Management (new capability)
- **Affected code:** Root-level repository files, .github/ directory
- **Dependencies:** None (this is the foundation)
- **Enables:** All subsequent Sprint 0 tasks (CI/CD, service scaffolding)
