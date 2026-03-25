## MODIFIED Requirements

### Requirement: Skill presence gate
Phase 1 MUST check for the presence of 3 required OpenSpec skill files before proceeding with exploration:
- `.claude/skills/openspec-explore/SKILL.md`
- `.claude/skills/openspec-new-change/SKILL.md`
- `.claude/skills/openspec-continue-change/SKILL.md`

If any skill file is missing, Phase 1 MUST stop with the message: "OpenSpec dependency missing. Run /solon-debug to diagnose."

Phase 1 MUST NOT attempt a direct-write fallback when skills are missing.

#### Scenario: All required skills present
- **WHEN** all three skill files exist at their expected paths
- **THEN** Phase 1 proceeds to exploration

#### Scenario: One skill missing
- **WHEN** `.claude/skills/openspec-new-change/SKILL.md` does not exist but the other two do
- **THEN** Phase 1 stops and displays "OpenSpec dependency missing. Run /solon-debug to diagnose."

#### Scenario: Multiple skills missing
- **WHEN** two or more of the required skill files are absent
- **THEN** Phase 1 stops and displays "OpenSpec dependency missing. Run /solon-debug to diagnose."

#### Scenario: Skill missing with fallback temptation
- **WHEN** a required skill file is missing
- **THEN** Phase 1 MUST NOT attempt to write artifacts directly or proceed without the skill

### Requirement: Explore delegation
Phase 1 MUST delegate codebase exploration to the openspec-explore skill. Solon adds a structured reading order on top of the exploration results, following the priority: specs, notepads, project context, then codebase.

#### Scenario: Exploration with openspec-explore
- **WHEN** Phase 1 begins exploration after the skill presence gate passes
- **THEN** codebase exploration is delegated to the openspec-explore skill

#### Scenario: Structured reading order applied
- **WHEN** openspec-explore returns exploration results
- **THEN** Solon applies its structured reading order (specs -> notepads -> project context -> codebase) on top of the exploration output
