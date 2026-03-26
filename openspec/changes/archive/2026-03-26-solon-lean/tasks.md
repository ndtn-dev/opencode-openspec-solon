## 1. Create solon-mem skill

- [x] 1.1 Create `claude/skills/solon-mem/SKILL.md` with two-tier classification logic (key/routine), staging file write, Clio dispatch, and Phase 5 evolution summary generation
- [x] 1.2 Create `.solon/staging/` directory structure (ensure it exists or is created on first use)
- [x] 1.3 Define the staging file markdown format: header with spec name, session ID, date; decision entries with D-NNN IDs, phase, classification, session, context, decision, supersedes fields
- [x] 1.4 Implement graceful degradation logic: dispatch to Clio when available, continue silently when unavailable

## 2. Refactor solon-spec skill

- [x] 2.1 Update skill metadata: change description from "7-phase" to "6-phase", replace "ingress dispatch" with "solon-mem dispatch", remove solon-ingress reference from hard boundaries
- [x] 2.2 Refactor Phase 1: remove `graphiti-ledger-status` invocation and decision tracking housekeeping step (item 4), retain skill presence gate, path resolution, OpenSpec state detection, context reading priority, plan-to-spec conversion
- [x] 2.3 Refactor Phase 2: remove three-tier classification (Big/Medium/Small), remove micro-ingress section, remove graphiti-ledger-insert and add_memory calls, add solon-mem invocation for each decision, simplify assumption handling to remove tier-specific labels, update reconcile mode variant to use key/routine classification
- [x] 2.4 Verify Phase 3 (Gap Analysis) and Phase 2-3 Soft Ratchet are unchanged -- no edits needed, confirm no graphiti references leaked in
- [x] 2.5 Refactor Phase 4: remove "candidate overrides that supersede prior decisions" graphiti language, retain confirmed assumptions, placeholders, Phase 3 findings, and user interaction options
- [x] 2.6 Rewrite Phase 5 as "Finalize": read staging file, invoke solon-mem for evolution summary, write checkpoint file to `.solon/checkpoints/{spec-name}-phase5.json`, remove all graphiti/ingress operations
- [x] 2.7 Merge old Phase 6 (Write Artifacts) and Phase 7 (Verify and Nudge) into new Phase 6: remove execute_sql and `.graphiti/ingress/pending/` pre-write checks, retain checkpoint file gate, retain sub-agent delegation for OpenSpec skills, add post-write handoff nudge, remove graphiti-ledger-status dispatch
- [x] 2.8 Simplify integrity rules: remove "Never duplicate Big graph ingestion" and "Keep ledger state, graph ingestion state, and artifact content aligned", retain phase integrity and topic-switch rules

## 3. Refactor solon.md agent definition

- [x] 3.1 Remove the entire `<LedgerAutoVerify>` section
- [x] 3.2 Remove `.graphiti/` from `<PathRestrictions>` permitted directories
- [x] 3.3 Simplify `<DoubleWriting>`: remove "Ingress checkpoints require explicit confirmation before entering Phase 6 writes" line, retain Reconcile -> Spec confirmation and user-authored consent rules

## 4. Remove skills from Solon's skill set

- [x] 4.1 Remove or relocate `claude/skills/solon-ingress/SKILL.md` (functionality moved to Clio in clio-agent change)
- [x] 4.2 Remove or relocate `claude/skills/graphiti-ledger-status/SKILL.md` (Clio co-loads graphiti-ledger-status directly)

## 5. Update solon-eval

- [x] 5.1 Update Test 4 (Explicit) pass/fail criteria: remove expectations about tier classification and micro-ingress, verify solon-mem staging behavior instead
- [x] 5.2 Review all other test cases for stale references to graphiti, tiers, or ingress; update descriptions if needed
- [x] 5.3 Verify scoring thresholds remain appropriate (7-8 pass, 5-6 marginal, <5 fail)

## 6. Mirror changes to opencode/

- [x] 6.1 Update `opencode/agent/solon.md` with the same changes as `claude/agent/solon.md` (remove LedgerAutoVerify, remove .graphiti/ path restrictions, simplify DoubleWriting)
- [x] 6.2 Update `opencode/skills/solon-spec/SKILL.md` with the same changes as `claude/skills/solon-spec/SKILL.md` (6-phase workflow, solon-mem dispatch, all phase refactors)
- [x] 6.3 Create `opencode/skills/solon-mem/SKILL.md` mirroring `claude/skills/solon-mem/SKILL.md`
- [x] 6.4 Remove `opencode/skills/solon-ingress/SKILL.md` (functionality moved to Clio in clio-agent change)
- [x] 6.5 Remove `opencode/skills/graphiti-ledger-status/SKILL.md` (Clio co-loads graphiti-ledger-status directly)

## 7. Verification

- [x] 7.1 Confirm solon-spec is approximately 100-120 lines (down from ~220)
- [x] 7.2 Confirm zero graphiti references remain in solon.md and solon-spec SKILL.md (both claude/ and opencode/)
- [x] 7.3 Confirm solon-reconcile, solon-handoff, solon-debug are unmodified (both claude/ and opencode/)
- [x] 7.4 Confirm Phase 0 routing table in solon.md is unchanged
- [x] 7.5 Test graceful degradation: solon-mem staging works when Clio is unavailable
- [x] 7.6 Confirm opencode/ files mirror claude/ files after all changes
