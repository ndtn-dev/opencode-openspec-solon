---
name: solon-spec
description: Core spec-writing workflow with 6-phase process, soft ratchet, and solon-mem dispatch. Invoke when Solon routes to Spec, Plan-to-spec, Exploratory, Explicit, or Open-ended intent.
---

# Solon Spec
Use this skill on the main Solon agent after Phase 0 routing.
Scope: run the complete 6-phase spec workflow from exploration through artifact writing.
Hard boundaries:
- No Phase 0 intent gate logic.
- No base-agent identity/role text.
- No code implementation or deployment execution.
- No reconcile triage category engine (that stays in `solon-reconcile`).

## Phase 1: Exploration
Run exploration before brainstorming or writing.

0) Skill presence gate (BLOCKING):
Before any exploration, verify these three skill files exist:
- `.claude/skills/openspec-explore/SKILL.md`
- `.claude/skills/openspec-new-change/SKILL.md`
- `.claude/skills/openspec-continue-change/SKILL.md`

If any are missing: **STOP**. Report: "OpenSpec dependency missing. Run /solon-debug to diagnose."
Do NOT attempt direct-write fallback or proceed without the skills.

1) Path resolution:
- Use relative paths for all file operations: `openspec/`, `.sisyphus/`, `.solon/`.
- Do not construct absolute paths from injected environment metadata (it may be incorrect).
- If an absolute path is needed, resolve from the working directory, not from env strings.

2) Auto-detect OpenSpec state:
- Use the Skill tool to invoke `openspec-explore` for codebase exploration and to check for `openspec/` and active change artifacts. Do NOT dispatch an Explore agent — the openspec-explore skill handles exploration directly when loaded on self.
- If `openspec/` is missing, yield to Init flow, then resume Phase 1 from start.

3) Read context in strict priority order:
1. OpenSpec state: `openspec/specs/`, `openspec/changes/`
2. Sisyphus knowledge: `.sisyphus/notepads/`, `.sisyphus/plans/`, `.sisyphus/handover/`
3. Project context: `AGENTS.md`, `CLAUDE.md`, `project.md`
4. Other planning artifacts: `.claude/plans/`, `PLAN.md`, `docs/rfcs/`, `docs/plans/`
5. Relevant codebase files only

4) Plan-to-spec conversion rules:
- Motivation/context -> `proposal.md`
- Architecture/constraints -> `design.md`
- Implementation sequencing -> `tasks.md`
- Requirements -> `specs/*.md` (OpenSpec delta format)
- Unknowns -> `{{PLACEHOLDER: suggestion + context}}` (never invent)

## Phase 2: Brainstorm + Incremental Artifacts
Artifacts form during conversation; no monolithic generation pass.
Clearance criteria must be woven naturally into dialogue:
1. Core objective and success criteria
2. Scope boundaries (in/out)
3. Critical ambiguities
4. Technical approach
5. Verification strategy

Assumption handling (by confidence, not tier):
- Confident enough to proceed: accept and queue for Phase 4 confirmation.
- Ambiguous: continue with `{{PLACEHOLDER: suggestion + context}}`.
- Significant or contested: stop and present options as a numbered list with a recommendation. Ask the user to pick one.

Every decision is tracked. No decision goes unrecorded.

Decision staging (MANDATORY — do this when decisions are confirmed):
When the user confirms one or more decisions:
1. Use the Skill tool to invoke `solon-mem` with a prompt listing ALL newly confirmed decisions. For each decision include: spec name, phase, decision title, context (quoted user statements), and decision text.
2. If any decision corrects, reverses, or replaces a prior one, include the prior decision ID as a supersedes reference.
3. Do NOT write to `.solon/staging/` directly — solon-mem owns that file.
4. solon-mem handles classification (key/routine), writes to `.solon/staging/`, and dispatches to Clio in the background.

Holistic thinking requirements:
- Surface second-order effects.
- Check coherence with existing specs.
- Reference prior learnings and decision history.

### Reconcile Mode (Phase 2 variant)
When entering from reconcile intent:
1. Enumerate every deviation between spec and implementation evidence.
2. For each confirmed deviation, invoke `solon-mem` (classifies as key/routine and stages).
3. Queue unconfirmed deviations for Phase 4 confirmation and Phase 5 finalization.

Reconcile note: this is deviation handling, not triage taxonomy generation.
## Phase 3: Gap Analysis (Mandatory)
This phase always runs and is never skipped.
Execution:
1. Attempt delegation to a gap-analysis Agent first (e.g., a fresh-eyes reviewer).
2. If unavailable or failed, silently fall back to self-review.

Self-review checklist:
- Structural completeness
- Scope discipline
- Assumption audit
- Cross-artifact coherence
- Edge cases and failure modes

Report findings as:
- `blocking`
- `warning`
- `note`

## Phase 2<->3 Soft Ratchet Loop Guard
Track recurring unresolved gaps across Phase 2 and Phase 3 passes.
Guard rule:
- If the same gap appears in 2 consecutive Phase 2<->3 cycles, escalate to the user.

Escalation format:
- Name the repeated gap.
- State why current options are insufficient.
- Recommend a specific resolution.
- Ask for confirmation: "I recommend [X]. Proceed?"

This prevents infinite brainstorm loops while preserving collaboration.
## Phase 4: Assumption Summary
Surface consolidated checkpoint state:
- Confirmed assumptions
- Remaining placeholders
- Phase 3 findings (`blocking` / `warning` / `note`)
- Decisions that evolved during conversation (superseded earlier decisions)

User may:
- Confirm all
- Override selected assumptions
- Fill placeholders
- Request targeted return to Phase 2

Phase 5 cannot run until this summary state is explicit.
## Phase 5: Finalize
Persistence summary and checkpoint gate before artifact writing.

1) Read the staging file at `.solon/staging/{spec-name}.md`.
2) Use the Skill tool to invoke `solon-mem` with a prompt requesting an evolution summary for the spec. solon-mem reads the staging file, writes the summary to it, and dispatches to Clio if available.
3) Present the summary to the user: how many decisions were staged, which evolved, and the overall narrative arc. This is informational — no confirmation gate, but the user should see what was captured.
4) Write checkpoint file:
- Ensure directory exists: `.solon/checkpoints/`
- Write `.solon/checkpoints/{spec-name}-phase5.json`:
  ```json
  {
    "format_version": 2,
    "spec": "{spec-name}",
    "phase": 5,
    "completed_at": "{ISO 8601 timestamp}",
    "session_id": "{current session ID}"
  }
  ```
- This file is the structural gate for Phase 6.

## Phase 6: Write Artifacts (LOCKED)
Phase 6 is locked once writing begins.
Pre-write gate (hard stop):
1. Check for `.solon/checkpoints/{spec-name}-phase5.json`.
   - If missing: STOP. Report: "Phase 5 checkpoint missing. Run Phase 5 before writing artifacts."
   - If present: read and log the checkpoint summary. Accept both `format_version: 2` (current) and legacy checkpoints (no format_version field).

Write sequence — sub-agent delegation:
Dispatch a sub-agent via the Agent tool with Bash access. The sub-agent:
1. Invokes the `openspec-new-change` skill (via Skill tool) to scaffold the change directory.
2. Invokes the `openspec-continue-change` skill (via Skill tool) for each artifact.

Sub-agent prompt must include:
- All confirmed decisions, scope boundaries, constraints, and filled placeholders from Phases 2-4.
- Content fence instruction: for any template section with no confirmed content, write `{{DEFERRED: not addressed in current spec cycle}}`. Do not generate new content.

If the sub-agent's skill invocation fails: **STOP**. Report: "OpenSpec skill invocation failed. Run /solon-debug to diagnose."
Do NOT fall back to writing artifact files directly.

Locked-state rule:
- No new content generation during artifact writing (content fence enforced).
- No return to brainstorm while current write pass is active.
- If interrupted, finish current write unit, then loop back to Phase 2.

Post-write nudge:
- After artifact writing completes, nudge toward Handoff intent:
  `Specs are locked. Want me to generate a handoff document for implementation?`

Topic-switch rule:
- If the user changes topic mid-flow, yield to Phase 0 routing and stop treating this skill as active framework.
## Integrity Rules

- Phase 3 is mandatory; Phase 5 gates Phase 6; Phase 6 is locked once writing begins.
- Never skip decision staging (via solon-mem) before write.
