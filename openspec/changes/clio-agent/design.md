## Context

The graphiti ecosystem has three battle-tested skills in the global toolkit:
- `graphiti-normalizer`: 6-step pipeline (entity dictionary, synonym replacement, sentence restructuring, entity discovery, extraction instructions, add_memory call)
- `graphiti-ledger-insert`: Postgres ledger writes (UUID generation, INSERT RETURNING id, JSON fallback to .graphiti/ingress/pending/)
- `graphiti-enhancer`: Content expansion with conversation context (may be deprecated -- see decisions)

Additionally, `graphiti-ledger-status` exists in the Solon project with drain/verify/report operations but contains Solon-specific language.

Clio is a new agent that acts as a friendly router on top of these skills, similar to how Solon uses Phase 0 intent routing. Callers talk to Clio; Clio delegates to the right graphiti skill.

## Goals / Non-Goals

**Goals:**
- Define Clio as a lightweight agent-router with co-loaded graphiti skills
- Create graphiti-egress for the 2-group search pattern
- Clio manages group_id awareness (primary + companion groups)
- Quality gate on ingress (drop duplicates and trivial entries)
- Any agent can dispatch to Clio

**Non-Goals:**
- Reimplementing normalizer, ledger-insert, or enhancer logic inside Clio
- Refactoring Solon (separate follow-up change: solon-lean)
- Building the solon-mem adapter (separate follow-up change)
- Changing the graphiti MCP server or FalkorDB schema

## Decisions

### Agent-router pattern over skill-per-capability
Clio routes requests to existing graphiti-* skills rather than having its own clio-ingress, clio-status, clio-search, clio-drain skills. This avoids reimplementing logic that already exists and keeps Clio small (~60-80 lines). The graphiti-* skills are the real implementation; Clio is the friendly face.

Alternative considered: Four separate Clio skills wrapping graphiti skills. Rejected because three of four would be thin passthroughs adding indirection without value.

### Quality gate inline in agent definition over separate skill
The quality gate (drop duplicates, drop trivial implementation details) is simple enough to live in Clio's agent instructions. It does not need its own skill file. Drop reasons: "Duplicate of existing decision", "Trivial implementation detail". Entries that pass the gate proceed to graphiti-ledger-insert then graphiti-normalizer.

Alternative considered: Separate clio-quality-gate skill. Rejected because the gate is ~5 lines of logic (check two drop conditions) and doesn't warrant its own skill.

### Drop the enhancement pass
The graphiti-enhancer skill was originally needed because solon-ingress received terse input (e.g., "use SQLite" with no context). In the new architecture, solon-mem writes verbose staging entries with full conversation excerpts. The input to Clio is already rich, making enhancement redundant. graphiti-enhancer remains in the toolkit for other use cases but Clio does not co-load it.

Alternative considered: Keep enhancement for key decisions. Rejected because solon-mem's verbose capture already provides the context that enhancement was adding.

### Single pipeline over branching key/routine paths
All entries follow the same pipeline: quality gate -> graphiti-ledger-insert -> graphiti-normalizer. No branching based on classification. The two-tier classification (key/routine) is solon-mem's concern for the staging file, not Clio's concern for persistence. Clio treats all non-dropped entries equally.

Alternative considered: Different pipeline paths for key vs routine. Rejected because without the enhancement pass, there is no behavioral difference between the paths.

### graphiti-egress encapsulates the 2-group search pattern
Search always needs the primary group_id plus companion group(s) (e.g., ndtn_preferences). This pattern is currently hardcoded in graphiti-ledger-status verify. A dedicated graphiti-egress skill encapsulates it so callers don't need to know about companion groups. Clio provides the group_id context; graphiti-egress handles the multi-group query.

Alternative considered: Callers pass group_ids directly to graphiti MCP tools. Rejected because it leaks the companion group implementation detail to every caller.

### Clio manages group_id configuration
Clio knows the primary group_id and companion group(s) for the current context. This can come from:
1. Caller-provided group_id in the dispatch prompt
2. A configuration file (.graphiti/config.yaml) if it exists
3. Clio asks the caller if neither source provides it

This means callers like solon-mem must either pass group_id or ensure .graphiti/config.yaml exists. Clio is the single source of truth for "which groups do we read from and write to."

### Clio communicates requirements to callers
When Clio needs information from the calling agent (e.g., group_id is not configured and not provided), Clio returns a structured response explaining what it needs rather than silently failing. This allows the calling agent to provide the missing information or surface the request to the user.

### Egress pipeline: Clio orchestrates, graphiti-* skills execute
Clio handles the intelligence (intent detection, group selection, expired filtering, deduplication, result handling). graphiti-egress is simplified to raw search with 2-group enforcement. graphiti-entities handles dictionary-based query expansion. This replaces the existing monolithic graphiti-egress that embedded all logic including a Gemini subagent for expired fact filtering.

Alternative considered: Keep the existing monolithic graphiti-egress with its Gemini retriever subagent. Rejected because (a) the subagent conflicts with Clio's depth guard, (b) Clio can do expired filtering inline (it's a timestamp check), and (c) the decomposition is cleaner.

### Eliminate the Gemini retriever subagent
The existing graphiti-egress delegates search to a google/gemini-2.5-flash subagent for expired fact filtering and deduplication. Clio absorbs these responsibilities inline. Expired fact filtering is a timestamp comparison (~35% of results are expired). Deduplication is straightforward merging. Neither requires a separate model. This also avoids the depth guard conflict (Clio as sub-agent spawning another sub-agent).

Alternative considered: Keep the retriever as a Clio-internal subagent. Rejected because it violates the depth guard and the filtering logic is simple enough for Clio to handle inline.

### FalkorDB 2-group bug documented in both layers
The FalkorDB driver bug (single-group searches use wrong database context) is documented in both graphiti-egress (enforces 2-group minimum, rejects single-group) and Clio (always includes ndtn_preferences as companion). Belt-and-suspenders approach ensures the bug cannot be triggered regardless of which layer a future caller interacts with.

## Risks / Trade-offs

**[graphiti-* skill availability]** Clio depends on graphiti-normalizer, graphiti-ledger-insert, and graphiti-ledger-status being available as co-loadable skills. If any are missing, Clio cannot function. Mitigation: these are in the global toolkit and are stable.

**[graphiti-ledger-status generalization]** The current skill has Solon-specific language that needs to be removed. This modifies an existing global skill. Mitigation: the generalization is removing references, not changing behavior.

**[group_id discovery]** If no group_id is configured or provided, Clio must ask. This adds a round-trip to the first interaction. Mitigation: .graphiti/config.yaml can provide a default so this only happens on first use.
