## MODIFIED Requirements

### Requirement: Post-implementation workflow reference
The handoff document MUST reference the post-implementation steps in order: apply, verify, archive. The document MUST use the skill names openspec-apply-change, openspec-verify-change, and openspec-archive-change.

The handoff skill MUST NOT invoke these skills itself; they are post-Solon territory and are only referenced for the implementer's awareness.

#### Scenario: Handoff document includes post-implementation steps
- **WHEN** the handoff document is generated
- **THEN** it includes a section referencing the post-implementation workflow in order: apply (openspec-apply-change) -> verify (openspec-verify-change) -> archive (openspec-archive-change)

#### Scenario: Skill names used correctly
- **WHEN** the handoff document references post-implementation steps
- **THEN** it uses the exact skill names: openspec-apply-change, openspec-verify-change, openspec-archive-change

#### Scenario: Skills not invoked by handoff
- **WHEN** the handoff document is being generated
- **THEN** solon-handoff MUST NOT invoke openspec-apply-change, openspec-verify-change, or openspec-archive-change
