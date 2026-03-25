## Context

Solon currently reimplements OpenSpec behavior instead of delegating to OpenSpec's CLI-generated skills. OpenSpec skills (SKILL.md files) handle templates, file operations, and validation. The goal is for Solon to act as a natural language interface -- the user talks plain English and Solon delegates mechanical work to OpenSpec skills behind the scenes.

The core architectural model: Solon is the brain (thinking, decisions, user interaction). OpenSpec skills are the hands (file operations, templates, validation). The user never needs to remember OpenSpec commands or CLI syntax.

Key constraint: Solon disallows Bash (it is a design partner, not an executor). OpenSpec skills require Bash for CLI commands. This creates a dispatch problem that shapes the entire integration architecture.

Solon path restrictions limit writes to: openspec/, specs/, .solon/, .graphiti/.

## Goals / Non-Goals

**Goals:**
- Delegate all mechanical file operations to OpenSpec skills (explore, new-change, continue-change)
- Make OpenSpec a hard dependency with clear diagnostics when anything is missing
- Preserve Solon's incremental, conversational spec workflow (no batch generation)
- Centralize all OpenSpec dependency diagnostics in a single skill (solon-debug)
- Enable automatic pickup of OpenSpec template/validation improvements on update

**Non-Goals:**
- Using the openspec propose command (it generates all artifacts in one shot, contradicting Solon's incremental approach)
- Graceful degradation or silent fallback to direct writes when OpenSpec is unavailable
- Version or staleness checks in solon-spec itself (that is solon-debug's job)
- Pre-implementation spec verification via openspec-verify-change (that is post-implementation only)
- Changes to Phase 7 (stays as ledger verification + nudge to handoff)

## Decisions

### Decision 1: OpenSpec is a Hard Dependency

**Choice:** If any required OpenSpec dependency is missing, Solon stops and points to /solon-debug. No silent fallback to direct writes.

**Rationale:** The previous design treated OpenSpec as optional with graceful degradation. This created two code paths (delegated vs. direct writes) that were difficult to test and maintain. A hard dependency simplifies the architecture and ensures consistent artifact quality.

**Alternatives considered:**
- Graceful degradation with direct writes as fallback -- rejected because it undermines the value of delegation and creates a maintenance burden of two parallel write paths.

### Decision 2: Expanded OpenSpec Profile Required

**Choice:** Solon requires the expanded OpenSpec profile, not just the core profile.

**Rationale:**
- Core profile provides: explore, propose, apply-change, archive-change
- Solon needs: explore, new-change, continue-change (expanded profile only)
- The propose skill is explicitly NOT used because it generates all artifacts in one shot, contradicting Solon's incremental conversational approach
- solon-debug detects a core-only profile and tells the user to run: `openspec config profile`

**Alternatives considered:**
- Using the core profile's propose command and parsing its batch output -- rejected because it contradicts Solon's fundamental incremental design philosophy.

### Decision 3: Sub-Agent Dispatch for Skill Invocation

**Choice:** Solon dispatches sub-agents via the Agent tool. Sub-agents have Bash access and invoke OpenSpec skills using the Skill tool.

**Rationale:** Solon itself disallows Bash (design partner, not executor), but OpenSpec skills require Bash for CLI commands. Sub-agents solve this by having their own Bash access while Solon remains a pure thinking/decision layer.

Tested and confirmed: sub-agents CAN invoke skills by name via the Skill tool. Skills are session-level and shared across agent and sub-agent contexts.

**Alternatives considered:**
- Giving Solon direct Bash access -- rejected because it breaks the brain/hands separation that keeps Solon focused on design.
- Writing files directly without skills -- rejected (see Decision 1).

### Decision 4: Diagnostics Offloaded to solon-debug

**Choice:** All OpenSpec dependency diagnostics live in one new skill: solon-debug. Other skills (solon-spec, solon-init) just check and point to /solon-debug on failure.

**Rationale:** Centralizing diagnostics keeps solon-spec and solon-init lean. The diagnostic tree is complex (CLI installed? -> Project initialized? -> All skills present? -> Specific skill missing? -> Profile mismatch? -> Version staleness? -> CLI runtime error?) and maintaining it in one place avoids duplication.

solon-debug also owns the `openspec update` remediation flow (version staleness check + `openspec update --force`) and writes the version marker to .solon/openspec-version.txt.

**Alternatives considered:**
- Inline diagnostics in each skill -- rejected because it duplicates logic and makes maintenance harder.
- A separate diagnostic CLI command -- rejected because it wouldn't integrate with Solon's conversational flow.

### Decision 5: Content Fence for Artifact Creation

**Choice:** During Phase 6 sub-agent dispatch, Solon provides confirmed content (decisions, scope, constraints, filled placeholders) in the dispatch prompt. For any template section with no confirmed content from Solon, the sub-agent writes "{{DEFERRED: not addressed in current spec cycle}}" -- it does not generate new content.

**Rationale:** This preserves the locked-state rule: no new brainstorming during writes. Phase 6 is purely mechanical -- converting confirmed decisions into artifact files. The content fence ensures sub-agents cannot hallucinate new design decisions.

**Alternatives considered:**
- Allowing sub-agents to fill gaps creatively -- rejected because it violates the locked-state rule and could introduce unreviewed decisions.

## Risks / Trade-offs

**Hard dependency creates onboarding friction** -> Mitigated by solon-debug providing clear, actionable diagnostics and fix commands for every failure mode. The diagnostic tree covers CLI installation, project initialization, skill presence, profile mismatch, and version staleness.

**Sub-agent dispatch adds latency to Phase 6** -> Accepted trade-off. The benefit of automatic template/validation improvements outweighs the cost of sub-agent overhead. Phase 6 is not latency-sensitive (user is waiting for artifact files, not interactive responses).

**Profile mismatch is a silent failure mode** -> Mitigated by solon-debug detecting core-only profile and guiding the user to switch. The gate check in Phase 1 catches missing skills before any work begins.

**openspec update could break solon-* skills** -> Mitigated by OpenSpec's update scope: it only touches openspec-* prefixed skill files, never solon-* skills. This is an OpenSpec guarantee, not enforced by Solon.

**Implementation ordering dependency** -> solon-debug must be built first since solon-spec and solon-init reference it for failure paths. Incorrect ordering would create broken references.

**solon-debug itself needs Bash access** -> allowed-tools for solon-debug: Bash, Read, Glob. This is acceptable because solon-debug is a diagnostic/remediation skill, not a design skill. It respects Solon's path restrictions (version marker written to .solon/).
