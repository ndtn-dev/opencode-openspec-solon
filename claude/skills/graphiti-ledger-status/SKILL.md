---
name: graphiti-ledger-status
description: Drains pending JSON fallbacks, verifies episodes in FalkorDB, and reports ledger status. Runs inline when co-loaded by an agent, or dispatches to a background Agent when standalone.
---

# Graphiti Ledger Status

## When Loaded

Load this skill when ledger health must be checked or reconciled:
- Agent-initiated checks (e.g., Clio status routing, periodic verification)
- Manual requests like "check the ledger", "drain the queue", or "verify episodes"

## Delegation Pattern

Context-aware delegation:

- **Co-loaded by another agent** (e.g., Clio): Run inline within the calling agent's context. The co-loading agent controls execution.
- **Loaded standalone**: Dispatch to a background Agent to prevent context bloat.

When dispatching standalone:
"CHECK LEDGER STATUS: [drain|verify|report|all] for session {session_id}"

The agent executes one operation (`drain`, `verify`, `report`) or full sequence (`all`).

## Operations

### Drain

1. Find pending fallbacks:
   - `glob(".graphiti/ingress/pending/*.json")`
2. For each file:
   - `Read` JSON payload
    - Insert with Postgres MCP using `execute_sql` (parameter name is `sql`, not `query`):

```python
execute_sql(sql="""
INSERT INTO episodes (
  id, name, episode_body, group_id, source, source_description,
  agent, session_id, repo, model, phase, tier, decision_status, created_at
)
VALUES (
  '{id}', '{name}', '{body}', '{group_id}', '{source}', '{source_description}',
  '{agent}', '{session_id}', '{repo}', '{model}', '{phase}', '{tier}', '{decision_status}', now()
)
ON CONFLICT (id) DO NOTHING;
""")
```

3. If insert succeeds, delete pending file.
4. Output:
   - `Drained N pending -> M inserted, K failed`

### Verify

1. Query unverified rows:

```python
execute_sql(sql="""
SELECT id, name, group_id, episode_body, created_at
FROM episodes
WHERE verified_at IS NULL;
""")
```

2. For each row:
   - Compute age from `created_at`
   - If age < 30 minutes: skip as too recent
   - Check FalkorDB with 2-group egress pattern:

```python
search_memory_facts(
  query="{episode name}",
  group_ids=["{group_id}", "ndtn_preferences"],
  max_facts=5
)
```

3. If found in FalkorDB, retrieve the episode's `created_at` timestamp from FalkorDB:

```python
episodes = get_episodes(group_ids=["{group_id}"], max_episodes=50)
falkordb_episode = next((e for e in episodes if e.name == "{episode name}"), None)
falkordb_created_at = falkordb_episode.created_at if falkordb_episode else None
```

   Then mark ingressed and verified using two distinct timestamps:
   - `ingressed_at` = when FalkorDB processed the episode (from FalkorDB's `created_at`)
   - `verified_at` = when this verification confirmed its existence (`now()`)

```python
execute_sql(sql="""
UPDATE episodes
SET ingressed_at = '{falkordb_created_at}', verified_at = now()
WHERE id = '{uuid}';
""")
```

4. If not found and age > 24 hours, mark failed:

```python
execute_sql(sql="""
UPDATE episodes
SET failed_at = now(),
    failure_reason = 'not found in FalkorDB after 24h verification check'
WHERE id = '{uuid}';
""")
```

5. If not found and age <= 24 hours: keep pending for later verification.

### Report

Use session-scoped summary query:

```python
execute_sql(sql="""
SELECT
  count(*) as total,
  count(normalized_at) as normalized,
  count(ingressed_at) as ingressed,
  count(verified_at) as verified,
  count(failed_at) as failed
FROM episodes
WHERE session_id = '{session_id}';
""")
```

Report format:

```text
Ledger Status (session: {session_id}):
  Total: N | Normalized: M | Ingressed: I | Verified: V | Failed: F
  Unverified: [{uuid1}] "name1" (age), [{uuid2}] "name2" (age)...
```

### All

Run in strict order:
1. `drain`
2. `verify`
3. `report`

## Reasonable Time Policy

- Do not auto-fail episodes younger than 30 minutes.
- FalkorDB ingestion is asynchronous; local models can process slowly.
- Only mark as failed after 24 hours without verification evidence.
- Until 24 hours, keep episode in retryable unverified state.

## Guardrails

- Do not call `add_memory()` from this skill.
- Do not mutate episode content fields.
- Update status/timestamps only (`ingressed_at`, `verified_at`, `failed_at`, `failure_reason`).
- When standalone: keep main-agent context thin by dispatching to a background agent.
- When co-loaded: run inline; the calling agent manages its own context.
