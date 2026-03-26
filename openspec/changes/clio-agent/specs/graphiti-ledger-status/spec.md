## MODIFIED Requirements

### Requirement: Agent-agnostic language
graphiti-ledger-status SHALL use agent-agnostic language throughout. References to "Solon phase 5", "Solon phase 7", "solon-spec", or any Solon-specific workflow MUST be replaced with generic terms (e.g., "caller", "invoking agent"). The skill MUST be usable from any agent context, not just Solon.

#### Scenario: No Solon-specific references
- **WHEN** graphiti-ledger-status is loaded by any agent (Clio, Solon, or otherwise)
- **THEN** the skill instructions contain no references to Solon phases, solon-spec, or Solon-specific workflows

### Requirement: Context-aware delegation pattern
graphiti-ledger-status SHALL support both inline execution (when co-loaded by an agent like Clio) and background Agent delegation (when loaded standalone). The current "Always dispatch to a background Agent" instruction MUST be changed to: dispatch to a background Agent when loaded standalone; run inline when co-loaded by another agent. The co-loading agent controls the execution context.

#### Scenario: Inline execution when co-loaded
- **WHEN** graphiti-ledger-status is co-loaded by Clio and invoked for a status check
- **THEN** the operations run inline within Clio's agent context without dispatching a sub-agent

#### Scenario: Background delegation when standalone
- **WHEN** graphiti-ledger-status is loaded directly (not co-loaded by another agent)
- **THEN** operations are dispatched to a background Agent to prevent context bloat

### Requirement: Preserve verification mechanics
graphiti-ledger-status SHALL preserve the existing verification mechanics: query unverified rows from Postgres, check FalkorDB via search_memory_facts with the 2-group egress pattern (primary group_id + companion group), retrieve FalkorDB timestamps via get_episodes, and update ingressed_at and verified_at with distinct semantics. The Reasonable Time Policy (skip < 30 minutes, retry 30min-24h, fail > 24 hours) MUST be preserved.

#### Scenario: Verification with Reasonable Time Policy
- **WHEN** graphiti-ledger-status verifies episodes and finds an unverified episode created 15 minutes ago
- **THEN** the episode is skipped as too recent (not marked as failed)

#### Scenario: Verification marks stale episodes as failed
- **WHEN** graphiti-ledger-status verifies episodes and finds an unverified episode created 26 hours ago with no FalkorDB match
- **THEN** the episode is marked as failed with failure_reason

### Requirement: Preserve guardrails
graphiti-ledger-status SHALL NOT call add_memory(), mutate episode content fields, or spawn sub-sub-agents. It SHALL only update status/timestamp fields (ingressed_at, verified_at, failed_at, failure_reason).

#### Scenario: No content mutation during verification
- **WHEN** graphiti-ledger-status processes an episode during verification
- **THEN** only timestamp and status fields are updated; episode_body and other content fields are not modified
