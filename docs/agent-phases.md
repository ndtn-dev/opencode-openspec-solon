# Agent Phase Architecture

The five phases of the OpenSpec Planner agent, from intent detection to
artifact finalization.

---

## Overview

```
PHASE 0: Intent Gate
    │
    ├── Trivial ──────── answer directly, done
    ├── Ambiguous ─────── ask one question, reclassify
    │
    ├── Exploratory ───── /opsx:explore ──┐
    ├── Open-ended ────── /opsx:explore ──┤
    │                                      ├── PHASE 1 ── PHASE 2 ─┐
    ├── Explicit ──────── /opsx:propose ──┤                         │
    └── Plan-to-spec ──── /opsx:propose ──┘                         │
                                                                     │
                                              ┌──────────────────────┘
                                              │
                                              ▼
                                        PHASE 3: Gap Analysis (optional)
                                              │
                                              ▼
                                        PHASE 4: Assumption Summary
                                              │
                                              ▼
                                        PHASE 5: Finalize
```

---

## Phase 0: Intent Gate

**Purpose**: Classify user intent and auto-trigger the appropriate skill.

**Behavior**:
1. Read the user's message
2. Classify: trivial / exploratory / explicit / plan-to-spec / open-ended / ambiguous
3. Verbalize intent naturally (no classification labels)
4. Auto-trigger /opsx:explore or /opsx:propose as appropriate
5. For trivial: just answer
6. For ambiguous: ask one clarifying question

**Verbalization examples**:
- "This sounds like you're exploring [topic] -- let me dig into the current state."
- "You want a full proposal for [feature]. Let me check a few things first."
- "I see you have a Sisyphus plan for [name]. I can convert this to OpenSpec format."

See [intent-skill-mapping.md](intent-skill-mapping.md) for full mapping.

---

## Phase 1: Exploration

**Purpose**: Understand current system state before brainstorming or generating.

**Sources to read**:

| Source | What it tells the agent |
|--------|------------------------|
| `openspec/specs/` | Current system state (source of truth) |
| `openspec/changes/` | Active proposals in flight |
| `openspec/config.yaml` | Project OpenSpec configuration |
| `.sisyphus/plans/` | Past/active execution plans |
| `.sisyphus/notepads/` | Accumulated learnings, decisions, issues |
| `.sisyphus/drafts/` | Prometheus's externalized knowledge |
| `AGENTS.md` / `CLAUDE.md` | Project rules and conventions |
| Codebase (grep/read) | Actual implementation state |

**For plan-to-spec intent**: Read the referenced `.sisyphus/plans/*.md` file
and extract scope, tasks, decisions, technical approach.

**For exploratory/open-ended**: Read broadly. Look for gaps in specs, known
issues in notepads, incomplete changes.

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
a checklist. If scope isn't clear, it asks about scope. If the approach
hasn't been discussed, it raises options.

### Assumption Tracking

Three tiers running simultaneously during artifact creation:

| Tier | Decision Size | Behavior | Example |
|------|--------------|----------|---------|
| Small | < 5 min to fix if wrong | Assume, track, keep moving | Spec file naming |
| Medium | Doesn't block other sections | `{{PLACEHOLDER}}` with suggestion | Retention period |
| Big | Changes overall direction | Stop, explain trade-offs, wait | New service vs extend existing |

See [assumption-tracking.md](assumption-tracking.md) for full system.

### Artifact Formation

Artifacts begin forming during conversation, not after:

```
Turn 1: User describes feature
Turn 2: Agent explores, asks about scope -> starts proposal.md skeleton
Turn 3: User clarifies scope -> agent fills proposal.md, starts design.md
Turn 4: Agent raises a big decision -> waits
Turn 5: User decides -> agent continues design.md, starts specs/
Turn 6: Agent shares current state: "Here's where we are so far..."
...
```

The user sees the spec taking shape and can redirect at any point.

### Holistic Thinking

During brainstorming, the agent should actively consider:
- **Second-order effects**: "If we add this service, it needs a Traefik route,
  DNS entry, and possibly Authentik protection. Should I include those?"
- **Architectural coherence**: "This overlaps with what zerobyte already does.
  Should we extend zerobyte or build separate?"
- **Existing decisions**: "The notepads show we tried X before and hit Y problem.
  Should we take a different approach?"

---

## Phase 3: Gap Analysis (Optional)

**Purpose**: Review near-complete artifacts for blind spots before finalizing.

**Trigger**: Agent prompts "Want me to run gap analysis before finalizing?"

### If @metis is available (OmO installed):
- Delegate with: tracked assumptions, placeholders, draft artifacts, original request
- Metis returns gaps categorized as blocking/warning/note
- Results surfaced to user

### If @metis is not available:
- Self-review checklist:
  - Structural completeness (all 4 artifact types present)
  - Scope discipline (no scope creep)
  - Assumption audit (no Tier 3 decisions silently assumed)
  - Coherence check (no conflicts with existing specs)
  - Edge cases (failure modes, rollback strategy)

See [gap-analysis.md](gap-analysis.md) for full system.

---

## Phase 4: Assumption Summary

**Purpose**: Surface all decisions made during brainstorming for user confirmation.

**Presented as a structured summary**:

```markdown
## Assumptions I Made
1. [small assumption] -- [reasoning]
2. [small assumption] -- [reasoning]

## Placeholders Remaining
1. {{NAME}} in [file] -- [suggestion]
2. {{NAME}} in [file] -- [suggestion]

## Gap Analysis Findings (if run)
- [blocking] ...
- [warning] ...
- [note] ...

Want me to adjust anything, or are we good to finalize?
```

User can:
- Confirm all at once
- Override specific assumptions
- Fill placeholders
- Request changes
- Go back to brainstorming on specific sections

---

## Phase 5: Finalize

**Purpose**: Lock artifacts and communicate handoff.

**Steps**:
1. Fill all remaining placeholders with confirmed values
2. Apply any assumption overrides
3. Address gap analysis findings (resolve blocking items)
4. Write final versions of all artifacts
5. Communicate handoff:

```
"Specs are locked in openspec/changes/[name]/. To implement:
- Switch to Sisyphus and run /opsx:apply
- Or use Prometheus for a detailed execution plan first (/start-work)
- Prometheus will run its own Metis review before code is written."
```

**The agent does NOT implement.** It does not write code, run commands, or
start the build process. It hands off cleanly.

---

## Phase Transitions

Phases are not strictly linear. The agent can:

- **Loop within Phase 2**: Brainstorm for as long as needed
- **Return from Phase 4 to Phase 2**: User wants to rethink a section
- **Skip Phase 3**: User doesn't want gap analysis
- **Pause anywhere**: User can come back later, artifacts persist

The only hard rule: Phase 5 (finalize) requires Phase 4 (assumption summary)
to have run at least once. Never finalize without surfacing assumptions.
