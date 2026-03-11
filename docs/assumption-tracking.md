# Assumption Tracking System

Three-tier system for handling decisions during brainstorm/artifact creation.
Core principle: keep momentum while maintaining accountability for every assumption.

---

## The Problem

AI planners have two failure modes:

1. **Ask too much**: Every small decision becomes a question. User gets 20 prompts
   before seeing any artifact. Feels like an interrogation, not a brainstorm.
2. **Ask too little**: AI makes silent assumptions, generates a monolith plan,
   user discovers the assumptions were wrong after reading 200 lines.

The assumption tracking system solves both by categorizing decisions by impact
and handling each tier differently.

---

## Three Tiers

### Tier 1: Small Assumptions (assume + track + keep moving)

Decisions where the cost of being wrong is low and the most likely answer is obvious.

**Examples**:
- Markdown table format vs bullet lists for a spec section
- Naming convention for a new spec file
- Order of sections in a document
- Which existing spec to reference for context

**Behavior**:
- Make the assumption silently
- Track it in an internal assumptions list
- Keep building artifacts
- Surface all small assumptions in Phase 4 (summary) for batch confirmation

**Why this works**: If you're wrong about table vs bullet format, it's a 30-second
fix. Stopping to ask would break flow for zero value.

---

### Tier 2: Medium Decisions (write artifact with {{PLACEHOLDER}} + keep moving)

Decisions where the agent can continue building the surrounding structure but
needs user input for a specific detail.

**Examples**:
- Retention policy duration (7 days? 30 days?)
- Specific tool choice (rsync vs rclone vs restic)
- Port numbers or domain names for a new service
- Which node a service should run on
- Specific acceptance criteria thresholds

**Behavior**:
- Write the artifact section with a `{{PLACEHOLDER}}` marker
- Continue building other sections that don't depend on this decision
- Placeholders are visible in the artifacts as they form
- User can fill them anytime, or they're collected in Phase 4

**Placeholder format**:
```markdown
## Backup Schedule

Backups run {{BACKUP_SCHEDULE: daily at 3am UTC? weekly? user to decide}}
with a retention period of {{RETENTION_PERIOD: suggest 30 days for DB,
7 days for logs}}.
```

The placeholder includes the agent's suggestion/context so the user has
something to react to rather than a blank field.

**Why this works**: The user sees the shape of the proposal forming. They can
course-correct on specifics without waiting for the whole thing. Placeholders
with suggestions are easier to confirm than open-ended questions.

---

### Tier 3: Big Decisions (stop + ask + wait)

Decisions that change the direction of the entire proposal. Getting these wrong
means throwing away work.

**Examples**:
- "Should this be a new service or integrated into an existing one?"
- "Is this VPN-only or should it be externally accessible?"
- "Do we want this to replace the existing system or run alongside it?"
- "This conflicts with the existing spec for X. Which takes priority?"
- Anything that affects more than one spec/service boundary

**Behavior**:
- Stop artifact generation
- Explain the decision clearly with trade-offs for each option
- Wait for user response before continuing
- This is the only tier that blocks progress

**Why this works**: Architectural direction questions have cascading effects.
A wrong assumption here means rewriting everything, not tweaking a field.

---

## Decision Classification Guide

For the agent's prompt, the classification heuristic:

```
Is the cost of being wrong < 5 minutes to fix?
  YES -> Tier 1 (assume + track)
  NO  -> Does the rest of the artifact still make sense without this?
           YES -> Tier 2 (placeholder + continue)
           NO  -> Tier 3 (stop + ask)
```

Alternative framing:
```
Does this affect ONE section of ONE artifact? -> Tier 1 or 2
Does this affect MULTIPLE artifacts or the overall approach? -> Tier 3
```

---

## Phase 4: Assumption Summary

Before finalizing artifacts, the agent presents a structured summary:

```markdown
## Assumptions I Made

1. Using rsync over SSH for file transfer (not rclone) -- lightweight, no extra deps
2. Spec organized as specs/backup/spec.md -- follows existing convention
3. Referencing zerobyte specs for backup context

## Placeholders Remaining

1. {{BACKUP_SCHEDULE}} in design.md -- suggested daily at 3am UTC
2. {{RETENTION_PERIOD}} in design.md -- suggested 30 days DB, 7 days logs
3. {{ALERT_CHANNEL}} in tasks.md -- ntfy? email? both?

## [Gap Analysis Results, if run]

Want me to adjust any assumptions or fill the placeholders?
```

The user can:
- Confirm all at once ("looks good")
- Override specific assumptions ("use restic, not rsync")
- Fill placeholders ("30 days retention, ntfy for alerts")
- Request changes ("actually, make the schedule configurable")

---

## Interaction with Metis

If the user opts for gap analysis (Phase 3), the assumption list and
placeholders are handed to Metis as input:

```
Review this proposal. Here are assumptions the planner made:
[assumption list]
Here are unresolved placeholders:
[placeholder list]
Check for: hidden intentions, over-engineering, missing criteria,
scope creep, edge cases.
```

Metis may flag assumptions that should have been Tier 3 (big decisions),
or identify gaps in the placeholder suggestions. These findings get
surfaced to the user alongside the assumption summary.
