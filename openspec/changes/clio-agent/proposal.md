## Why

Solon's spec-driven design agent is tightly coupled to graphiti memory infrastructure -- roughly 50-60% of solon-spec is graphiti ceremony. Extracting memory into a standalone agent makes Solon leaner, makes memory services universally available, and cleanly separates design conversation from knowledge persistence.

The graphiti ecosystem already has battle-tested skills in the global toolkit (graphiti-normalizer, graphiti-ledger-insert, graphiti-enhancer). Rather than reimplement this logic, Clio is a lightweight agent-router that co-loads these skills and adds a friendly interface on top.

## What Changes

- Create a new agent "Clio" (Muse of history, recorder of deeds) as a lightweight router
- Clio co-loads existing graphiti-* skills: graphiti-normalizer, graphiti-ledger-insert, graphiti-ledger-status
- Create a new `graphiti-egress` skill for the 2-group search pattern (primary group + companion group)
- Clio routes intent to the right graphiti skill, manages group_id awareness, and applies a quality gate on ingress
- Clio operates independently -- Solon is not required. Any agent can dispatch to Clio.
- Generalize `graphiti-ledger-status` to remove Solon-specific language (move/adapt to global toolkit)

## Capabilities

### New Capabilities
- `clio-agent`: Lightweight agent-router for knowledge persistence and retrieval. Routes ingress, egress, status, and drain requests to graphiti-* skills. Manages group_id configuration. Orchestrates full egress pipeline: intent routing (4 patterns: repo-specific, cross-reference, broad, meta), query expansion via graphiti-entities, expired fact filtering, deduplication, history mode, and result handling. Applies quality gate on ingress (drop duplicates, drop trivial implementation details).
- `graphiti-egress`: Simplified raw search skill enforcing FalkorDB's 2-group minimum. Calls search_memory_facts and search_nodes with caller-provided group_ids. Returns raw, unfiltered results. No intelligence -- Clio handles intent routing, entity expansion, expired filtering, and result handling.
- `graphiti-entities`: Entity dictionary management using .graphiti/entities.yaml. Provides query expansion for egress (synonym/canonical mapping) and synonym lookup for ingress normalization.

### Modified Capabilities
- `graphiti-ledger-status`: Generalize to remove Solon-specific references. Make it usable from any agent context, not just Solon phases.

## Impact

- Memory services become available to any agent, not just Solon's spec ceremony
- Solon loses direct graphiti dependency (separate follow-up change)
- No reimplementation of existing graphiti skills -- Clio delegates to them
- Requires graphiti MCP server, Postgres, and FalkorDB for full functionality
- Purely additive -- existing functionality continues working
