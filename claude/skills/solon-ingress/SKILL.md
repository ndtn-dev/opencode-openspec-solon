---
name: solon-ingress
description: High-quality memory ingestion for Solon decisions with quality gate and graphiti utilities. Dispatched by solon-spec Phase 5.
---

# Solon Ingress

## Role

Receives pre-classified decisions from solon-spec Phase 5 batch ingestion.

Co-uses: `graphiti-enhancer`, `graphiti-ledger-insert`, `graphiti-normalizer`.
All three are called **inline** — do NOT dispatch sub-agents (depth guard).

## Input Contract

Receives a prompt with:

- **Decisions**: List of items, each with: phase, tier (Big/Medium/Small/null), decision_status, classification, content, superseded_by (if applicable)
- **group_id**: Target graph group (e.g., `mem_bricknet`)
- **source_description template**: `platform:claude-code agent:solon session:{id} repo:{repo} model:{model}`
- **Session metadata**: agent name, session ID, repo name, extraction model

## Enhancement Binary Gate

| Condition | Action |
|-----------|--------|
| Solon tier Medium or Big | SKIP — already detailed by Opus |
| Solon tier Small + assumption | RUN enhancer `mode=assumption` |
| Non-Solon (tier=null) | RUN enhancer `mode=default` |
| test-result classification | RUN enhancer `mode=default` |

When the enhancer runs, instruct it to also evaluate quality. Request a structured response:
- `status: enhanced` with expanded body
- `status: dropped` with `drop_reason`

Valid drop reasons: "Duplicate of existing decision", "Too vague to expand meaningfully", "Trivial implementation detail".

Medium/Big decisions bypass the quality gate entirely — they always proceed.

## Quality Gate

| Enhancer Status | Action |
|-----------------|--------|
| `enhanced` | Proceed: ledger insert -> normalization -> add_memory |
| `dropped` | Ledger-only: INSERT with `decision_status=dropped` + `drop_reason`. No add_memory. Include in batch summary. |

## Pipeline (Per Decision)

For each decision that passes the quality gate:

**1. Enhance** — Apply binary gate. Use enhanced body if enhancer ran, otherwise original content.

**2. Ledger Insert** — Via `graphiti-ledger-insert`:
- `INSERT ... RETURNING id` with Solon metadata: phase, tier, decision_status, superseded_by
- Capture UUID. Fallback: `uuidgen` + pending JSON if Postgres unreachable.

**3. Build source_description** — Append GUID to template:
```
platform:claude-code agent:solon session:{id} repo:{repo} model:{model} GUID:{uuid}
```

**4. Normalize and Ingest** — Call `graphiti-normalizer` **inline** (not via sub-agent).
Pass: classification, content, group_id, source_description.
The normalizer runs its 6-step pipeline and calls `add_memory()` as its final step.
Do NOT call `add_memory()` directly.

**5. Update normalized_at** — Via `graphiti-ledger-insert`:
```sql
UPDATE episodes SET normalized_at = now() WHERE id = '{uuid}';
```

## All-Tier Ingestion (Decision #19)

ALL tiers (Big, Medium, Small) get graph ingestion via add_memory AND ledger records. The Postgres ledger is an audit/durability layer, not a replacement for graph ingestion.

Do NOT set `ingressed_at`. It is set later by `graphiti-ledger-status verify` using FalkorDB's `created_at` (Decision #22). The gap between add_memory() and verification can be hours or days — expected by design.

## Big Decision Skip (Phase 5 Batch)

Phase 2 Big decisions may already be ingested via micro-ingress. At Phase 5 batch:
- Check if a ledger record exists for the decision (by content match or decision ID)
- Already ingested -> skip re-ingestion, verify ledger record is intact
- Not yet ingested -> proceed with normal pipeline

## Batch Summary

Return to calling agent:

```
Ingested: {n} | Dropped: {n} | Skipped: {n} | Errors: {n}

Dropped:
- "{title}": {drop_reason}

Errors (if any):
- "{title}": {error}
```

## Do NOT

- Call `add_memory()` directly — normalizer handles that
- Spawn sub-agents — all co-loaded skills run inline
- Include Phase 0 routing or spec-writing logic
- Set `ingressed_at` — ledger-status verify handles that later
