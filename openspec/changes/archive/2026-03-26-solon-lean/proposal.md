## Why

Solon's spec-driven design workflow is tightly coupled to graphiti memory infrastructure -- roughly 50-60% of solon-spec is graphiti ceremony (ledger management, ingestion pipelines, FalkorDB verification). This coupling makes Solon too complex for weaker models, forces adoption of the graphiti stack, and entangles design conversation with knowledge persistence. Extracting memory concerns into a `solon-mem` adapter that optionally dispatches to Clio (the memory agent from the prerequisite `clio-agent` change) makes Solon dramatically leaner, model-agnostic, and able to function fully without any memory infrastructure.

## What Changes

- **New `solon-mem` skill**: Adapter layer between Solon and Clio. Classifies decisions as "key" or "routine" (replacing Big/Medium/Small), writes verbose entries to `.solon/staging/{spec-name}.md`, dispatches to Clio per decision when available, and produces an evolution summary at Phase 5.
- **Refactor `solon-spec` skill**: Drop from 7 phases (~220 lines) to 6 phases (~100-120 lines). Remove all graphiti ceremony -- micro-ingress, three-tier classification, ingress checkpoint phase, ledger verification, execute_sql calls. Replace with solon-mem calls for decision staging.
- **Refactor `solon.md` agent definition**: Remove `<LedgerAutoVerify>` section, remove `.graphiti/` from `<PathRestrictions>`, simplify `<DoubleWriting>` to remove ingress checkpoint language.
- **Remove `solon-ingress` from Solon's skill set**: Clio handles ingress via graphiti-* skills.
- **Remove `graphiti-ledger-status` from Solon's skill set**: Clio co-loads graphiti-ledger-status directly.
- **Update `solon-eval`**: Adjust test case expectations for the new phase structure; remove tier and micro-ingress references.

## Capabilities

### New Capabilities
- `solon-mem`: Decision classification (key/routine), local staging to `.solon/staging/`, optional Clio dispatch, and Phase 5 evolution summary generation.

### Modified Capabilities
- `solon-spec-lean`: Refactored 6-phase spec workflow with zero graphiti coupling. Phases consolidated (old Phase 6+7 merge), Phase 5 rewritten from ingress checkpoint to finalize, all graphiti ceremony removed from Phases 1, 2, and 4.
- `solon-agent-lean`: Refactored agent definition removing LedgerAutoVerify, .graphiti/ path restrictions, and ingress checkpoint confirmation language.

## Impact

- solon-spec drops from ~220 lines to ~100-120 lines; phases from 7 to 6
- Zero graphiti coupling remains in Solon -- Solon works fully without Clio/graphiti
- `solon-ingress` and `graphiti-ledger-status` skills removed from Solon's skill set
- No changes to solon-reconcile, solon-handoff, solon-debug
- Phase 0 routing table unchanged
- Prerequisite: `clio-agent` change must be implemented first; solon-mem dispatches fail silently (graceful degradation) if Clio is unavailable
- Staging file `.solon/staging/` introduces a new local persistence path
