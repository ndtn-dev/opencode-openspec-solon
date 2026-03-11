# Intent Gate + OpenSpec Skill Mapping

How the agent classifies user intent and auto-triggers the appropriate OpenSpec skill.

---

## Intent Classifications

### Trivial

**Detection**: User asks a factual question about specs, format, or project state.

**Examples**:
- "What format do delta specs use?"
- "How many active changes are there?"
- "What's in the auth spec?"

**Behavior**: Just answer. No skills triggered, no artifacts, no ceremony.

---

### Exploratory

**Detection**: User is thinking out loud, exploring an idea, not committed to a direction.

**Examples**:
- "I'm thinking about adding monitoring"
- "What would it take to split the auth service?"
- "How hard would it be to migrate from X to Y?"

**Auto-trigger**: `/opsx:explore`

**Behavior**:
1. Surface-level dig -- read relevant specs, codebase, .sisyphus/notepads
2. Discuss options, trade-offs, implications
3. Think about second-order effects ("if we do X, it implies Y for Z")
4. When the idea solidifies: "Want to turn this into a proposal?"
5. If yes -> transition to Explicit intent, trigger `/opsx:propose`

---

### Explicit

**Detection**: User clearly wants a spec/proposal created.

**Examples**:
- "Propose a backup service for CORE"
- "Create a spec for adding dark mode"
- "I want to spec out a new monitoring stack"

**Auto-trigger**: `/opsx:propose`

**Behavior**:
1. Quick exploration phase (read existing state)
2. Start clearance check (conversational, not blocking)
3. Begin incremental artifact generation with assumption tracking
4. Full brainstorm flow through phases 2-5

---

### Plan-to-Spec (Document Conversion)

**Detection**: User provides or references an existing planning document and
wants it converted to OpenSpec format. The agent uses a tiered detection
system to identify the source format with high confidence before acting.

**Auto-trigger**: `/opsx:propose`

---

#### Detection Tiers (evaluated in order, first match wins)

##### Tier 1: Known Plan Paths (high confidence, auto-detect)

These are well-known locations with predictable structure. If the user
references a file at one of these paths, the agent knows exactly what
it is and proceeds immediately.

**Sisyphus plans** (highest confidence):
```
.sisyphus/plans/*.md
.sisyphus/drafts/*.md
```
- Structure: task waves, evidence paths, verification steps, tool specs
- Always has: scenario description, expected outcomes, commit strategy
- Richest source format -- maps cleanly to all 4 OpenSpec artifacts
- Associated notepads at `.sisyphus/notepads/*/` provide extra context

**Claude Code plans**:
```
.claude/plans/*.md
```
- Structure: numbered steps, considerations, approach sections
- Typically has: goal statement, step-by-step plan, trade-offs
- Less structured than Sisyphus but still predictable format

**Triggers at this tier**:
- User says "convert my Sisyphus plan" or "use the plan in .sisyphus"
- User says "convert my Claude plan" or references `.claude/plans/`
- User provides a path that matches these glob patterns
- Agent finds these files during Phase 1 exploration and user confirms

**Behavior**: No ambiguity. Read the file, begin conversion immediately.
The agent knows the format and can map sections confidently.

##### Tier 2: Common Plan Conventions (medium confidence, verify format)

These are common locations/names for planning documents. The agent is
fairly confident these are plans but should verify the structure after
reading before committing to conversion.

**Common plan file locations**:
```
PLAN.md (project root)
docs/plans/*.md
docs/rfcs/*.md
docs/adrs/*.md
docs/design/*.md
```

**Triggers at this tier**:
- User references one of these paths explicitly
- User says "convert this RFC" or "turn this ADR into a spec"
- User says "spec out this plan" and points to a file in these dirs

**Behavior**: Read the file first. Verify it looks like a planning document
by checking for structural signals:
- Has headings like "Background", "Motivation", "Approach", "Decision"
- Contains requirement-like language ("must", "shall", "should")
- Has task lists, steps, or action items
- Discusses alternatives or trade-offs

If structure confirms it's a plan: proceed with conversion.
If structure is ambiguous: drop to Tier 4 (ask the user).

##### Tier 3: Keyword-Based Detection (low confidence, heuristic)

User provides a `.md` file path that doesn't match known locations.
The agent reads the file and scans for plan-like content.

**Keywords and patterns that suggest a plan**:

| Category | Keywords / Patterns |
|----------|-------------------|
| Planning language | "roadmap", "plan", "phase", "milestone", "timeline" |
| Requirement language | "must", "shall", "should", "requirement", "acceptance criteria" |
| Task language | "TODO", "[ ]", "step 1", "action item", "deliverable" |
| Design language | "architecture", "approach", "design", "decision", "trade-off" |
| Scope language | "in scope", "out of scope", "goals", "non-goals" |
| RFC/ADR language | "status: accepted", "context", "alternatives considered" |

**Scoring**: The agent mentally tallies how many categories are present:
- 3+ categories with multiple hits -> likely a plan, proceed with conversion
  but flag it: "This looks like a planning document. Converting to OpenSpec format."
- 1-2 categories -> ambiguous, drop to Tier 4
- 0 categories -> not a plan, reclassify intent (probably Exploratory or Explicit)

**Triggers at this tier**:
- User provides a random `.md` path: "turn docs/notes/backup-ideas.md into a spec"
- User pastes markdown content directly into chat
- User says "spec this out" with a file that isn't in a known plan location

**Behavior**: Read, scan for keywords, assess confidence.
If confident: proceed but verbalize: "This looks like a [plan/RFC/design doc].
I'll convert it to OpenSpec format."
If not confident: Tier 4.

##### Tier 4: Ask the User (fallback, zero confidence)

The agent can't determine if the user wants plan-to-spec conversion,
or the source document's format is unclear.

**Triggers**:
- Tier 2 file didn't have plan-like structure
- Tier 3 keyword scan was ambiguous (1-2 categories)
- User's message is vague: "do something with this file"
- Agent genuinely isn't sure what the user wants

**Behavior**: Ask ONE specific question. Not "what do you want?" but
something targeted:

```
"I see [filename]. It looks like it might be [description of what it
contains]. Would you like me to:
  (a) Convert it to an OpenSpec proposal
  (b) Use it as reference while we brainstorm something new
  (c) Something else?"
```

This is the LAST resort. The agent should exhaust Tiers 1-3 before
asking. But it should never guess wrong on intent -- a bad conversion
wastes more time than one clarifying question.

---

#### Conversion Mapping (all tiers)

Once the source is identified, extract what's available:

| If the source has... | Maps to |
|---------------------|---------|
| Context, motivation, background, "why" | `proposal.md` |
| Technical decisions, architecture, approach | `design.md` |
| Task lists, steps, implementation order | `tasks.md` |
| Requirements, acceptance criteria, constraints | `specs/` (ADDED delta format) |
| Alternatives considered, trade-offs | `design.md` (decision rationale) |
| Verification steps, test plans | `tasks.md` (verification section) |

#### Source-Specific Mapping Details

**From Sisyphus plans** (Tier 1):

| Sisyphus Section | OpenSpec Artifact |
|-----------------|-------------------|
| Plan header, scenario | `proposal.md` (motivation, scope) |
| Tool spec, technical decisions | `design.md` (technical approach) |
| Task waves (Wave 1, Wave 2...) | `tasks.md` (ordered implementation) |
| Expected outcomes per task | `specs/` (ADDED: acceptance criteria) |
| Evidence paths | `tasks.md` (verification section) |
| Final verification wave (F1-F4) | `tasks.md` (final verification) |
| Commit strategy | `tasks.md` (delivery section) |

**From Claude Code plans** (Tier 1):

| Claude Plan Section | OpenSpec Artifact |
|--------------------|-------------------|
| Goal / objective | `proposal.md` (motivation) |
| Steps / approach | `design.md` (technical approach) |
| Numbered steps | `tasks.md` (implementation order) |
| Considerations / constraints | `specs/` (ADDED: requirements) |
| Trade-offs / alternatives | `design.md` (decision rationale) |

**From RFCs / ADRs** (Tier 2):

| RFC/ADR Section | OpenSpec Artifact |
|----------------|-------------------|
| Context / Background | `proposal.md` (motivation) |
| Decision / Resolution | `design.md` (technical approach) |
| Consequences | `specs/` (ADDED: implied requirements) |
| Alternatives Considered | `design.md` (decision rationale) |
| Status | `proposal.md` (current state note) |

**From freeform / keyword-detected docs** (Tier 3):

Best-effort extraction. For content that doesn't map cleanly:
- Use `{{PLACEHOLDER}}` markers with notes about what's needed
- Don't invent content -- if the source doesn't discuss testing, leave
  test strategy as a placeholder rather than guessing
- Flag decisions that weren't explicitly justified as assumptions

---

#### Post-Conversion Behavior (all tiers)

1. Present artifacts incrementally with assumptions flagged
2. Since this is a conversion (not greenfield), flag any decisions in the
   source that weren't explicitly justified -- these become Tier 1
   assumptions to confirm in Phase 4
3. Mark missing sections with `{{PLACEHOLDER}}` and a note about what's needed
4. Ask about gaps that block other sections (Tier 3 big decisions)
5. If the source was rich (Sisyphus plan), most artifacts will be complete
6. If the source was sparse (freeform notes), most artifacts will have
   placeholders -- transition into brainstorm mode to fill them

---

### Open-ended

**Detection**: User doesn't have a specific direction. Wants guidance or suggestions.

**Examples**:
- "What should I work on next?"
- "What's the biggest gap in our specs?"
- "Any technical debt worth addressing?"

**Auto-trigger**: `/opsx:explore`

**Behavior**:
1. Read specs, .sisyphus notepads (especially `problems.md`, `issues.md`),
   active changes, codebase state
2. Suggest areas based on gaps, tech debt, incomplete specs
3. Offer to propose when user picks a direction

---

### Ambiguous

**Detection**: Can't determine what the user wants from the message alone.

**Behavior**: Ask ONE clarifying question. Do not trigger any skills yet.

---

## Skill Trigger Decision Tree

```
User message arrives
│
├─ Is it a question about existing state? ─────── Trivial (no skill)
│
├─ Does it reference a known plan path? ──────── Plan-to-Spec (/opsx:propose)
│  (.sisyphus/plans/, .claude/plans/)              Tier 1: auto-detect
│
├─ Does it reference a file in a common ─────── Plan-to-Spec (/opsx:propose)
│  plan location? (PLAN.md, docs/rfcs/)            Tier 2: verify format first
│
├─ Does it point to a .md file and say ──────── Plan-to-Spec (/opsx:propose)
│  "convert/spec/turn into"?                       Tier 3: keyword scan
│
├─ Does it explicitly ask for a proposal? ────── Explicit (/opsx:propose)
│
├─ Does it explore an idea without ───────────── Exploratory (/opsx:explore)
│  commitment?
│
├─ Is it asking for suggestions/direction? ───── Open-ended (/opsx:explore)
│
├─ Does it reference a .md file but intent ───── Plan-to-Spec Tier 4 (ask)
│  is unclear?                                     "Convert this, or use as ref?"
│
└─ Can't tell at all? ───────────────────────── Ambiguous (ask, no skill)
```

**Key principle**: Plan-to-spec detection is evaluated BEFORE other intents
because it has concrete signals (file paths, conversion verbs). If none of
the plan-to-spec tiers match, fall through to the standard intent checks.

## Escalation Pattern

The key insight: **every non-trivial intent starts with exploration, and exploration
can always escalate to proposal.**

```
Exploratory ──── "Want to turn this into a proposal?" ──── /opsx:propose
Open-ended ───── "Want me to spec this out?" ────────────── /opsx:propose
Plan-to-spec ─── already a proposal, but confirm scope ── /opsx:propose
```

The agent should never force a user into proposal mode. It explores, surfaces
information, and offers the upgrade. The user decides when to commit.

## Intent Verbalization

The agent should verbalize its classification (adapted from Sisyphus, softened
for collaborative context):

```
> "This sounds like you're exploring [topic] -- let me dig into the current
   state before we discuss options."

> "You want a full proposal for [feature]. Let me check a few things first
   before we start building the spec."

> "I see you have a Sisyphus plan for [name]. I can convert this to OpenSpec
   format -- let me read through it."

> "I'm not sure if you want me to explore this idea or spec it out. Which
   would be more helpful right now?"
```

Tone: collaborative, not robotic. State what you're about to do, not a
classification label.
