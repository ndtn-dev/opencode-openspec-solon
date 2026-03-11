# Exploration Sources

What the agent reads during Phase 1 (exploration) and why.

---

## Source Priority

Read in this order to build understanding:

### 1. OpenSpec State (highest priority)

| Path | Contains | Why |
|------|----------|-----|
| `openspec/config.yaml` | Project OpenSpec config | Understand project settings, schemas |
| `openspec/specs/` | Current system specifications | Source of truth for what exists |
| `openspec/changes/` | Active proposals in flight | Avoid conflicts, understand in-progress work |
| `openspec/changes/archive/` | Completed past changes | Historical context, past decisions |

### 2. Sisyphus Knowledge

| Path | Contains | Why |
|------|----------|-----|
| `.sisyphus/notepads/*/learnings.md` | Patterns and conventions discovered | Avoid proposing designs that contradict learned patterns |
| `.sisyphus/notepads/*/decisions.md` | Architectural choices and rationales | Understand why things are the way they are |
| `.sisyphus/notepads/*/issues.md` | Blockers and gotchas encountered | Avoid known pitfalls |
| `.sisyphus/notepads/*/problems.md` | Unresolved technical debt | Identify opportunities for improvement |
| `.sisyphus/plans/` | Past and active execution plans | Understand what's been planned/executed |
| `.sisyphus/drafts/` | Prometheus's externalized thinking | Rich context about past planning sessions |

### 3. Project Context

| Path | Contains | Why |
|------|----------|-----|
| `AGENTS.md` | Project agent rules and conventions | Follow established patterns |
| `CLAUDE.md` | Project instructions for AI | Constraints and guidelines |
| `project.md` | High-level vision and scope | Align proposals with project direction |

### 4. Other Planning Artifacts

| Path | Contains | Why |
|------|----------|-----|
| `.claude/plans/*.md` | Claude Code plan files | Past planning work, may be conversion source |
| `PLAN.md` | Standalone plan files | Common convention for project-level plans |
| `docs/plans/`, `docs/rfcs/` | RFCs, ADRs, design docs | Existing design decisions and context |

### 5. Codebase (as needed)

Read actual source files when the proposal touches existing functionality.
Use grep/glob to find relevant code. Don't read the entire codebase --
read what's relevant to the current proposal.

---

## Plan-to-Spec: Reading Source Documents

### Sisyphus Plans

When converting a `.sisyphus/plans/*.md` file, extract:

| Plan Section | Maps To |
|-------------|---------|
| Plan header, context, scenario | `proposal.md` (motivation, scope) |
| Technical decisions, tool specs | `design.md` (technical approach) |
| Task waves, verification steps | `tasks.md` (implementation checklist) |
| Implied requirements, acceptance criteria | `specs/` (delta format: ADDED) |
| Evidence paths, verification waves | `tasks.md` (verification section) |

Also read the plan's associated notepads (if any) for accumulated wisdom
that should inform the spec.

### Claude Code Plans

When converting a `.claude/plans/*.md` or `PLAN.md` file, extract:

| Plan Section | Maps To |
|-------------|---------|
| Goal, context, background | `proposal.md` (motivation, scope) |
| Steps, approach, strategy | `design.md` (technical approach) |
| Numbered steps, checklist items | `tasks.md` (implementation order) |
| Considerations, constraints | `specs/` (requirements as ADDED delta) |
| Trade-offs, alternatives | `design.md` (decision rationale) |

Claude plans tend to be more conversational and less structured than Sisyphus
plans. The agent may need to infer structure from prose.

### Freeform Documents (RFCs, ADRs, PRDs, Notes)

Best-effort extraction. Look for:

| Pattern | Maps To |
|---------|---------|
| "Problem", "Background", "Motivation" headings | `proposal.md` |
| "Decision", "Approach", "Architecture" headings | `design.md` |
| "Requirements", "Must", "Shall", "Acceptance" | `specs/` (ADDED delta) |
| Numbered lists, action items, "TODO" | `tasks.md` |
| "Alternatives", "Rejected", "Trade-offs" | `design.md` |
| Anything else | `{{PLACEHOLDER}}` with note about what's missing |

For documents with no clear structure, the agent should ask the user
what the document represents before attempting conversion.

---

## What NOT to Read

- `.env` files or secrets (never)
- `node_modules/`, `dist/`, build artifacts
- Git history (use git commands if needed, don't read .git/)
- Other users' draft files unless referenced
