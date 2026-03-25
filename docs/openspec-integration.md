# OpenSpec CLI Integration Proposal

Solon currently writes artifacts directly. This proposal maps Solon's phases
to OpenSpec's CLI-generated skills so Solon acts as the cognitive orchestrator
while OpenSpec handles mechanical file operations, templates, and validation.

---

## Current State

Solon references `/opsx:explore`, `/opsx:propose`, and `/opsx:apply` in
design docs but the actual skills reimplement the behavior rather than
delegating. OpenSpec's skills were likely unavailable or immature when
Solon was built.

## Goal

Wrap OpenSpec's skills so Solon picks up improvements to templates,
validation, and artifact formats automatically.

---

## Phase-to-Skill Mapping

### Solon orchestrates (no delegation)

| Phase | Solon does | Why not delegate |
|-------|-----------|-----------------|
| Phase 0: Intent Gate | Classify and route | OpenSpec has no intent routing |
| Phase 2: Brainstorm | Incremental artifacts, assumption tracking | OpenSpec has no assumption tiers or decision tracking |
| Phase 3: Gap Analysis | Mandatory review with escalation | OpenSpec has no gap analysis |
| Phase 4: Assumption Summary | Surface decisions for confirmation | OpenSpec has no equivalent |
| Phase 5: Ingress Checkpoint | Persist decisions to knowledge graph | OpenSpec has no decision persistence |

### Solon delegates to OpenSpec

| Phase | OpenSpec skill | How |
|-------|---------------|-----|
| Phase 1: Explore | `/opsx:explore` | Delegate codebase investigation. Solon adds structured reading order (specs → notepads → project context → codebase) on top. |
| Phase 1: Explore (fresh project) | `/opsx:onboard` | When exploring a new project, use onboard to get oriented via existing specs. |
| Phase 6: Write (scaffold) | `/opsx:new` | Create change directory structure. Replaces manual `mkdir -p openspec/changes/[name]/`. |
| Phase 6: Write (artifacts) | `/opsx:continue` | Generate one artifact at a time using OpenSpec templates. Matches Solon's incremental approach. Solon fills in confirmed values, placeholders resolved, overrides applied — then delegates the actual file write to OpenSpec's template system. |
| Phase 7: Verify | `/opsx:verify` | Run completeness/correctness/coherence check after artifacts are locked. Complements Solon's ledger verification with spec-level validation. |

### Post-Solon (other agents handle)

| Workflow step | OpenSpec skill | Notes |
|---------------|---------------|-------|
| Implementation | `/opsx:apply` | Task-by-task implementation. Solon hands off via solon-handoff. |
| Archive | `/opsx:archive` | Move completed change to archive, sync delta specs into main. Solon should mention this in handoff nudge. |
| Spec sync | `/opsx:sync` | Merge delta specs into main specs post-archive. |
| Bulk cleanup | `/opsx:bulk-archive` | Archive multiple completed changes. |

### Not used

| OpenSpec skill | Why |
|---------------|-----|
| `/opsx:propose` | Replaced by Solon's Phases 2-6. Propose generates all artifacts in one shot — contradicts Solon's incremental, gated approach. |
| `/opsx:ff` | Fast-forwards all remaining artifacts. Contradicts Solon's deliberate phase-by-phase process. Could be offered as an escape hatch if user explicitly wants to skip. |
| `/opsx:feedback` | Meta-workflow skill. Not relevant to Solon's spec-writing flow. |

---

## Implementation Notes

### Bash restriction

Solon has `disallowedTools: [Bash]`. OpenSpec CLI commands require Bash.
Solution: Phase 6 dispatches a sub-agent (via Agent tool) with Bash access
to run `openspec new`, `openspec instructions`, etc. Solon provides the
content; the sub-agent handles file operations.

### Template integration

`openspec instructions <artifact-id> --json` returns structured templates
with context, rules, and output paths. Phase 6 should:
1. Dispatch sub-agent to run `openspec new change "[name]"`
2. Get artifact instructions via `openspec instructions <id> --json`
3. Merge Solon's confirmed content (from Phases 2-4) with OpenSpec's template
4. Dispatch sub-agent to write the file at the specified output path

### Prerequisite

OpenSpec CLI must be installed (`bun add -g @fission-ai/openspec`).
`solon-init` already checks for this. If missing, Solon falls back to
direct file writes (current behavior).

### Graceful degradation

If OpenSpec CLI is not available:
- Phase 1: Solon explores directly (current behavior)
- Phase 6: Solon writes files directly (current behavior)
- Phase 7: Solon runs self-review only (current behavior)
- Post-handoff: Manual archive instructions in handoff doc

---

## Changes Required

### solon-spec skill
- Phase 1: Add `/opsx:explore` delegation before structured reading order
- Phase 6: Replace direct file writes with `/opsx:new` + `/opsx:continue` delegation
- Phase 7: Add `/opsx:verify` delegation alongside ledger verification

### solon-handoff skill
- Mention `/opsx:archive` and `/opsx:sync` in handoff document

### solon-init skill
- After `openspec init`, verify that OpenSpec generated its own skills
- Ensure both Solon skills and OpenSpec skills coexist without conflict

### Design docs
- Update intent-skill-mapping.md to reflect delegation vs replacement
- Update agent-phases.md Phase 6 and 7 descriptions
