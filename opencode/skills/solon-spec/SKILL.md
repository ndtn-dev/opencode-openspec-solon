---
name: solon-spec
description: Core spec-writing workflow with 7-phase process, soft ratchet, and ingress dispatch
compatibility: opencode
metadata:
  category: spec
  triggers:
    - spec
    - propose
    - explore
    - plan-to-spec
    - reconcile
    - brainstorm
---

# Solon Spec
Use this skill on the main Solon agent after Phase 0 routing.
Scope: run the complete 7-phase spec workflow from exploration through write verification.
Hard boundaries:
- No Phase 0 intent gate logic.
- No base-agent identity/role text.
- No code implementation or deployment execution.
- No reconcile triage category engine (that stays in `solon-reconcile`).
- No redefinition of full ingress internals (that stays in `solon-ingress`).

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
- Use relative paths for all file operations: `openspec/`, `.sisyphus/`, `.solon/`, `.graphiti/`.
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

4) Run decision tracking housekeeping:
- Load `graphiti-ledger-status` and perform a lightweight session check.
- If Postgres is unavailable, count `.graphiti/ingress/pending/` JSON fallbacks.

5) Plan-to-spec conversion rules:
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

Assumption tiers:
- Small: proceed, queue for Phase 4 confirmation.
- Medium: continue with `{{PLACEHOLDER: suggestion + context}}`.
- Big: stop and present options as a numbered list with a recommendation. Ask the user to pick one.

Decision tracking rules:
- Every decision is tracked with phase/tier/status metadata.
- Use `decision_status=active` for current decisions.
- Corrections must link via `superseded_by`.

Phase 2 micro-ingress for Big decisions only:
1. Load `graphiti-ledger-insert`.
2. Insert decision row with `phase=P2`, `tier=Big`, `decision_status=active`.
3. Call `add_memory` for the confirmed Big decision.
4. Keep GUID linkage in source metadata.

Big override handling:
1. Record replacement decision via `graphiti-ledger-insert`.
2. Link old -> new with `superseded_by`.
3. Ingest correction rationale via `add_memory`.

Small and Medium are not ingested in Phase 2; they are batch-ingested after Phase 4 in Phase 5.
Holistic thinking requirements:
- Surface second-order effects.
- Check coherence with existing specs.
- Reference prior learnings and decision history.

### Reconcile Mode (Phase 2 variant)
When entering from reconcile intent:
1. Enumerate every deviation between spec and implementation evidence.
2. Classify each deviation as Small, Medium, or Big.
3. Micro-ingest confirmed Big deviations immediately using the same Phase 2 Big path.
4. Queue Small/Medium deviations for Phase 4 confirmation and Phase 5 batch ingestion.

Reconcile note: this is deviation handling, not triage taxonomy generation.
## Phase 3: Gap Analysis (Mandatory)
This phase always runs and is never skipped.
Execution:
1. Attempt `@metis` delegation first.
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
- Candidate overrides that supersede prior decisions

User may:
- Confirm all
- Override selected assumptions
- Fill placeholders
- Request targeted return to Phase 2

Phase 5 cannot run until this summary state is explicit.
## Phase 5: Ingress Checkpoint (Verify)
This is the persistence and verification gate before artifact writing.
1) Verify Phase 2 records:
- Load `graphiti-ledger-status` and verify current-session rows.
- Capture verified vs pending counts.

2) Batch-record confirmed Small/Medium decisions:
- Load `graphiti-ledger-insert`.
- Insert confirmed Small/Medium assumptions for first-time ingestion tracking.
- Apply `superseded_by` links for overrides.

3) All-tier ingestion policy (Decision #19):
- Graph ingestion happens via `add_memory` through the `solon-ingress` + `graphiti-normalizer` path.
- Big decisions: already ingested in Phase 2 micro-ingress -> skip duplicate graph ingestion in Phase 5.
- Medium decisions: graph-ingested for first time in Phase 5.
- Small decisions: graph-ingested for first time in Phase 5.
- All tiers: ledger records are verified at Phase 5.

4) Dispatch solon-ingress:
```python
task(
  category='unspecified-high',
  load_skills=['solon-ingress', 'graphiti-enhancer', 'graphiti-ledger-insert', 'graphiti-normalizer'],
  run_in_background=true,
  prompt='INGRESS CHECKPOINT BATCH: process confirmed Phase 5 decisions, enforce Decision #19 all-tier ingestion, skip Big graph duplicates already ingested in Phase 2, return enhanced/dropped/ingested summary with errors if any.'
)
```
Depth guard:
- Do not spawn sub-sub-agents from this path.

5) Write checkpoint file:
- Ensure directory exists: `.solon/checkpoints/`
- Write `.solon/checkpoints/{spec-name}-phase5.json`:
  ```json
  {
    "spec": "{spec-name}",
    "phase": 5,
    "completed_at": "{ISO 8601 timestamp}",
    "session_id": "{current session ID}",
    "decisions_ingested": N,
    "decisions_dropped": M
  }
  ```
- This file is the structural gate for Phase 6.

## Phase 6: Write Artifacts (LOCKED)
Phase 6 is locked once writing begins.
Pre-write gate (hard stop):
1. Check for `.solon/checkpoints/{spec-name}-phase5.json`.
   - If missing: STOP. Report: "Phase 5 checkpoint missing. Run Phase 5 ingress before writing artifacts."
   - If present: read and log the checkpoint summary.
2. Query `execute_sql` for current-session episode count (secondary verification).
3. If zero, check `.graphiti/ingress/pending/` fallback JSON count.
4. If both are zero, stop and report checkpoint failure.

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

## Phase 7: Verify and Nudge
1. Fire ledger status pass via `graphiti-ledger-status` (`all`: drain, verify, report) as background:
   ```
   task(category='quick', load_skills=['graphiti-ledger-status'], run_in_background=true, prompt='CHECK LEDGER STATUS: all for session {session_id}')
   ```
2. Immediately nudge toward Handoff intent (do not wait for verify result):
   - `Specs are locked. Want me to generate a handoff document for implementation?`
3. If the background verify completes while the user is still in session, surface the summary as informational context.

Topic-switch rule:
- If the user changes topic mid-flow, yield to Phase 0 routing and stop treating this skill as active framework.
## Integrity Rules

- Preserve phase integrity: Phase 3 mandatory, Phase 5 gates Phase 6, Phase 6 locked.
- Never skip decision tracking before write.
- Never duplicate Big graph ingestion already completed in Phase 2.
- Keep ledger state, graph ingestion state, and artifact content aligned.
