# Handoff: solon-lean

## Spec Reference

`openspec/changes/solon-lean/` in this repo (~/Projects/opencode-openspec-solon):
- `proposal.md` -- why, what changes, capabilities
- `design.md` -- 5 decisions with alternatives, 5 risks with mitigations, opencode/ parity decision
- `specs/solon-mem/spec.md` -- 8 requirements (classification, staging, supersession, dispatch, evolution summary, session ID, format)
- `specs/solon-spec-lean/spec.md` -- 11 modified + 5 removed requirements (all 6 phases, integrity rules)
- `specs/solon-agent-lean/spec.md` -- 2 modified + 3 removed requirements (DoubleWriting, PathRestrictions, LedgerAutoVerify)
- `tasks.md` -- 7 groups, 27 tasks

## Prerequisite

**clio-agent** (~/Projects/clio-graphiti-agent) MUST be implemented first. solon-mem dispatches to Clio; if Clio doesn't exist, solon-mem gracefully degrades (staging file only, no graph persistence).

## Key Decisions

1. **Two-tier classification**: key/routine replaces Big/Medium/Small. Classification lives in solon-mem, not solon-spec.
2. **Dispatch per decision**: solon-mem dispatches to Clio on every staging write. Phase 5 sends evolution summary separately.
3. **Verbose staging file**: .solon/staging/{spec-name}.md preserves raw conversation excerpts, quoted statements, session ID on every entry. This is the text-based ledger.
4. **Graceful degradation**: If Clio is unavailable, solon-mem skips dispatch silently. Staging file is the durable record. Solon works fully without Clio.
5. **Phase 0 routing unchanged**: No new routes. Small changes still go through solon-spec (the phases are fast without graphiti ceremony).
6. **6 phases, not 7**: Phase 5 becomes Finalize (summarize + ship). Old Phase 6+7 merge into new Phase 6 (write + nudge).
7. **opencode/ parity**: All changes mirrored to opencode/ directory.

## Implementation Constraints

- **Do NOT call graphiti MCP tools directly from solon-spec or solon-mem** -- all graphiti access goes through Clio
- **Do NOT add .graphiti/ back to PathRestrictions** -- Clio owns .graphiti/
- **solon-mem reads .graphiti/config.yaml** for group_id -- this is a read-only dependency, not a write path
- **Checkpoint format_version: 2** -- Phase 6 pre-write gate must accept both new and legacy checkpoints
- **Session ID resolution**: CLAUDE_SESSION_ID env var -> timestamp fallback. Must be consistent within a session.
- **Staging file archival**: On session mismatch, rename old file with session ID suffix, create fresh

## Suggested Strategy

### Implementation Order (from tasks.md)

```
1. Create solon-mem skill
   New skill: classification, staging file write, Clio dispatch, evolution summary.
   This is the core new capability.

2. Refactor solon-spec
   7 phases -> 6 phases. Remove all graphiti ceremony.
   Replace with solon-mem calls. Simplify integrity rules.
   This is the largest task group.

3. Refactor solon.md agent definition
   Remove LedgerAutoVerify, .graphiti/ paths, ingress checkpoint language.
   Small, focused edits.

4. Remove skills from Solon
   Delete solon-ingress and graphiti-ledger-status from claude/skills/.
   (Functionality moved to Clio)

5. Update solon-eval
   Adjust test expectations for new phase structure.
   Remove tier/micro-ingress references.

6. Mirror to opencode/
   All changes from steps 1-5 replicated in opencode/ directory.
   Include opencode/ YAML permission updates.

7. Verification
   Confirm line count reduction, zero graphiti refs, parity check.
```

### Parallelism

- Tasks 1 and 3 are independent (can be done in parallel)
- Task 2 depends on task 1 (solon-spec calls solon-mem)
- Tasks 4, 5, 6 can be done after 1-3 are complete
- Task 7 depends on all others

### Risk Areas

- **solon-spec refactor (task 2)**: Largest change. The current skill is ~220 lines and deeply entangled with graphiti. Careful line-by-line removal needed.
- **opencode/ parity (task 6)**: opencode/agent/solon.md has a YAML permission frontmatter that differs structurally from claude/agent/solon.md. The implementer must update this permission block (add solon-mem, remove solon-ingress, remove graphiti-ledger-status, remove .graphiti/ edit permission).
- **Session ID availability**: CLAUDE_SESSION_ID may not exist in all environments. The timestamp fallback must work reliably.

## Post-Implementation

1. **Verify**: `openspec-verify-change` -- validate implementation matches spec requirements
2. **Archive**: `openspec-archive-change` -- archive the completed change and merge delta specs
