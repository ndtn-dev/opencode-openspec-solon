# Decision Ledger: solon-mem
Session: session-2026-03-26T00:00:00 | Started: 2026-03-26

## D-001: Explicit loop structure for multi-decision staging
- **Phase**: 2
- **Classification**: key
- **Session**: session-2026-03-26T00:00:00
- **Context**:
  > User reported "solon-mem stages only 1 decision per invocation — despite 'Process ALL' instruction, it writes D-001 and returns. The remaining confirmed decisions get dropped. This is the main blocker."
  > Analysis showed the 6-step linear checklist allows the model to complete all steps with a single decision. The word "ALL" on step 5 fights against the structural signal of "you've completed steps 1 through 6, you're done."
  > The fix restructures into setup/iteration/completion phases with a completion verification step that forces a count check.
- **Decision**: Restructure the "Local staging file persistence" requirement from a linear step list to three explicit phases (setup, iteration, completion). Add "Process all decisions in a single invocation" scenario requiring all N entries written before proceeding. Add "Completion verification" scenario requiring count match and "Staged N decisions (D-001 through D-NNN)" report.
- **Status**: active

## D-002: Batch Clio dispatch per invocation
- **Phase**: 2
- **Classification**: key
- **Session**: session-2026-03-26T00:00:00
- **Context**:
  > User asked "what does this mean in terms of ingress into graphiti?" — analysis of clio-graphiti-agent showed Clio's ingress pipeline is strictly single-item, single-call. One dispatch = one UUID = one ledger insert = one normalization = one add_memory. Multi-decision payloads fused into a single episode, destroying per-decision granularity in the knowledge graph.
  > Evaluated Options A (N dispatches — expensive, N agent spawns), B (batch router in Clio — 1 spawn, sub-skills unchanged), C (new batch skill — duplication risk). User chose B.
  > User raised bloat concern: "Im just worried with option B that clio is getting too bloated." Analysis showed batch mode adds ~15 lines to Clio's router (a conditional branch, not a new capability) vs Option C duplicating quality gate, pipeline orchestration, group_id resolution, and graceful degradation.
  > Clio handoff written to .solon/handoffs/clio-batch-ingress.md.
- **Decision**: Replace "Clio dispatch per decision" requirement with "Clio batch dispatch per invocation." solon-mem sends one structured batch payload (spec name, session ID, group_id, numbered decisions list) per invocation. Remove "No batching" scenario. Add "Batch dispatch", "Batch payload structure", and "One dispatch per invocation" scenarios. Depends on Clio batch ingress (cross-repo handoff).
- **Status**: active

## D-003: Sharpen classification criteria with concrete examples and ambiguity default
- **Phase**: 2
- **Classification**: key
- **Session**: session-2026-03-26T00:00:00
- **Context**:
  > User reported "solon-mem classified 'hierarchical event filter with wildcards' as 'routine' when it's architectural (should be 'key')."
  > Analysis showed the "architectural" definition — "affects system structure" — is too vague. The model interprets "system structure" narrowly (e.g., only database schemas, service boundaries) and misses design decisions about event models, data flow patterns, and API contracts.
- **Decision**: Expand "architectural" definition to explicitly include data flow, API boundaries, event models, and component relationships. Add concrete examples to scenarios (e.g., "hierarchical event filter with wildcards", "structured payload format for Clio dispatch"). Add new "data-flow or API boundary" scenario. Add "Default ambiguous classification to key" scenario as a safety net for ambiguous cases.
- **Status**: active
