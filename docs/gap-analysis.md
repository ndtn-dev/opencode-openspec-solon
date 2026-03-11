# Gap Analysis System

How the agent reviews its own work before presenting final artifacts.
Combines optional Metis delegation with built-in self-review.

---

## When It Runs

Gap analysis runs at the boundary between Phase 2 (brainstorm/incremental
artifacts) and Phase 4 (assumption summary). The agent prompts:

```
"Artifacts are mostly complete. Want me to run a gap analysis before
finalizing? (This checks for missing requirements, over-engineering,
and blind spots.)"
```

User chooses:
- **Yes** -> Full gap analysis (Metis if available, self-review if not)
- **No** -> Skip straight to assumption summary + finalization

For smaller changes, skipping is fine. For architectural decisions or
multi-service proposals, gap analysis catches things.

---

## Execution: Try Metis, Fall Back to Self-Review

The agent always **attempts** Metis delegation first. If it fails (OmO not
installed, @metis not available, task tool denied), it silently falls back
to self-review. The user doesn't need to know or care which path ran --
they get gap analysis results either way.

```
Attempt @metis delegation
    │
    ├── Success -> present Metis findings
    │
    └── Failure (agent not found / task denied / error)
            │
            └── Fall back to self-review checklist
                    │
                    └── Present self-review findings
```

This means the agent works identically whether or not OmO is installed.

---

## Path A: Metis Delegation (preferred, automatic)

If Oh My OpenAgent is installed and `@metis` is available as a subagent:

**What gets sent to Metis**:
```
Review this draft OpenSpec proposal for gaps.

## Tracked Assumptions
[list of Tier 1 assumptions the planner made]

## Unresolved Placeholders
[list of Tier 2 {{PLACEHOLDER}} items]

## Draft Artifacts
[current state of proposal.md, design.md, specs/, tasks.md]

## User's Original Request
[the initial message that triggered this proposal]

Check for:
- Hidden intentions not captured in the proposal
- Over-engineering or unnecessary complexity
- Missing acceptance criteria
- Scope creep beyond original request
- Edge cases and failure modes not addressed
- Assumptions that should have been user decisions
- Conflicts with existing specs
```

**What Metis returns**: A list of gaps, each categorized as:
- **Blocking**: Must resolve before finalizing (missing critical requirement)
- **Warning**: Should address but not a blocker (vague acceptance criteria)
- **Note**: Worth considering but optional (edge case, nice-to-have)

**Why Metis is better**: Different model, no sunk cost in the plan it's reviewing.
Genuinely catches things the planner's own self-review misses because it has
no attachment to the decisions already made.

---

## Path B: Self-Review (automatic fallback)

If Metis isn't available (no OmO, or user chose not to install it):

The agent runs an internal checklist against its own output:

### Self-Review Checklist

**Structural completeness**:
- [ ] All four artifacts present (proposal.md, design.md, specs/, tasks.md)
- [ ] Every requirement in specs/ has acceptance criteria
- [ ] Tasks in tasks.md map to specific requirements in specs/
- [ ] Design.md technical approach aligns with proposal.md scope

**Scope discipline**:
- [ ] Change touches only what the user asked for
- [ ] No "while we're at it" additions
- [ ] No unnecessary abstractions or plugin systems
- [ ] Could this be simpler? (If yes, simplify before presenting)

**Assumption audit**:
- [ ] All Tier 1 assumptions are genuinely low-risk
- [ ] No Tier 3 (architectural) decisions were silently assumed
- [ ] Placeholder suggestions are reasonable defaults, not arbitrary

**Coherence check**:
- [ ] Proposal doesn't contradict existing specs in openspec/specs/
- [ ] Design doesn't conflict with past decisions in .sisyphus/notepads/
- [ ] Naming conventions match existing project patterns

**Edge cases**:
- [ ] Failure modes addressed (what happens when X is down?)
- [ ] Rollback strategy considered (can we undo this change?)
- [ ] Dependencies identified (does this require other changes first?)

### Self-Review Output

Presented to the user as part of the assumption summary:

```markdown
## Self-Review Findings

- [warning] Acceptance criteria for "backup completes successfully" is vague.
  Suggest: "backup exits 0, output file size > 0, sha256 matches source."
- [note] No rollback strategy defined. If backup corruption is detected,
  what's the recovery path?
- [ok] Scope looks clean -- touches only backup-related files.
```

---

## Effectiveness Comparison

```
┌────────────────────┬──────────────┬──────────────────────────────────────┐
│ Aspect             │ Metis        │ Self-Review                          │
├────────────────────┼──────────────┼──────────────────────────────────────┤
│ Hidden intentions  │ Strong       │ Weak (same blind spots as planner)   │
│ Over-engineering   │ Strong       │ Moderate (checklist helps)           │
│ Missing criteria   │ Strong       │ Strong (checklist-driven)            │
│ Scope creep        │ Moderate     │ Strong (checklist-driven)            │
│ Edge cases         │ Strong       │ Moderate                             │
│ Speed              │ Slower       │ Instant                              │
│ Cost               │ Extra tokens │ Free                                 │
│ Dependency         │ Requires OmO │ None                                 │
└────────────────────┴──────────────┴──────────────────────────────────────┘
```

Self-review is ~60-70% as effective as Metis for gap detection, but is always
available and adds no latency. Metis excels at catching things the planner
can't see about its own work.

---

## Interaction with Prometheus

Important context: if the user takes this proposal through Prometheus for
execution planning, Metis will run again as part of that pipeline. So gap
analysis at the OpenSpec stage is an **early catch** -- it prevents bad specs
from becoming bad plans. But it's not the last line of defense.

This means the OpenSpec agent's gap analysis can be lighter-touch than
Prometheus's. It focuses on spec quality and design coherence, not
implementation feasibility (that's Prometheus's job).
