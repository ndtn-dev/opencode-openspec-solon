## ADDED Requirements

### Requirement: Intent routing for ingress
Clio SHALL route ingress requests ("remember this", "persist this decision", or structured decision entries from other agents) through the ingress pipeline. The pipeline is: quality gate -> graphiti-ledger-insert -> graphiti-normalizer. Clio SHALL co-load graphiti-ledger-insert and graphiti-normalizer and call them inline (no sub-agent dispatch). Clio accepts two types of ingress: individual decision entries (with title, classification, context, etc.) and evolution summaries (narrative synthesis of a session's decisions). Both types follow the same pipeline.

#### Scenario: Route a decision entry for ingress
- **WHEN** Clio receives a decision entry with title, context, decision text, session ID, and group_id
- **THEN** Clio applies the quality gate, and if the entry passes, calls graphiti-ledger-insert followed by graphiti-normalizer

#### Scenario: Route an evolution summary for ingress
- **WHEN** Clio receives an evolution summary with spec name, session ID, group_id, and summary text
- **THEN** Clio routes it through the same ingress pipeline (quality gate -> graphiti-ledger-insert -> graphiti-normalizer)

#### Scenario: Route a natural language ingress request
- **WHEN** a user or agent says "remember that we chose SQLite because there's no daemon"
- **THEN** Clio extracts the decision content and routes it through the ingress pipeline with the configured group_id

### Requirement: Intent routing for egress
Clio SHALL route egress requests through a multi-step pipeline: intent detection -> group selection -> query expansion -> search -> filtering -> result handling. Clio determines the search intent and selects group_ids accordingly. Clio always includes ndtn_preferences as a companion group, which serves dual purpose: surfacing user preferences and forcing FalkorDB's multi-group decorator activation (required due to a driver bug with single-group searches). The repo-specific group_id is derived as `mem_{repo_name}` where repo_name is the basename of the git repository root with hyphens replaced by underscores (e.g., git root `opencode-openspec-solon` becomes `mem_opencode_openspec_solon`).

#### Scenario: Repo-specific search
- **WHEN** a user asks about this project's decisions, patterns, or architecture (e.g., "why did we choose SQLite?")
- **THEN** Clio searches with group_ids [mem_{repo_name}, ndtn_preferences]

#### Scenario: Cross-reference search
- **WHEN** a user's question bridges multiple projects or mentions another project by name (e.g., "how does the auth pattern in project-A compare to what we do here?")
- **THEN** Clio searches with group_ids [mem_{current_repo}, mem_{other_repo}, ndtn_preferences]

#### Scenario: Broad cross-project search
- **WHEN** a user asks about general conventions or patterns spanning all repos (e.g., "what's our standard env var convention?")
- **THEN** Clio searches with group_ids [mem, ndtn_preferences] where "mem" is the catch-all group

#### Scenario: Meta search
- **WHEN** a user asks about graphiti's own configuration (e.g., "what extraction model is running?")
- **THEN** Clio searches with group_ids [graphiti_meta, ndtn_preferences]

#### Scenario: Preference-weighted search
- **WHEN** a user's query signals preference importance (e.g., "what's my style for commit messages?")
- **THEN** Clio weights ndtn_preferences results higher in the response

### Requirement: Query expansion via graphiti-entities
Clio SHALL expand search terms using graphiti-entities before executing searches via graphiti-egress. For each expanded term, Clio runs a separate search and merges results. If graphiti-entities reports no dictionary available, Clio proceeds with the original search term.

#### Scenario: Expand and search
- **WHEN** a user searches for "graphiti-mcp" and graphiti-entities expands it to ["graphiti-mcp", "Graphiti MCP Server"]
- **THEN** Clio runs searches for both terms via graphiti-egress and merges the results

#### Scenario: No dictionary available
- **WHEN** graphiti-entities reports no dictionary
- **THEN** Clio proceeds with the original search term only

### Requirement: Expired fact filtering
Clio SHALL filter expired facts from search results before presenting them to the user. Expired facts are those whose validity period has passed (based on timestamps in the result metadata). Approximately 35% of raw search results may be expired. Filtered facts are not shown to the user unless history mode is active.

#### Scenario: Filter expired facts
- **WHEN** graphiti-egress returns raw results containing both current and expired facts
- **THEN** Clio removes expired facts from the response and only presents current facts

#### Scenario: History mode
- **WHEN** a user asks about evolution or changes ("how did X evolve?", "what changed about Y?")
- **THEN** Clio retains expired facts in a separate "Previously (superseded)" section instead of dropping them

### Requirement: Result deduplication
Clio SHALL deduplicate results when multiple searches return overlapping facts (e.g., from expanded terms or cross-reference queries). Duplicate facts (same content from same source) are merged into a single result.

#### Scenario: Deduplicate across expanded terms
- **WHEN** searches for "graphiti-mcp" and "Graphiti MCP Server" both return the same fact
- **THEN** Clio includes the fact only once in the results

### Requirement: Result handling
Clio SHALL handle search results naturally: incorporate found facts into responses, apply user preferences from ndtn_preferences to response style, surface contradictory facts for user resolution, and never mention empty or failed searches to the user.

#### Scenario: Results found
- **WHEN** Clio receives search results with matching facts
- **THEN** Clio incorporates them naturally into the response, citing sources where relevant

#### Scenario: No results
- **WHEN** Clio receives empty search results
- **THEN** Clio answers from its own knowledge without mentioning the empty search

#### Scenario: Contradictory facts
- **WHEN** two current facts contradict each other
- **THEN** Clio presents both and asks the user which applies

### Requirement: Intent routing for status
Clio SHALL route status requests ("check the ledger", "how's the memory system?") to graphiti-ledger-status. Clio SHALL pass the appropriate context (session ID if available, group_id) to graphiti-ledger-status.

#### Scenario: Route a status check
- **WHEN** a user or agent asks "check the ledger"
- **THEN** Clio invokes graphiti-ledger-status with the current context

### Requirement: Intent routing for drain
Clio SHALL route drain requests ("flush the queue", "drain pending") to graphiti-ledger-status's drain operation.

#### Scenario: Route a drain request
- **WHEN** a user or agent asks "flush the pending queue"
- **THEN** Clio invokes graphiti-ledger-status in drain mode

### Requirement: Quality gate on ingress
Clio SHALL apply a quality gate before persisting entries. The quality gate drops entries that are duplicates of existing decisions or trivial implementation details (e.g., formatting choices, naming conventions). Dropped entries are NOT persisted to the graph but MAY be recorded in the Postgres ledger with decision_status=dropped and drop_reason. All non-dropped entries proceed through the full pipeline.

#### Scenario: Drop a duplicate decision
- **WHEN** Clio receives a decision that is substantively identical to one already in the graph
- **THEN** Clio drops the entry with reason "Duplicate of existing decision" and does not call graphiti-normalizer

#### Scenario: Drop a trivial implementation detail
- **WHEN** Clio receives an entry like "use kebab-case for file names"
- **THEN** Clio drops the entry with reason "Trivial implementation detail"

#### Scenario: Non-dropped entry proceeds through pipeline
- **WHEN** Clio receives a decision that is not a duplicate and not trivial
- **THEN** the entry proceeds to graphiti-ledger-insert then graphiti-normalizer

### Requirement: Group ID management
Clio SHALL manage the group_id context for all operations. Clio determines the primary group_id from: (1) caller-provided group_id in the dispatch prompt, (2) .graphiti/config.yaml if it exists, (3) asking the caller if neither source provides it. Clio also knows the companion group(s) (e.g., ndtn_preferences) for egress operations. Clio is the single source of truth for which groups to read from and write to.

#### Scenario: Group ID from caller
- **WHEN** a caller dispatches to Clio with an explicit group_id
- **THEN** Clio uses the provided group_id for the current operation

#### Scenario: Group ID from config
- **WHEN** a caller does not provide group_id and .graphiti/config.yaml contains a default group_id
- **THEN** Clio uses the configured default group_id

#### Scenario: Group ID not available
- **WHEN** a caller does not provide group_id and no .graphiti/config.yaml exists
- **THEN** Clio returns a structured response asking the caller for a group_id before proceeding

#### Scenario: Companion groups for egress
- **WHEN** Clio routes an egress query to graphiti-egress
- **THEN** Clio provides both the primary group_id and companion group(s) from its configuration

### Requirement: Communicate requirements to callers
Clio SHALL return structured responses when it cannot proceed due to missing information. The response MUST specify what information is needed and why. This allows calling agents to provide the missing information or surface the request to the user.

#### Scenario: Missing group_id
- **WHEN** Clio cannot determine the group_id from any source
- **THEN** Clio returns a response explaining that group_id is required, how to provide it (dispatch parameter or .graphiti/config.yaml), and does not proceed with the operation

### Requirement: Co-load graphiti skills inline
Clio SHALL co-load graphiti-normalizer, graphiti-ledger-insert, graphiti-ledger-status, graphiti-egress, and graphiti-entities as inline skills. Clio SHALL NOT dispatch sub-agents for these skills (depth guard). All graphiti skill calls happen within Clio's agent context.

#### Scenario: Skills loaded inline
- **WHEN** Clio processes an ingress request
- **THEN** graphiti-ledger-insert and graphiti-normalizer are called inline within Clio's context, not as sub-agent dispatches
