# Agent Phase Architecture

Eight phases of the Solon agent, from intent detection to verification.

---

## Overview

```
PHASE 0: Intent Gate
    │
    ├── Trivial ──────── answer directly, done
    ├── Ambiguous ─────── ask one question, reclassify
    │
    ├── Exploratory ───── solon-spec ──┐
    ├── Open-ended ────── solon-spec ──┤
    │                                   ├── PHASE 1 ── PHASE 2 ◄──┐
    ├── Explicit ──────── solon-spec ──┤                    │      │
    ├── Plan-to-spec ──── solon-spec ──┘                    │      │
    ├── Reconcile ─────── solon-reconcile ── PHASE 2 ───────┤      │
    ├── Init ──────────── solon-init                        │      │
    └── Handoff ────────── solon-handoff                    │      │
                                                            ▼      │
                                              PHASE 3: Gap Analysis (mandatory)
                                                            │      │
                                                     (soft ratchet loop)
                                                            │      │
                                                            ▼      │
                                              PHASE 4: Assumption Summary
                                                            │ (user can return to P2)
                                                            ▼
                                              PHASE 5: Ingress Checkpoint
                                                            │
                                                            ▼
                                              PHASE 6: Write Artifacts (LOCKED)
                                                            │
                                                            ▼
                                              PHASE 7: Verify + Nudge to Handoff
```

---

## Phase 0: Intent Gate

**Purpose**: Classify user intent and route to the appropriate skill or sub-agent.

**Behavior**:
1. Read the user's message
2. Classify: trivial / exploratory / explicit / plan-to-spec / reconcile / init / handoff / open-ended / ambiguous
3. Verbalize intent naturally (no classification labels)
4. Route to the appropriate skill
5. For trivial: just answer
6. For ambiguous: ask one clarifying question

**Ordering**: Evaluate concrete intents first (Reconcile, Init, Handoff, Plan-to-spec) before falling back to broader categories.

**Auto-verify**: On every activation, dispatch a background ledger status check before routing.

See [intent-skill-mapping.md](intent-skill-mapping.md) for full mapping.

---

## Phase 1: Exploration

**Purpose**: Understand current system state before brainstorming or generating.

**Sources to read** (in priority order):

| Source | What it tells the agent |
|--------|------------------------|
| `openspec/specs/` | Current system state (source of truth) |
| `openspec/changes/` | Active proposals in flight |
| `.sisyphus/notepads/` | Accumulated learnings, decisions, issues |
| `.sisyphus/plans/`, `.claude/plans/` | Past/active execution plans |
| `AGENTS.md` / `CLAUDE.md` | Project rules and conventions |
| `docs/rfcs/`, `docs/plans/` | Other planning artifacts |
| Codebase (grep/read) | Actual implementation state |

**Auto-detect**: If `openspec/` doesn't exist, redirect to Init flow before continuing.

**Decision tracking housekeeping**: Run a lightweight ledger status check for pending/verified counts.

**Principle**: Read before speaking. The agent should never propose something
that contradicts existing specs or repeats a known issue from notepads.

---

## Phase 2: Brainstorm + Incremental Artifacts

**Purpose**: Collaboratively develop the spec through conversation, forming
artifacts incrementally rather than in a monolith.

### Clearance Check (Internal Compass)

The 5 criteria are used as a guide for conversation, not a blocking gate:

1. **Core objective** -- Is the goal clear with success criteria?
2. **Scope boundaries** -- What's IN and what's OUT?
3. **Ambiguities** -- Any critical unknowns?
4. **Technical approach** -- Has the strategy been discussed?
5. **Test strategy** -- How will we verify this works?

The agent weaves these into natural conversation. It doesn't present them as
a checklist.

### Assumption Tracking

Three tiers running simultaneously during artifact creation:

| Tier | Decision Size | Behavior | Example |
|------|--------------|----------|---------|
| Small | < 5 min to fix if wrong | Assume, track, keep moving | Spec file naming |
| Medium | Doesn't block other sections | `{{PLACEHOLDER}}` with suggestion | Retention period |
| Big | Changes overall direction | Stop, explain trade-offs, wait | New service vs extend existing |

See [assumption-tracking.md](assumption-tracking.md) for full system.

### Decision Tracking

Every decision is tracked with phase/tier/status metadata via the graphiti ledger.
Big decisions get **micro-ingressed** immediately (ledger insert + `add_memory`).
Small and Medium are queued for batch ingestion in Phase 5.

### Reconcile Mode (Phase 2 variant)

When entering from reconcile intent, brainstorm takes the form of a structured
diff: enumerate deviations between spec and implementation, classify each by tier,
micro-ingest Big deviations immediately, queue the rest for Phase 4 confirmation.

### Holistic Thinking

During brainstorming, the agent should actively consider:
- **Second-order effects**: "If we add this service, what else does it imply?"
- **Architectural coherence**: "This overlaps with what already exists. Extend or build separate?"
- **Existing decisions**: "The notepads show we tried X before and hit Y. Different approach?"

---

## Phase 3: Gap Analysis (Mandatory)

**Purpose**: Review near-complete artifacts for blind spots before proceeding.

This phase always runs and is never skipped.

### Execution
1. Attempt delegation to a fresh-eyes review agent first
2. If unavailable, silently fall back to self-review

### Self-review checklist
- Structural completeness (all artifact types present, acceptance criteria, task mapping)
- Scope discipline (no scope creep, no unnecessary abstractions)
- Assumption audit (no Tier 3 decisions silently assumed)
- Coherence check (no conflicts with existing specs, naming conventions match)
- Edge cases (failure modes, rollback strategy, dependencies)

Results categorized as: `blocking` / `warning` / `note`.

### Soft Ratchet Loop Guard

If the same gap appears in 2 consecutive Phase 2↔3 cycles, escalate to user
with a specific resolution recommendation.

See [gap-analysis.md](gap-analysis.md) for full system.

---

## Phase 4: Assumption Summary

**Purpose**: Surface all decisions made during brainstorming for user confirmation.

**Presented as a structured summary**:
- Confirmed assumptions with reasoning
- Remaining placeholders with suggestions
- Phase 3 findings (blocking / warning / note)
- Candidate overrides that supersede prior decisions

User can:
- Confirm all at once
- Override specific assumptions
- Fill placeholders
- Request targeted return to Phase 2

Phase 5 cannot run until this summary state is explicit.

---

## Phase 5: Ingress Checkpoint

**Purpose**: Persist decisions and verify tracking integrity before writing artifacts.

**Steps**:
1. Verify Phase 2 ledger records for the current session
2. Batch-record confirmed Small/Medium decisions (first-time ingestion)
3. Dispatch ingress agent for graph ingestion via `add_memory`
   - Big decisions: skip (already ingested in Phase 2 micro-ingress)
   - Medium/Small: ingested for first time here
4. Write checkpoint file to `.solon/checkpoints/{spec-name}-phase5.json`

The checkpoint file is the structural gate for Phase 6.

---

## Phase 6: Write Artifacts (LOCKED)

**Purpose**: Generate final spec artifacts. Locked once writing begins.

**Pre-write gate** (hard stop):
1. Phase 5 checkpoint file must exist
2. Session episode count must be non-zero (or fallback JSON count)
3. If both checks fail, stop and report checkpoint failure

**Write sequence**:
1. Fill placeholders with confirmed values
2. Apply approved overrides
3. Resolve blocking Phase 3 gaps
4. Write to `openspec/changes/[name]/`
5. Ensure artifacts match tracked decision history

**Locked-state rule**: No return to brainstorm while write is active.
If interrupted, finish current write unit, then loop back to Phase 2.

---

## Phase 7: Verify and Nudge

**Purpose**: Final verification and handoff prompt.

**Steps**:
1. Dispatch background ledger status pass (drain, verify, report)
2. Immediately nudge toward handoff (don't wait for verify):
   "Specs are locked. Want me to generate a handoff document for implementation?"
3. If background verify completes during session, surface summary as context

---

## Phase Transitions

Phases are not strictly linear. The agent can:

- **Loop within Phase 2**: Brainstorm for as long as needed
- **Loop between Phase 2 and 3**: Soft ratchet catches repeated gaps
- **Return from Phase 4 to Phase 2**: User wants to rethink a section
- **Pause anywhere**: User can come back later, artifacts persist

Hard rules:
- Phase 3 is mandatory (never skipped)
- Phase 5 requires Phase 4 to have run
- Phase 6 requires Phase 5 checkpoint
- Phase 6 is locked once writing begins
- Phase 7 runs after Phase 6
