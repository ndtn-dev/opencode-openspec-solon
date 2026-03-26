# Handoff: solon-mem Batch Staging & Classification Fix

**Spec reference:** `openspec/specs/solon-mem/spec.md`
**Decision ledger:** `.solon/staging/solon-mem.md`
**Date:** 2026-03-26

## Key Decisions Summary

Three key decisions drive this implementation (all classified "key"):

| ID    | Decision                                              | Root Cause                                |
|-------|-------------------------------------------------------|-------------------------------------------|
| D-001 | Explicit loop structure for multi-decision staging    | Linear 6-step checklist lets model early-return after 1 decision |
| D-002 | Batch Clio dispatch per invocation                    | Per-decision dispatch fuses multi-item payloads into single Graphiti episode |
| D-003 | Sharpen classification criteria + ambiguity default   | "Affects system structure" too vague; model misclassifies architectural decisions as routine |

## Target Artifacts

### 1. `claude/skills/solon-mem/SKILL.md` and `opencode/skills/solon-mem/SKILL.md`

Both files are identical copies. Apply changes to both.

#### Change A: Classification section (D-003)

Current:
```markdown
## Classification

Two tiers only:
- **Key**: evolved (changed during conversation), architectural (affects system structure), or contentious (user debated alternatives).
- **Routine**: everything else — accepted without debate.

Do NOT use Big/Medium/Small or any other multi-tier system.
```

Replace with:
```markdown
## Classification

Two tiers only:
- **Key**: meets ANY of these — evolved (changed or superseded during conversation), architectural (affects system structure, data flow, API boundaries, event models, or component relationships), or contentious (user debated alternatives or explicitly chose between options).
- **Routine**: accepted without debate AND does not affect system structure.

When classification is ambiguous, default to **key**.

Do NOT use Big/Medium/Small or any other multi-tier system.
```

#### Change B: Staging Decisions section (D-001)

Current section is a flat numbered list (steps 1-6). Replace the entire "Staging Decisions" section with a three-phase structure:

```markdown
## Staging Decisions

The caller's prompt contains one or more decisions to stage. Process ALL of them in a single invocation.

### Setup
1. Ensure `.solon/staging/` exists (create if needed).
2. If a staging file exists for this spec:
   - **Same session ID in header** -> append, continuing the D-NNN sequence.
   - **Different session ID** -> archive the old file to `.solon/staging/{spec-name}.{old-session-id}.md`, then create a fresh file.
3. If no staging file exists, create one with a header.

### For EACH decision in the caller's prompt
4. Classify the decision (key or routine).
5. Assign the next sequential ID (D-001, D-002, etc., continuing from the last entry if appending).
6. Write the entry to the staging file using the format below.

### After ALL entries are written
7. Verify: count of entries written MUST match count of decisions received.
8. Report: "Staged N decisions (D-001 through D-NNN)".
9. Proceed to Clio dispatch (see below).

Do NOT return or yield control until steps 7-9 are complete.
```

The critical structural change: steps 4-6 are nested under an iteration header. The model cannot satisfy "For EACH decision" by processing one. Steps 7-9 are nested under a completion header with an explicit count verification that forces the model to compare what it wrote against what it received.

#### Change C: Clio Dispatch section (D-002)

Current section dispatches with a generic list of fields. Replace with structured batch payload format:

```markdown
## Clio Dispatch

After writing ALL decisions to the staging file, dispatch to Clio ONCE:

1. Determine `group_id` from `.graphiti/config.yaml` or caller context.
2. If `group_id` is unavailable: skip dispatch, log that group_id was unavailable.
3. Dispatch the `clio` agent in the background with this structured batch payload:

```
Remember these decisions from spec session:

Spec: {spec-name}
Session: {session-id}
Group: {group_id}

Decisions:
1. **{title}** [{classification}]
   Context: {quoted conversation excerpts}
   Decision: {decision text}
   Supersedes: {D-NNN or none}

2. **{title}** [{classification}]
   ...
```

4. One Clio dispatch per solon-mem invocation. Do NOT dispatch per decision.
```

### 2. `claude/skills/solon-spec/SKILL.md` and `opencode/skills/solon-spec/SKILL.md`

Minor update to the decision staging instructions in the Phase 2 section.

Current (lines 66-71):
```markdown
Decision staging (MANDATORY — do this when decisions are confirmed):
When the user confirms one or more decisions:
1. Use the Skill tool to invoke `solon-mem` with a prompt listing ALL newly confirmed decisions. For each decision include: spec name, phase, decision title, context (quoted user statements), and decision text.
2. If any decision corrects, reverses, or replaces a prior one, include the prior decision ID as a supersedes reference.
3. Do NOT write to `.solon/staging/` directly — solon-mem owns that file.
4. solon-mem handles classification (key/routine), writes to `.solon/staging/`, and dispatches to Clio in the background.
```

Replace with:
```markdown
Decision staging (MANDATORY — do this when decisions are confirmed):
When the user confirms one or more decisions:
1. Use the Skill tool to invoke `solon-mem` with a prompt listing ALL newly confirmed decisions. Structure the prompt with: spec name, phase, and a numbered list where each item has decision title, context (quoted user statements), and decision text.
2. If any decision corrects, reverses, or replaces a prior one, include the prior decision ID as a supersedes reference on that item.
3. Do NOT write to `.solon/staging/` directly — solon-mem owns that file.
4. solon-mem handles classification (key/routine), writes ALL decisions to `.solon/staging/` in one pass, and dispatches a single batch to Clio in the background.
```

## Implementation Constraints

- **Do not touch** `openspec/specs/solon-mem/spec.md` — the spec is already updated.
- **Do not touch** `.solon/staging/` or `.solon/handoffs/` — those are Solon-owned artifacts.
- Both `claude/skills/` and `opencode/skills/` copies must stay identical.
- The SKILL.md frontmatter (`name`, `description`) does not need to change.
- Preserve all sections not mentioned above (Session ID, Decision Supersession, Phase 5 Evolution Summary, Staging File Format, Do NOT list).

## Cross-Repo Dependency

Clio's batch ingress support must be implemented **before** the batch dispatch from solon-mem will produce per-decision granularity in Graphiti. Without it, Clio will still fuse the batch payload into a single episode.

- **Handoff:** `.solon/handoffs/clio-batch-ingress.md` (in this repo)
- **Target repo:** `~/Projects/clio-graphiti-agent`
- **Target spec:** `openspec/specs/clio-agent/spec.md`

Sequencing: apply Clio batch ingress first, then solon-mem SKILL updates. solon-mem's staging file writes work independently of Clio, so the local staging fix (D-001) can be applied immediately regardless.

## Suggested Strategy

1. **Immediate (no dependency):** Apply Changes A and B to solon-mem SKILL.md — fixes the staging loop and classification. These work without Clio changes.
2. **After Clio batch ingress:** Apply Change C to solon-mem SKILL.md — switches to batch payload format.
3. **Anytime:** Apply solon-spec SKILL.md update — clarifies the prompt structure solon-spec sends to solon-mem.

Risk area: Change B is the structural fix for the main blocker. The three-phase layout (setup/iteration/completion) must be visually distinct in the SKILL.md — if the headers get flattened or the nesting is lost, the model may still early-return. Preserve the `### Setup` / `### For EACH` / `### After ALL` headers exactly.

## Post-Implementation Steps

After implementation is complete, run these in order:

1. **Verify:** `openspec-verify-change` — validate that SKILL.md files match spec requirements.
2. **Archive:** `openspec-archive-change` — archive the completed change and merge delta specs into baseline.
