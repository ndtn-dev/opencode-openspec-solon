## Why

Solon currently references OpenSpec skill commands (/opsx:explore, /opsx:propose, etc.) in design docs but reimplements the behavior instead of delegating. OpenSpec's CLI-generated skills (SKILL.md files) are well-designed agent instructions that handle templates, file operations, and validation. Solon should delegate mechanical work to these skills so it automatically picks up improvements to templates, validation, and artifact formats when OpenSpec is updated.

The user's primary motivation: use plain English instead of remembering OpenSpec commands. Solon is the natural language interface to OpenSpec.

## What Changes

1. **solon-spec Phase 1** -- Add minimal gate check: verify 3 required OpenSpec skills are present (openspec-explore, openspec-new-change, openspec-continue-change). If missing, stop and point to /solon-debug. Also delegate codebase exploration to openspec-explore skill.

2. **solon-spec Phase 6** -- Replace direct artifact file writes with delegation to OpenSpec skills via sub-agent. Sub-agent has Bash access and invokes openspec-new-change (scaffold) then openspec-continue-change (per-artifact) using the Skill tool. Solon provides confirmed content from Phases 2-4.

3. **solon-spec Phase 7** -- No change. Stays as ledger verification + nudge to handoff. openspec-verify-change is post-implementation only, not suitable for pre-implementation spec verification.

4. **solon-handoff** -- Update handoff document to reference the full post-implementation workflow: apply (openspec-apply-change) -> verify (openspec-verify-change) -> archive (openspec-archive-change).

5. **solon-init** -- Simplify: remove redundant CLI pre-flight check (which openspec). Keep git repo and git remote warnings. If openspec init fails, stop and point to /solon-debug.

6. **solon-debug (NEW SKILL)** -- New skill that owns all OpenSpec dependency diagnostics: CLI installed? Project initialized? Skills present? Correct profile? Version staleness? Also owns the openspec update remediation flow.

## Capabilities

### New Capabilities

- `solon-debug`: New skill that owns all OpenSpec dependency diagnostics and remediation (CLI installed, project initialized, skills present, correct profile, version staleness, update flow)

### Modified Capabilities

- `solon-spec-phase1`: Skill presence gate check + delegation of codebase exploration to openspec-explore
- `solon-spec-phase6`: OpenSpec skill delegation via sub-agent for artifact creation
- `solon-handoff`: Post-implementation workflow references (apply -> verify -> archive)
- `solon-init`: Simplified pre-flight checks with fail-to-debug pointer

## Impact

- **OpenSpec becomes a hard dependency** (not optional). No silent fallback to direct writes.
- **Expanded OpenSpec profile required**: core profile lacks new-change and continue-change skills. solon-debug detects and guides profile switch.
- **Sub-agents dispatched in Phase 6** need Bash access (already the case in current architecture).
- **openspec update safety**: updates only touch openspec-* prefixed files, never clobbers solon-* skills.
- **docs/openspec-integration.md to be archived**: superseded by this spec.
