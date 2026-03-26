---
name: solon-mem
description: Decision staging and optional Clio dispatch for Solon spec sessions. Two-tier classification (key/routine), local staging to .solon/staging/, and Phase 5 evolution summary generation.
---

# Solon Mem

Adapter between Solon and Clio for decision persistence.
Called by solon-spec to stage one or more decisions and dispatch to Clio.
Also called at Phase 5 to produce an evolution summary.

## Session ID

Resolve once per session, reuse for all operations:
1. `CLAUDE_SESSION_ID` environment variable (if set).
2. Conversation's unique identifier (if available).
3. Fallback: `session-{ISO 8601 timestamp}` (e.g., `session-2026-03-25T14:30:00`).

## Classification

Two tiers only:
- **Key**: evolved (changed during conversation), architectural (affects system structure), or contentious (user debated alternatives).
- **Routine**: everything else — accepted without debate.

Do NOT use Big/Medium/Small or any other multi-tier system.

## Staging Decisions

The caller's prompt contains one or more decisions to stage. Process ALL of them — do not stop after the first.

For each decision in the prompt, write an entry to `.solon/staging/{spec-name}.md`:

1. Ensure `.solon/staging/` exists (create if needed).
2. If a staging file exists for this spec:
   - **Same session ID in header** -> append, continuing the D-NNN sequence.
   - **Different session ID** -> archive the old file to `.solon/staging/{spec-name}.{old-session-id}.md`, then create a fresh file.
3. If no staging file exists, create one with a header.
4. Assign sequential IDs: D-001, D-002, etc. (continuing from the last entry if appending).
5. Write ALL decision entries in one pass (see format below).
6. After writing, dispatch to Clio (see below).

## Clio Dispatch

After writing all decisions to the staging file, dispatch to Clio once with all staged decisions:

1. Determine `group_id` from `.graphiti/config.yaml` or caller context.
2. If `group_id` is unavailable: skip dispatch, log that group_id was unavailable.
3. Dispatch the `clio` agent in the background with ingress intent, including all decisions from this invocation:
   - Decision titles, classifications (key/routine), session ID, group_id
   - Verbose context (conversation excerpts)
   - Decision text for each
   - Supersedes references (if applicable)
4. One Clio dispatch per solon-mem invocation, not per decision.

### Graceful Degradation

- If Clio dispatch fails or agent is not found: continue silently.
- The staging file is always the durable record.
- Solon functions fully without Clio/graphiti.

## Decision Supersession

When a new decision replaces a prior one within the same staging file:
1. New entry includes `Supersedes: D-NNN`.
2. Annotate the old entry title with `[SUPERSEDED by D-NNN]`.
3. Set old entry status to `superseded`.
4. Preserve the original entry content (never delete).

## Phase 5 Evolution Summary

When invoked for Phase 5:
1. Read the full staging file for the current spec.
2. Produce a narrative summary:
   - Which decisions evolved (were superseded and why).
   - What was finalized.
   - Overall arc of the session's decisions.
3. Append the evolution summary to the staging file.
4. Dispatch the summary to Clio as an evolution summary (separate knowledge type from individual decisions).
5. If Clio is unavailable, the staging file summary is sufficient.

## Staging File Format

### Header
```markdown
# Decision Ledger: {spec-name}
Session: {session-id} | Started: {YYYY-MM-DD}
```

### Decision Entry
```markdown
## D-NNN: {title}
- **Phase**: {phase number}
- **Classification**: key | routine
- **Session**: {session-id}
- **Context**:
  > {quoted user/assistant statements and conversation excerpts}
- **Decision**: {decision text}
- **Supersedes**: D-NNN (only if applicable)
- **Status**: active | superseded
```

### Evolution Summary (Phase 5)
```markdown
## Evolution Summary
- **Session**: {session-id}
- **Decisions**: {count} total, {superseded count} evolved
- **Narrative**: {description of how decisions evolved}
```

## Do NOT

- Use three-tier (Big/Medium/Small) classification.
- Call graphiti tools directly — Clio handles graph persistence.
- Block on Clio dispatch failures.
- Delete or overwrite superseded entries.
