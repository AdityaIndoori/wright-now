# WRightNow Sprint Plan - Development Guide

This rule provides guidance for working through the 6-month MVP sprint plan systematically using OpenSpec workflow.

## Sprint Plan Overview

- **Duration:** 12 sprints × 2 weeks (6 months total)
- **Goal:** Production-ready MVP with Founder's LTD launch
- **Workflow:** PLAN MODE (proposals) → ACT MODE (implementation) → Archive

## Working with Sprint Tasks

### 1. Sprint Progression Rules

- **Always start with Sprint 0** unless explicitly directed to a different sprint
- **Complete sprints sequentially** - do not skip ahead without user approval
- **Reference `ProjectDocs/SprintPlan.md`** for task lists and OpenSpec prompts
- **Track which sprint is currently active** in conversation context

### 2. Using OpenSpec Proposal Prompts

When the user references a task from the sprint plan:

1. **Locate the exact OpenSpec Proposal Prompt** from the sprint table
2. **Use that prompt verbatim** to create the proposal (don't paraphrase)
3. **Wait for user approval** before proceeding to implementation
4. **Example workflow:**
   ```
   User: "Let's start Sprint 0, Task 1.1"
   You: [Read SprintPlan.md, find task 1.1, use exact prompt]
        "Create a proposal to add GitHub repository setup with GitFlow-lite branching and protection rules"
   ```

### 3. Mode-Specific Behaviors

#### PLAN MODE (Creating Proposals)
- Use OpenSpec Proposal Prompts from the sprint plan tables
- Read `openspec/project.md` for context before creating proposals
- Create proposals with `proposal.md`, `tasks.md`, and `design.md` (when needed)
- Write spec deltas under `specs/` subdirectories
- Always validate with `openspec validate <id> --strict`
- Present proposals for user review before toggling to ACT MODE

#### ACT MODE (Implementation)
- Read the approved proposal files before implementing
- Implement tasks sequentially using TDD approach
- Track progress with TODO lists in `task_progress`
- Update `tasks.md` checklist as tasks complete
- Run tests after each significant change
- Validate against NFRs (Non-Functional Requirements)

#### ARCHIVE MODE (Post-Deployment)
- Run `openspec archive <change-id> --yes` after deployment
- Confirm specs were updated correctly
- Validate with `openspec validate --strict`

### 4. Critical Performance Requirements (NFRs)

Always validate implementations against these metrics:

| Requirement | Target | Sprint | Validation |
|------------|--------|--------|------------|
| Permission checks | p99 <10ms | Sprint 2 | Load testing |
| API responses | p95 <200ms | All | Performance monitoring |
| Cmd+K modal open | <100ms | Sprint 6 | E2E testing |
| Test coverage | >80% | All | Coverage reports |
| System uptime | 99.9% | Sprint 12 | Production monitoring |

### 5. Testing Standards

For every implementation:

- **TDD approach:** Write tests before implementation
- **Unit tests:** Required for all business logic
- **Integration tests:** Required for API endpoints
- **E2E tests:** Required for critical user flows
- **Test coverage:** Maintain >80% coverage
- **Tools:** Jest (TypeScript), Pytest (Python), Vitest (Frontend)

### 6. Sprint-Specific Guidance

#### Sprint 0 (Foundation)
- **Focus:** Infrastructure must be rock-solid
- **Critical:** DevOps pipeline, Docker Compose, Kubernetes staging
- **Deliverable:** All services start and communicate

#### Sprint 2 (Authentication & Authorization)
- **High Risk:** OIDC integration complexity
- **Critical:** PermissionsService must meet NFR 2.1 (p99 <10ms)
- **Mitigation:** Use Testcontainers for integration tests
- **Deliverable:** Zero-trust authorization working

#### Sprint 4 (Real-Time Editor)
- **High Risk:** Yjs CRDT synchronization
- **Recommendation:** Consider spike in Sprint 0 to prototype
- **Critical:** Offline support with IndexedDB
- **Testing:** Multi-user collaboration E2E tests

#### Sprint 6 (RAG Search)
- **Critical:** #1 differentiator feature
- **Must meet:** NFR 2.2 (p95 <200ms) and NFR 2.3 (<100ms modal open)
- **Focus:** Permission-filtered vector search
- **Testing:** Load test with 10k+ documents

#### Sprint 11 (Desktop & Mobile)
- **High Risk:** React Native complexity
- **Contingency:** Can be cut if behind schedule
- **Recommendation:** Start planning in Sprint 8
- **Testing:** Platform-specific E2E tests

#### Sprint 12 (Polish & Launch)
- **Focus:** Production readiness, not new features
- **Critical:** Security audit, performance optimization
- **Deliverable:** Production-ready MVP

### 7. Dependencies & Critical Path

Always respect these dependencies:

```
Sprint 0 → Sprint 1 → Sprint 2 → Sprint 3 → Sprint 4
                   ↓           ↘
                Sprint 5 → Sprint 6 → Sprint 7 → Sprint 8 → Sprint 9 → Sprint 10 → Sprint 11 → Sprint 12
```

**Cannot proceed to:**
- Sprint 3 without completing Sprint 2 (auth required)
- Sprint 6 without completing Sprint 4 & 5 (editor + AI foundation)
- Sprint 11 without completing Sprint 10 (all core features)

### 8. Task Progress Tracking

When implementing sprint tasks:

- **Create TODO list** at start of each sprint
- **Use task_progress parameter** in tool calls
- **Update checklist** as tasks complete
- **Example format:**
  ```
  - [x] Sprint 2 - Task 1.1: OIDC client setup
  - [x] Sprint 2 - Task 1.2: JWT validation
  - [ ] Sprint 2 - Task 1.3: Token refresh flow
  - [ ] Sprint 2 - Task 1.4: Logout endpoint
  ```

### 9. Risk Mitigation

When implementing high-risk sprints:

| Sprint | Risk | Required Mitigation |
|--------|------|---------------------|
| Sprint 2 | Auth complexity | Prototype OIDC early, use Testcontainers |
| Sprint 4 | Yjs sync issues | Spike in Sprint 0, thorough E2E testing |
| Sprint 6 | LLM latency | Load test early, monitor p95 latency |
| Sprint 11 | React Native | Start planning Sprint 8, web-first approach |

### 10. When to Ask Questions

**DO ask follow-up questions when:**
- User wants to skip sprints (confirm dependencies met)
- User requests changes to critical path
- Implementation deviates from NFRs
- Testing requirements unclear

**DON'T ask questions when:**
- OpenSpec Proposal Prompt is provided in sprint plan
- Task is clearly defined in sprint table
- Standard patterns apply (TDD, SOLID principles)

### 11. Architecture Patterns

Follow these patterns consistently:

- **Backend:** SOLID principles, repository pattern, DI via Nest.js
- **Frontend:** Component composition, hooks, context for global state
- **Testing:** TDD, Arrange-Act-Assert, test doubles for external services
- **Data Access:** Prisma ORM with repository pattern
- **Authorization:** Zero-trust, permission checks at every endpoint
- **Real-time:** Yjs CRDT for collaborative editing
- **AI:** RAG pipeline with pg_vector for semantic search

### 12. Documentation Standards

For each sprint:

- **Create ADRs** for architectural decisions (in `/docs/adr`)
- **Update API docs** with OpenAPI/Swagger
- **Write inline code comments** for complex logic
- **Update `README.md`** with new features
- **Maintain `CHANGELOG.md`** with sprint deliverables

### 13. Quick Reference Commands

Common OpenSpec commands during sprint work:

```bash
# List all changes
openspec list

# Show specific change
openspec show <change-id>

# Validate change
openspec validate <change-id> --strict

# Archive completed change
openspec archive <change-id> --yes

# List all specs
openspec list --specs
```

### 14. Sprint Completion Checklist

Before marking a sprint complete, verify:

- [ ] All tasks from sprint table completed
- [ ] OpenSpec proposals archived
- [ ] Tests passing (>80% coverage)
- [ ] NFRs validated (if applicable)
- [ ] CI/CD pipeline green
- [ ] Deployed to staging
- [ ] Sprint deliverable demonstrated
- [ ] Documentation updated

### 15. Contingency Planning

**If behind schedule:**
- Cut Sprint 11 (mobile) - launch web/desktop only
- Extend sprint duration with user approval
- Parallelize independent tasks

**If ahead of schedule:**
- Add V1.1 features (Slack integration, Graph view)
- Polish and optimization
- Advanced testing

**If performance issues:**
- Dedicate Sprint 11 to optimization
- Profile and identify bottlenecks
- Consider architectural changes

## Getting Started

To begin working with the sprint plan:

1. **Confirm current sprint** with user
2. **Review sprint goals** in `ProjectDocs/SprintPlan.md`
3. **Read first task** from sprint table
4. **Use exact OpenSpec Proposal Prompt** from table
5. **Create proposal** in PLAN MODE
6. **Wait for approval** before implementing
7. **Toggle to ACT MODE** and implement
8. **Archive** after deployment

## Success Metrics

Track these throughout development:

**Technical:**
- ✅ Permission checks: p99 <10ms
- ✅ API responses: p95 <200ms
- ✅ Cmd+K modal: <100ms open time
- ✅ Test coverage: >80%
- ✅ System uptime: 99.9%

**Business:**
- 🎯 Founder's LTD: 1,000+ sales @ $99
- 🎯 AppSumo launch: 5,000+ users
- 🎯 User satisfaction: 4.5+ stars
- 🎯 Self-hosting: 100+ GitHub stars

---

**Remember:** This is a 6-month journey to production. Focus on delivering value incrementally, maintaining quality, and following the OpenSpec workflow systematically.
