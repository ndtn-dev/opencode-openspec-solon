## Context

Solon is a spec-driven design agent with a 7-phase workflow defined in `solon-spec`. Currently, five of seven phases contain graphiti coupling: Phase 1 dispatches `graphiti-ledger-status` for housekeeping, Phase 2 uses a three-tier (Big/Medium/Small) classification with micro-ingress via `add_memory` and `graphiti-ledger-insert`, Phase 4 references "candidate overrides that supersede prior decisions" in graphiti terms, Phase 5 is entirely a graphiti ingress checkpoint (ledger verification, batch ingestion dispatch, execute_sql calls), and Phase 7 dispatches another `graphiti-ledger-status` pass.

The prerequisite `clio-agent` change creates Clio, a lightweight agent-router that co-loads existing graphiti-* skills (graphiti-normalizer, graphiti-ledger-insert, graphiti-ledger-status, graphiti-egress) and routes intent to the right skill. This change is the consumer side: it refactors Solon to stop calling graphiti directly and instead use a new `solon-mem` adapter skill that stages decisions locally and optionally dispatches to Clio.

Current Solon files affected:
- `claude/agent/solon.md` -- agent definition (~63 lines)
- `claude/skills/solon-spec/SKILL.md` -- core workflow (~222 lines)
- `claude/skills/solon-eval/SKILL.md` -- routing evaluation harness (~103 lines)
- `claude/skills/solon-ingress/SKILL.md` -- removed from Solon (Clio handles ingress via graphiti-* skills)
- `claude/skills/graphiti-ledger-status/SKILL.md` -- removed from Solon (Clio co-loads graphiti-ledger-status directly)

## Goals / Non-Goals

**Goals:**
- Remove all graphiti coupling from Solon's agent definition and solon-spec skill
- Introduce solon-mem as the single adapter between Solon and Clio
- Solon functions fully without Clio/graphiti via local staging files
- Reduce solon-spec from ~220 lines to ~100-120 lines and from 7 phases to 6
- Preserve all design conversation quality (exploration, brainstorm, gap analysis, assumption tracking)

**Non-Goals:**
- Changing Clio's interface or skills (those are defined in the clio-agent change)
- Modifying solon-reconcile, solon-handoff, or solon-debug
- Changing Phase 0 routing logic
- Building a new classification taxonomy beyond two tiers (key/routine)
- Changing the graphiti MCP server, FalkorDB schema, or Postgres schema

## Decisions

### Two-tier classification (key/routine) over three-tier (Big/Medium/Small)
The old three-tier system added complexity without meaningfully different handling -- Medium decisions were treated the same as Small in practice (both batch-ingested at Phase 5). Two tiers exist for solon-mem's staging file verbosity and evolution tracking. Clio treats all non-dropped entries equally through a single pipeline (quality gate -> ledger-insert -> normalizer). Classification logic lives in solon-mem, not in Clio.

Alternative considered: Keep three tiers and map them to Clio's two-tier gate. Rejected because the mapping adds a pointless translation layer and preserves unnecessary complexity in solon-spec.

### Dispatch per decision over batching at Phase 5
solon-mem dispatches each decision to Clio as it is staged, not in a batch at the end. This gives Clio real-time ingestion, reduces end-of-session latency, and means partial or interrupted sessions still persist their decisions. Phase 5 sends a complementary evolution summary -- a synthesis of the session's decisions -- which is a different knowledge type (narrative vs facts).

Alternative considered: Batch all decisions at Phase 5. Rejected because it creates a single point of failure, delays persistence, and loses decisions from interrupted sessions.

### Local staging file as primary record over graphiti-only persistence
solon-mem always writes to `.solon/staging/{spec-name}.md` regardless of Clio availability. The staging file is verbose: raw conversation excerpts, quoted user statements, full rationale, Claude session ID on every entry. This means Solon works fully without any memory infrastructure, and the staging file serves as a text-based audit trail.

Alternative considered: Only dispatch to Clio with no local record. Rejected because it creates hard dependency on Clio/graphiti and loses the human-readable audit trail.

### Merge old Phase 6 + Phase 7 into new Phase 6 over keeping 7 phases
Old Phase 7 (Verify and Nudge) existed to run a final graphiti-ledger-status pass and nudge toward handoff. Without graphiti verification, the nudge folds naturally into Phase 6 (Write Artifacts) as a post-write step. The new Phase 5 (Finalize) handles the staging file summary and Clio dispatch that replaces the old verification.

Alternative considered: Keep 7 phases with Phase 7 as pure "Nudge." Rejected because a single-purpose nudge phase is not worth the cognitive overhead of an extra phase.

### Staging file format: markdown ledger with decision IDs
Decisions are numbered sequentially (D-001, D-002, ...) within each staging file. When a decision is superseded, the new entry references the old one and the old entry is annotated with `[SUPERSEDED by D-NNN]`. This provides clear lineage without requiring a database.

Alternative considered: JSON-structured staging files. Rejected because markdown is human-readable, diffable, and doesn't require parsing tools for inspection.

### opencode/ parity with claude/
The `opencode/` directory is a parallel port of Solon for OpenCode (a different AI coding tool). It mirrors the same agent definition (`opencode/agent/solon.md`), skill files (`opencode/skills/solon-spec/SKILL.md`, etc.), and directory structure as `claude/`. All changes made to `claude/` files in this change MUST be mirrored to `opencode/` to maintain parity. Skills removed from `claude/` (solon-ingress, graphiti-ledger-status) MUST also be removed from `opencode/`. The new solon-mem skill MUST be created under `opencode/skills/solon-mem/` as well.

Alternative considered: Deprecate `opencode/` and maintain only `claude/`. Rejected because both deployments are actively maintained and divergence would create drift between tool-specific configurations.

## Risks / Trade-offs

**[Clio unavailability]** If Clio is not available, solon-mem dispatch calls fail silently. Mitigation: the local staging file always exists as the durable record. Phase 5 evolution summary is still produced (written to staging file) even if it cannot be shipped to Clio.

**[Staging file growth]** Long spec sessions could produce large staging files with many verbose entries. Mitigation: staging files are scoped per spec name with session-aware archival. When a new session begins and a staging file from a prior session exists, the old file is archived (renamed with the old session ID as suffix) and a fresh file is created. Archived files can be cleaned up after implementation. The verbosity is intentional -- raw data preservation is more valuable than brevity.

**[Classification accuracy]** The two-tier key/routine system is simpler than the old three-tier system. Risk that architecturally significant decisions get classified as routine and miss enhancement in Clio. Mitigation: Phase 5 evolution summary captures the full picture regardless of individual classification. Under-classification results in less enhancement, not lost data.

**[solon-eval test drift]** Test 4 (Explicit) expectations currently verify that Solon "tracks assumptions" which implicitly tested the three-tier system. Mitigation: update test expectations to verify solon-mem staging behavior instead of tier/micro-ingress behavior.

**[Prerequisite ordering]** This change depends on the clio-agent change being implemented first. If applied before clio-agent, solon-mem dispatch calls have no target. Mitigation: solon-mem is designed for graceful degradation -- Clio dispatch is always optional. The staging file functions independently.
