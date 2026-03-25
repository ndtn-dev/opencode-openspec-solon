## MODIFIED Requirements

### Requirement: Sub-agent delegation
Phase 6 MUST dispatch a sub-agent with Bash access via the Agent tool to perform artifact creation. The sub-agent MUST invoke the openspec-new-change skill to scaffold the change directory and then invoke the openspec-continue-change skill for each artifact.

The sub-agent prompt MUST include Solon's confirmed content from Phases 2-4 (decisions, scope, constraints, and filled placeholders).

The sub-agent MUST write "{{DEFERRED: not addressed in current spec cycle}}" for any template section that has no confirmed content from the preceding phases.

Phase 6 MUST NOT generate new content during artifact writing (locked-state rule applies).

#### Scenario: Sub-agent scaffolds and writes artifacts
- **WHEN** Phase 6 begins artifact creation
- **THEN** a sub-agent is dispatched via the Agent tool with Bash access, and the sub-agent invokes openspec-new-change to scaffold the change directory followed by openspec-continue-change for each artifact

#### Scenario: Confirmed content passed to sub-agent
- **WHEN** the sub-agent is dispatched
- **THEN** the sub-agent prompt includes all confirmed decisions, scope boundaries, constraints, and filled placeholders from Phases 2-4

#### Scenario: Template section without confirmed content
- **WHEN** the sub-agent encounters a template section for which no confirmed content exists
- **THEN** the sub-agent writes "{{DEFERRED: not addressed in current spec cycle}}" for that section

#### Scenario: No new content generation during Phase 6
- **WHEN** Phase 6 is active and writing artifacts
- **THEN** no new content is generated beyond what was confirmed in Phases 2-4

### Requirement: OpenSpec hard dependency
If an OpenSpec skill invocation fails during Phase 6, the phase MUST stop and point the user to /solon-debug. Phase 6 MUST NOT fall back to direct file writes.

#### Scenario: Skill invocation fails
- **WHEN** the sub-agent's invocation of openspec-new-change or openspec-continue-change fails
- **THEN** Phase 6 stops and reports: "OpenSpec skill invocation failed. Run /solon-debug to diagnose."

#### Scenario: No direct-write fallback
- **WHEN** an OpenSpec skill invocation fails
- **THEN** Phase 6 MUST NOT attempt to write artifact files directly, bypassing the OpenSpec skills
