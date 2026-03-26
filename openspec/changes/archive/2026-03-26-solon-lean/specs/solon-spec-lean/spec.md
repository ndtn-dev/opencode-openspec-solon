## MODIFIED Requirements

### Requirement: Skill description and phase count
solon-spec SHALL describe itself as a 6-phase spec workflow (not 7-phase). The skill description MUST reference "6-phase process" and "solon-mem dispatch" instead of "7-phase process" and "ingress dispatch." The hard boundaries MUST remove the reference to `solon-ingress` internals.

#### Scenario: Skill metadata reflects new structure
- **WHEN** solon-spec is loaded
- **THEN** the description references 6 phases and solon-mem dispatch, with no mention of ingress dispatch or solon-ingress

### Requirement: Phase 1 Exploration without graphiti housekeeping
Phase 1 SHALL NOT invoke `graphiti-ledger-status` or perform any decision tracking housekeeping. Phase 1 MUST retain: skill presence gate (blocking check for OpenSpec skill files), path resolution rules, auto-detect OpenSpec state via `openspec-explore`, context reading in strict priority order, and plan-to-spec conversion rules.

#### Scenario: Phase 1 runs without graphiti calls
- **WHEN** solon-spec enters Phase 1
- **THEN** solon-spec performs skill presence gate, path resolution, OpenSpec state detection, context reading, and plan-to-spec conversion without invoking graphiti-ledger-status or any graphiti/ledger operations

#### Scenario: Phase 1 retains skill presence gate
- **WHEN** solon-spec enters Phase 1 and a required OpenSpec skill file is missing
- **THEN** solon-spec stops and reports "OpenSpec dependency missing. Run /solon-debug to diagnose."

### Requirement: Phase 2 Brainstorm with solon-mem instead of three-tier classification
Phase 2 SHALL NOT use three-tier classification (Big/Medium/Small). Phase 2 SHALL NOT perform micro-ingress for any decisions. Phase 2 SHALL NOT call `graphiti-ledger-insert` or `add_memory`. Phase 2 MUST invoke solon-mem for each decision made during conversation. solon-mem handles classification (key/routine) and local staging. Phase 2 MUST retain: clearance criteria, assumption handling (without tier-specific behavior), holistic thinking requirements, and reconcile mode variant.

#### Scenario: Decision during brainstorm triggers solon-mem
- **WHEN** a decision is confirmed during Phase 2 brainstorming
- **THEN** solon-spec invokes solon-mem with the decision, and solon-mem handles classification and staging

#### Scenario: No graphiti calls during brainstorm
- **WHEN** Phase 2 is active and decisions are being made
- **THEN** solon-spec does not call graphiti-ledger-insert, add_memory, or any graphiti MCP tools

#### Scenario: Assumption handling without tiers
- **WHEN** an assumption arises during Phase 2
- **THEN** solon-spec handles it as: proceed and queue for Phase 4 confirmation (small assumptions), use placeholder notation (ambiguous assumptions), or stop and present options to user (significant assumptions) -- without referencing Big/Medium/Small tier labels

#### Scenario: Reconcile mode uses solon-mem
- **WHEN** solon-spec enters Phase 2 in reconcile mode
- **THEN** deviations are classified as key or routine (not Big/Medium/Small) and staged via solon-mem

### Requirement: Phase 3 Gap Analysis unchanged
Phase 3 SHALL remain unchanged from the current implementation. Phase 3 MUST retain: mandatory execution (never skipped), delegation attempt to gap-analysis agent with silent fallback to self-review, self-review checklist, and finding classification (blocking/warning/note).

#### Scenario: Phase 3 runs identically to current behavior
- **WHEN** solon-spec enters Phase 3
- **THEN** gap analysis runs with the same checklist, delegation pattern, and finding classification as the current implementation

### Requirement: Phase 2-3 Soft Ratchet Loop Guard unchanged
The soft ratchet loop guard between Phase 2 and Phase 3 SHALL remain unchanged. The guard rule MUST escalate to the user if the same gap appears in 2 consecutive Phase 2-3 cycles.

#### Scenario: Repeated gap triggers escalation
- **WHEN** the same gap appears in 2 consecutive Phase 2-3 cycles
- **THEN** solon-spec escalates to the user with gap name, insufficiency reason, recommended resolution, and confirmation request

### Requirement: Phase 4 Assumption Summary without graphiti language
Phase 4 SHALL NOT reference "candidate overrides that supersede prior decisions" in graphiti terms. Phase 4 MUST surface: confirmed assumptions, remaining placeholders, Phase 3 findings (blocking/warning/note). User MAY confirm all, override selected assumptions, fill placeholders, or request targeted return to Phase 2. Phase 5 MUST NOT run until Phase 4 summary state is explicit.

#### Scenario: Phase 4 presents summary without graphiti references
- **WHEN** solon-spec enters Phase 4
- **THEN** the assumption summary includes confirmed assumptions, remaining placeholders, and Phase 3 findings, with no mention of graphiti, ledger records, or ingestion state

### Requirement: Phase 5 Finalize replaces Ingress Checkpoint
Phase 5 SHALL be "Finalize" (not "Ingress Checkpoint"). Phase 5 MUST: (1) read the staging file at `.solon/staging/{spec-name}.md`, (2) invoke solon-mem to produce an evolution summary, (3) solon-mem dispatches the summary to Clio if available, (4) write a checkpoint file to `.solon/checkpoints/{spec-name}-phase5.json`. Phase 5 SHALL NOT invoke graphiti-ledger-status, graphiti-ledger-insert, execute_sql, add_memory, or dispatch solon-ingress. The checkpoint file MUST contain: format_version (2), spec name, phase (5), completed_at timestamp, and session_id. The `format_version: 2` field distinguishes new-format checkpoints from legacy checkpoints written by prior solon-spec versions. Legacy checkpoints (without format_version) are tolerated by the Phase 6 pre-write gate but are never generated by this workflow.

#### Scenario: Phase 5 reads staging and produces summary
- **WHEN** solon-spec enters Phase 5
- **THEN** solon-spec reads `.solon/staging/{spec-name}.md` and invokes solon-mem to produce an evolution summary

#### Scenario: Phase 5 writes checkpoint file
- **WHEN** Phase 5 completes
- **THEN** solon-spec writes `.solon/checkpoints/{spec-name}-phase5.json` with format_version (2), spec name, phase (5), completed_at timestamp, and session_id

#### Scenario: New checkpoint format includes format_version
- **WHEN** Phase 5 writes a checkpoint file
- **THEN** the checkpoint JSON includes `format_version: 2` to distinguish it from legacy checkpoint formats

#### Scenario: Phase 5 contains no graphiti operations
- **WHEN** Phase 5 is executing
- **THEN** no graphiti MCP tools, execute_sql, ledger inserts, or solon-ingress dispatches are invoked

### Requirement: Phase 6 Write Artifacts merges old Phase 6 and Phase 7
Phase 6 SHALL combine artifact writing (old Phase 6) and handoff nudge (old Phase 7). Phase 6 is locked once writing begins. The pre-write gate MUST check for `.solon/checkpoints/{spec-name}-phase5.json` and stop if missing. The pre-write gate SHALL NOT query execute_sql or check `.graphiti/ingress/pending/`. Write sequence MUST use sub-agent delegation via openspec-new-change and openspec-continue-change skills. After writing completes, Phase 6 MUST nudge toward handoff intent. Phase 6 SHALL NOT dispatch graphiti-ledger-status.

#### Scenario: Pre-write gate checks checkpoint only
- **WHEN** solon-spec enters Phase 6
- **THEN** solon-spec checks for the Phase 5 checkpoint file and does not query execute_sql or check .graphiti/ingress/pending/

#### Scenario: Pre-write gate accepts new-format checkpoint
- **WHEN** solon-spec enters Phase 6 and `.solon/checkpoints/{spec-name}-phase5.json` exists with `format_version: 2`
- **THEN** solon-spec accepts the checkpoint and proceeds with Phase 6

#### Scenario: Pre-write gate accepts legacy checkpoint
- **WHEN** solon-spec enters Phase 6 and `.solon/checkpoints/{spec-name}-phase5.json` exists but does NOT contain `format_version` (legacy format from a prior solon-spec version)
- **THEN** solon-spec accepts the checkpoint based on file existence alone and proceeds with Phase 6. Legacy checkpoints are tolerated but not generated by the new workflow.

#### Scenario: Missing checkpoint blocks Phase 6
- **WHEN** solon-spec enters Phase 6 and `.solon/checkpoints/{spec-name}-phase5.json` does not exist
- **THEN** solon-spec stops and reports "Phase 5 checkpoint missing. Run Phase 5 before writing artifacts."

#### Scenario: Post-write nudge toward handoff
- **WHEN** artifact writing completes in Phase 6
- **THEN** solon-spec nudges the user toward handoff intent (e.g., "Specs are locked. Want me to generate a handoff document for implementation?")

#### Scenario: Locked-state rules preserved
- **WHEN** Phase 6 writing is active
- **THEN** no new content generation occurs (content fence enforced), no return to brainstorm while current write pass is active, and if interrupted the current write unit finishes before looping back to Phase 2

### Requirement: No Phase 7
solon-spec SHALL NOT have a Phase 7. The old Phase 7 (Verify and Nudge) functionality is absorbed into the new Phase 5 (Finalize) and Phase 6 (Write Artifacts + Nudge).

#### Scenario: Phase count is exactly 6
- **WHEN** the solon-spec skill is fully defined
- **THEN** it contains exactly Phases 1 through 6 with no Phase 7

### Requirement: Simplified integrity rules
Integrity rules SHALL preserve: phase integrity (Phase 3 mandatory, Phase 5 gates Phase 6, Phase 6 locked) and topic-switch yielding to Phase 0. Integrity rules SHALL NOT reference: "Never duplicate Big graph ingestion" or "Keep ledger state, graph ingestion state, and artifact content aligned."

#### Scenario: Phase integrity preserved without graphiti references
- **WHEN** integrity rules are evaluated
- **THEN** Phase 3 is mandatory, Phase 5 gates Phase 6, Phase 6 is locked, and no references to graph ingestion or ledger state alignment exist

## REMOVED Requirements

### Requirement: Phase 2 micro-ingress for Big decisions
**Reason**: Three-tier classification (Big/Medium/Small) and Phase 2 micro-ingress via graphiti-ledger-insert and add_memory are replaced by solon-mem's two-tier classification and per-decision staging/dispatch.
**Migration**: Decisions are now staged via solon-mem during Phase 2. solon-mem handles classification (key/routine) and dispatches to Clio.

### Requirement: Phase 5 Ingress Checkpoint verification and batch ingestion
**Reason**: The entire ingress checkpoint phase (ledger verification, batch ingestion dispatch via solon-ingress, execute_sql calls, graphiti-ledger-status verification) is replaced by the new Phase 5 Finalize workflow using solon-mem evolution summaries.
**Migration**: Phase 5 now reads the staging file, produces an evolution summary via solon-mem, and writes a checkpoint file. No graphiti tools are invoked.

### Requirement: Phase 7 Verify and Nudge
**Reason**: Phase 7's graphiti-ledger-status dispatch is removed. The handoff nudge is merged into Phase 6.
**Migration**: Post-write handoff nudge moves to Phase 6. Graphiti verification is Clio's responsibility (co-loads graphiti-ledger-status).

### Requirement: Decision tracking via graphiti-ledger-insert
**Reason**: All direct graphiti-ledger-insert calls are removed from solon-spec. Decision tracking is handled by solon-mem's staging file and optional Clio dispatch.
**Migration**: Use solon-mem for all decision staging. solon-mem writes to `.solon/staging/` and dispatches to Clio.

### Requirement: Phase 1 graphiti-ledger-status housekeeping
**Reason**: Phase 1 no longer performs graphiti housekeeping. Ledger health is Clio's responsibility.
**Migration**: Remove graphiti-ledger-status invocation and pending fallback counting from Phase 1.
