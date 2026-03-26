# Decision Ledger: clio-agent
Session: explore-2026-03-25 | Started: 2026-03-25

## D-001: Extract memory into standalone agent
- **Phase**: 2 | **Classification**: key
- **Session**: explore-2026-03-25
- **Context**:
  User wanted to decouple Solon from graphiti. ~50-60% of solon-spec is graphiti ceremony.
  Explored three patterns: Push (Solon emits events), Pull (memory agent reads artifacts),
  Explicit (user invokes directly).
  > "I want to make something easier and more natural to type than 'graphiti ingress'"
  > "I also want to make solon more lean. that way it has a chance of being used with weaker models"
- **Decision**: Create standalone memory agent (later named Clio) using Push pattern (Pattern A)

## D-002: Name the agent Clio
- **Phase**: 2 | **Classification**: routine
- **Session**: explore-2026-03-25
- **Context**:
  > "I want to name the mem agent - Clio -- Muse of history, the recorder of deeds"
- **Decision**: Agent named Clio after the Greek Muse of history

## D-003: Two-tier classification replaces three-tier
- **Phase**: 2 | **Classification**: key
- **Session**: explore-2026-03-25
- **Context**:
  Discussed whether Big/Medium/Small was still needed. Medium decisions were treated same as
  Small in practice. The tier system served two purposes: conversation flow and ingestion priority.
  With memory extracted, ingestion priority goes away.
  > "Im not sure that I need a big/medium small anymore <- that might have been overkill"
- **Decision**: Two tiers (key/routine) replace Big/Medium/Small. Classification lives in solon-mem.
- **Supersedes**: D-001 (originally assumed three tiers would carry over)

## D-004: Dispatch per decision, not batched
- **Phase**: 2 | **Classification**: key
- **Session**: explore-2026-03-25
- **Context**:
  Explored whether decisions should be batched at Phase 5 or dispatched individually. User
  wanted simplicity. Dispatching per decision means partial sessions still persist. Phase 5
  sends a complementary evolution summary.
  > "Honestly I think if its clean enough we can just have solon route to mem-graphiti anytime it adds to the staging artifact"
- **Decision**: solon-mem dispatches to Clio on every decision write. Phase 5 sends evolution summary separately.

## D-005: Drop enhancement pass entirely
- **Phase**: 2 | **Classification**: key
- **Session**: explore-2026-03-25
- **Context**:
  Enhancement existed to compensate for terse input ("use SQLite" with no context). solon-mem
  now writes verbose entries with raw conversation excerpts. Input is already rich.
  Explored three options: A (drop both gate and enhance), B (keep gate, drop enhance),
  C (hybrid gate-enhance-gate). User chose B.
  > "Lets assess the whole quality gate thing...is this overcomplicating things?"
  > "Sure Im okay with that" (re: Option B)
- **Decision**: Drop enhancement pass. Keep quality gate only (drop duplicates + trivial). Single pipeline for all entries.

## D-006: Clio as agent-router, not skill set [SUPERSEDED by D-008]
- **Phase**: 2 | **Classification**: key
- **Session**: explore-2026-03-25
- **Context**:
  Originally designed with 4 separate Clio skills (clio-ingress, clio-status, clio-search, clio-drain).
  User questioned whether Clio should just be an agent that knows graphiti, like Solon's intent gate.
  > "hmm is clio small enough clio can just be an agent that know how to do all of the graphiti things?"
- **Decision**: Clio is a lightweight agent-router co-loading existing graphiti-* skills.
- **Status**: superseded

## D-007: Two-layer architecture (Clio + graphiti-*)
- **Phase**: 2 | **Classification**: key
- **Session**: explore-2026-03-25
- **Context**:
  User realized that if graphiti-* skills handle the plumbing, Clio doesn't need to reimplement
  anything. Clio is the friendly face; graphiti-* skills are the implementation.
  > "should I make graphiti-layer have something for the ledger-status so clio doesn't need to access the ledger directly?"
  > "also same concept with drain? But then almost all of them can be handed to graphiti directly then..."
- **Decision**: Two layers. Clio orchestrates. graphiti-normalizer, graphiti-ledger-insert, graphiti-ledger-status, graphiti-egress, graphiti-entities are the plumbing.

## D-008: Full egress pipeline in Clio
- **Phase**: 2 | **Classification**: key
- **Session**: explore-2026-03-25
- **Context**:
  Discovered existing graphiti-egress has Gemini retriever subagent, expired fact filtering,
  dictionary-aware entity expansion, 3 intent patterns. User wanted all functionality ported
  into Clio. Decomposed: Clio handles orchestration (intent, filtering, dedup), graphiti-egress
  simplified to raw search, graphiti-entities handles dictionary.
  > "I do want to port all functionality into clio. If you want we can seperate graphiti egress into more fine levers/controls and have clio handle the orchestration"
- **Decision**: Clio absorbs full egress intelligence. graphiti-egress simplified to raw search. graphiti-entities extracted for dictionary logic. Gemini retriever eliminated.
- **Supersedes**: D-006

## D-009: solon-mem as decoupling layer
- **Phase**: 2 | **Classification**: key
- **Session**: explore-2026-03-25
- **Context**:
  User wanted Solon to work without Clio. solon-mem writes staging file (always works) and
  optionally dispatches to Clio. The staging file is the text-based ledger.
  > "I also wanted solon-stage-spec to basically be a way to decouple mem agent in case it doesn't exist"
- **Decision**: solon-mem is the adapter layer. Writes .solon/staging/ always. Dispatches to Clio if available. Solon works fully without Clio.

## D-010: Verbose staging file as text ledger
- **Phase**: 2 | **Classification**: key
- **Session**: explore-2026-03-25
- **Context**:
  User wanted raw data preserved. Session IDs on every entry. Staging file is effectively
  the ledger in text form.
  > "I want the solon-mem to preserve as much of the raw data as it can. So I want pretty verbose excerpts of the conversation copied into the .md"
- **Decision**: Staging file preserves raw conversation excerpts, quoted statements, full rationale. Includes Claude session ID on every entry.

## EVOLUTION SUMMARY

This session started with a broad question: should Solon have separate agents for testing
and memory? The testing agent was deferred; memory extraction became the focus.

Key evolution arc:
1. Started with 4-skill Clio agent reimplementing graphiti logic (D-006)
2. Simplified to agent-router co-loading existing skills (D-007)
3. Expanded egress to port full existing functionality (D-008)
4. Three-tier classification dropped to two-tier (D-003)
5. Enhancement pass dropped entirely (D-005)
6. solon-mem emerged as the decoupling layer enabling Solon-without-Clio (D-009)

The architecture settled on two layers: Clio (orchestration, intent routing, quality gate,
expired filtering) and graphiti-* skills (raw plumbing). Implementation order: clio-agent
first, then solon-lean.
