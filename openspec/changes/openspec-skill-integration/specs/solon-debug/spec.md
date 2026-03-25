## ADDED Requirements

### Requirement: CLI installation check
The solon-debug skill MUST check whether the OpenSpec CLI is installed by running `which openspec`.

#### Scenario: CLI is installed
- **WHEN** `which openspec` returns a path
- **THEN** the check passes and diagnosis continues to the next check

#### Scenario: CLI is not installed
- **WHEN** `which openspec` returns no result or exits non-zero
- **THEN** the skill reports that the OpenSpec CLI is missing with an actionable install command

### Requirement: Project initialization check
The solon-debug skill MUST check whether the current project has been initialized by testing for the `openspec` directory.

#### Scenario: Project is initialized
- **WHEN** `test -d openspec` succeeds
- **THEN** the check passes and diagnosis continues to the next check

#### Scenario: Project is not initialized
- **WHEN** `test -d openspec` fails
- **THEN** the skill reports that the project is not initialized and provides the initialization command

### Requirement: Required skills presence check
The solon-debug skill MUST check that the three required skill files are present: openspec-explore, openspec-new-change, and openspec-continue-change.

#### Scenario: All required skills present
- **WHEN** all three skill files exist at `.claude/skills/openspec-explore/SKILL.md`, `.claude/skills/openspec-new-change/SKILL.md`, and `.claude/skills/openspec-continue-change/SKILL.md`
- **THEN** the check passes and diagnosis continues to the next check

#### Scenario: One or more required skills missing
- **WHEN** any of the three required skill files is absent
- **THEN** the skill reports which specific skills are missing with an actionable fix command

### Requirement: Profile type detection
The solon-debug skill MUST detect whether the installed OpenSpec profile is core or expanded by comparing installed skills against the expanded skill set.

#### Scenario: Expanded profile detected
- **WHEN** the installed skills include the full expanded set (including openspec-new-change and openspec-continue-change)
- **THEN** the skill reports the profile as expanded

#### Scenario: Core profile detected
- **WHEN** the installed skills match only the core set and lack expanded skills
- **THEN** the skill reports the profile as core and advises switching to the expanded profile

### Requirement: Version staleness check
The solon-debug skill MUST check for version staleness by comparing the output of `openspec --version` against the marker file at `.solon/openspec-version.txt`.

#### Scenario: Version is current
- **WHEN** `openspec --version` output matches the content of `.solon/openspec-version.txt`
- **THEN** the check passes and no update is needed

#### Scenario: Version is stale
- **WHEN** `openspec --version` output differs from `.solon/openspec-version.txt` or the marker file does not exist
- **THEN** the skill reports version staleness and triggers remediation

### Requirement: Remediation via forced update
The solon-debug skill MUST run `openspec update --force` when version staleness or missing skills are detected.

#### Scenario: Update succeeds
- **WHEN** `openspec update --force` completes successfully
- **THEN** the skill reports success and writes the current version to `.solon/openspec-version.txt`

#### Scenario: Update fails
- **WHEN** `openspec update --force` exits with an error
- **THEN** the skill reports the failure with the error output and suggests manual remediation steps

### Requirement: Version marker persistence
The solon-debug skill MUST write the current OpenSpec version to `.solon/openspec-version.txt` after a successful update.

#### Scenario: Marker written after successful update
- **WHEN** `openspec update --force` completes successfully
- **THEN** the skill writes the output of `openspec --version` to `.solon/openspec-version.txt`

### Requirement: Clear diagnostic reporting
The solon-debug skill MUST report a clear diagnosis with an actionable fix command for each issue found.

#### Scenario: Multiple issues detected
- **WHEN** more than one check fails
- **THEN** the skill reports all issues with individual actionable fix commands, not just the first failure

#### Scenario: No issues detected
- **WHEN** all checks pass
- **THEN** the skill reports that the OpenSpec environment is healthy

### Requirement: Allowed tools constraint
The solon-debug skill MUST only use Bash, Read, and Glob tools.

#### Scenario: Skill execution
- **WHEN** solon-debug runs any operation
- **THEN** it uses only Bash, Read, or Glob tools and does not invoke Agent, Write, or other tools
