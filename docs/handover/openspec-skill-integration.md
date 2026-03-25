# Handoff: openspec-skill-integration

## Spec Reference

`openspec/changes/openspec-skill-integration/` -- proposal.md, design.md, tasks.md, specs/

Delta specs in `specs/`: solon-debug, solon-spec-phase1, solon-spec-phase6, solon-handoff, solon-init

## Key Decisions Summary

1. **Solon = brain, OpenSpec skills = hands.** Plain English interface -- user never touches OpenSpec commands directly. Solon delegates all mechanical file operations to OpenSpec skills.

2. **OpenSpec is a hard dependency.** No silent fallback to direct writes. If any required OpenSpec dependency is missing, Solon stops and points to `/solon-debug`. This eliminates the dual code path (delegated vs. direct) that the previous design implied.

3. **New solon-debug skill owns all diagnostics.** Single centralized diagnostic tree: CLI installed -> project initialized -> skills present -> profile check (core vs expanded) -> version staleness. Also owns the `openspec update --force` remediation flow and writes version markers to `.solon/openspec-version.txt`.

4. **Expanded OpenSpec profile required.** Core profile lacks `openspec-new-change` and `openspec-continue-change`. The `openspec-propose` skill is explicitly NOT used because it generates all artifacts in one shot, contradicting Solon's incremental conversational approach. solon-debug detects core-only installs and advises `openspec config profile`.

5. **Phase 1 gate checks for 3 skills.** Before exploration begins, verify presence of: `openspec-explore`, `openspec-new-change`, `openspec-continue-change`. Missing any -> stop + `/solon-debug`. Exploration itself is delegated to `openspec-explore`.

6. **Phase 6 delegates artifact writes via sub-agent.** Sub-agent dispatched with Agent tool, has Bash access, invokes skills by name using the Skill tool. Solon provides confirmed content from Phases 2-4 in the dispatch prompt. Content fence: unfilled template sections get `{{DEFERRED: not addressed in current spec cycle}}`. No new content generation (locked-state rule).

7. **Phase 7 unchanged.** Stays as ledger verification + nudge to handoff. `openspec-verify-change` is post-implementation only, not pre-implementation spec verification.

8. **solon-init simplified.** Drop `which openspec` CLI pre-flight check (redundant with init command failure handling). If `openspec init --tools Claude` fails -> stop + `/solon-debug`. Git repo and git remote warnings preserved as non-blocking.

9. **Sub-agents CAN invoke skills via Skill tool.** Tested and confirmed. Skills are session-level and shared across agent/sub-agent contexts.

## Implementation Constraints

### Files to Modify

| Action | File | Variant |
|--------|------|---------|
| CREATE | `claude/skills/solon-debug/SKILL.md` | Also `opencode/skills/solon-debug/SKILL.md` |
| MODIFY | `claude/skills/solon-spec/SKILL.md` | Also `opencode/skills/solon-spec/SKILL.md` |
| MODIFY | `claude/skills/solon-handoff/SKILL.md` | Also `opencode/skills/solon-handoff/SKILL.md` |
| MODIFY | `claude/skills/solon-init/SKILL.md` | Also `opencode/skills/solon-init/SKILL.md` |
| REVIEW | `claude/skills/solon-eval/SKILL.md` | (no opencode variant) |

### Files NOT to Touch

- `solon-ingress`, `solon-reconcile`, `graphiti-ledger-status` -- unchanged
- `claude/agent/solon.md` (base agent definition) -- no changes needed
- Any code files outside agent/skill definitions

### Path Restrictions

Solon may only write to: `openspec/`, `specs/`, `.solon/`, `.graphiti/`

solon-debug writes version marker to `.solon/openspec-version.txt`.

OpenSpec update safety: updates only touch `openspec-*` prefixed skill files, never `solon-*` skills.

### Required Patterns

- solon-debug allowed-tools: `Bash, Read, Glob` only (no Agent, Write)
- Phase 6 sub-agent dispatch prompt must include confirmed content + content fence instruction
- Both `claude/` and `opencode/` variants must be updated for skills that have both
- Phase 1 gate checks file existence at `.claude/skills/openspec-explore/SKILL.md`, `.claude/skills/openspec-new-change/SKILL.md`, `.claude/skills/openspec-continue-change/SKILL.md`

### Hard Non-Goals

- No graceful degradation or silent fallback to direct writes
- No use of `openspec-propose` (batch generation contradicts incremental approach)
- No version/staleness checks in solon-spec itself (solon-debug's job)
- No changes to Phase 7 semantics
- No changes to solon-ingress, solon-reconcile, or graphiti-ledger-status

## Suggested Strategy

### Sequencing and Dependencies

```
Task 1: solon-debug (CREATE)          -- INDEPENDENT, build first
   |                                     Other skills reference /solon-debug on failure
   v
Task 2: solon-spec Phase 1 (MODIFY)   -- Depends on Task 1 (references /solon-debug)
Task 3: solon-spec Phase 6 (MODIFY)   -- Depends on Task 1 (references /solon-debug)
   Tasks 2+3 can be done together (same file)
   |
Task 4: solon-handoff (MODIFY)        -- INDEPENDENT of Tasks 2-3
Task 5: solon-init (MODIFY)           -- INDEPENDENT of Tasks 2-3, depends on Task 1
   Tasks 4+5 can be parallelized
   |
Task 6: Archive stale doc             -- ALREADY DONE
   |
Task 7: solon-eval review (REVIEW)    -- Do last, after all modifications are complete
```

### Parallelism Opportunities

- Tasks 2+3 target the same file (`solon-spec/SKILL.md`), so bundle them
- Tasks 4+5 are independent of each other and of Tasks 2+3; can run in parallel after Task 1
- Task 7 (eval review) is read-only analysis that should wait until all other tasks land

### Risk Areas

1. **Phase 6 sub-agent prompt engineering.** The dispatch prompt must thread the needle: include enough confirmed content for the sub-agent to populate templates correctly, enforce the content fence (`{{DEFERRED}}`), and invoke skills by name (`openspec-new-change`, `openspec-continue-change`) in the right sequence. Getting this wrong means either hallucinated content or broken skill invocations.

2. **Profile detection in solon-debug.** Need to know the exact expanded-profile skill name set to distinguish core from expanded installs. The spec identifies `openspec-new-change` and `openspec-continue-change` as expanded-only, but the full expanded set may include more. The detection logic must be accurate.

3. **solon-debug itself needs Bash access.** This is acceptable for a diagnostic/remediation skill, but the allowed-tools constraint (`Bash, Read, Glob` -- no Agent, no Write) must be respected. Version marker writes go through Bash (`echo > .solon/openspec-version.txt`), not the Write tool.

4. **Implementation ordering.** solon-debug MUST be built first. If solon-spec or solon-init ship before solon-debug exists, their `/solon-debug` failure pointers will be broken references.

5. **Dual variant maintenance.** Both `claude/` and `opencode/` directories need updates for solon-debug (create), solon-spec (modify), solon-handoff (modify), solon-init (modify). Missing one variant creates an inconsistent installation.

## Post-Implementation Workflow

After all tasks are implemented, run the following OpenSpec skills in order:

1. **openspec-apply-change** -- Applies the delta specs from `openspec/changes/openspec-skill-integration/specs/` to the baseline specs, implementing the changes across all affected skill files.

2. **openspec-verify-change** -- Validates that the implementation matches the spec requirements. Checks each scenario in the delta specs against the actual file contents. Reports pass/fail per requirement.

3. **openspec-archive-change** -- Archives the completed change, merging delta specs into the baseline and closing out `openspec/changes/openspec-skill-integration/`.

These are post-Solon territory -- the handoff skill does not invoke them. They are referenced here for the implementer's awareness.
