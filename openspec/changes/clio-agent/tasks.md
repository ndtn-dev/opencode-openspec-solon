## 0. Skill Prerequisites

- [ ] 0.1 Verify graphiti-normalizer exists as a standalone skill in the Claude Code global toolkit (~/.claude/skills/graphiti-normalizer/SKILL.md). If it only exists for OpenCode (~/.config/opencode/skills/), port it to Claude Code.
- [ ] 0.2 Verify graphiti-ledger-insert exists as a standalone skill in the Claude Code global toolkit (~/.claude/skills/graphiti-ledger-insert/SKILL.md). If it only exists for OpenCode, port it.
- [ ] 0.3 Verify graphiti-enhancer exists (not co-loaded by Clio, but confirm it is available for other use cases)

## 1. Clio Agent Definition

- [ ] 1.1 Create clio.md agent definition with intent routing (ingress including evolution summaries, egress with 4 patterns: repo-specific, cross-reference, broad, meta), expired fact filtering, deduplication, history mode, result handling, quality gate rules, group_id management logic, and co-loaded skill list
- [ ] 1.2 Define .graphiti/config.yaml schema for default group_id and companion group(s)
- [ ] 1.3 Ensure .graphiti/ingress/pending/ directory structure exists for JSON fallbacks

## 2. graphiti-egress Skill (simplified)

- [ ] 2.1 Create graphiti-egress skill with raw multi-group search (facts + nodes), enforcing 2-group minimum
- [ ] 2.2 Implement single-group rejection with FalkorDB bug explanation
- [ ] 2.3 Implement center_node_uuid support for entity-centered fact search
- [ ] 2.4 Implement graceful degradation for MCP unavailability and errors

## 3. graphiti-entities Skill

- [ ] 3.1 Create graphiti-entities skill with entity dictionary reader (.graphiti/entities.yaml)
- [ ] 3.2 Implement query expansion (synonym -> canonical, canonical -> synonyms, one level only, additive)
- [ ] 3.3 Implement synonym lookup for normalization use
- [ ] 3.4 Implement graceful degradation when dictionary is missing

## 4. Generalize graphiti-ledger-status

- [ ] 4.1 Remove Solon-specific language from graphiti-ledger-status (phase references, agent-specific wording)
- [ ] 4.2 Update delegation pattern: run inline when co-loaded by another agent, dispatch to background Agent when standalone
- [ ] 4.3 Ensure drain, verify, and report operations work from any agent context
- [ ] 4.4 Preserve Reasonable Time Policy (30min skip, 24h fail)
- [ ] 4.5 Preserve verification mechanics (2-group egress pattern for FalkorDB check, dual-timestamp updates)

## 5. Integration Verification

- [ ] 5.1 Verify Clio routes ingress correctly through quality gate -> graphiti-ledger-insert -> graphiti-normalizer
- [ ] 5.2 Verify Clio routes egress correctly through graphiti-egress with companion groups
- [ ] 5.3 Verify Clio routes status/drain correctly through graphiti-ledger-status
- [ ] 5.4 Verify quality gate drops duplicates and trivial entries without graph persistence
- [ ] 5.5 Verify group_id resolution (caller-provided > config > ask)
- [ ] 5.6 Verify Clio communicates missing requirements (group_id) back to callers
- [ ] 5.7 Verify Clio detects cross-reference intent and searches multiple repo graphs
- [ ] 5.8 Verify graphiti-entities expands search terms correctly
- [ ] 5.9 Verify expired facts are filtered from results (unless history mode)
- [ ] 5.10 Verify graphiti-egress rejects single-group searches
