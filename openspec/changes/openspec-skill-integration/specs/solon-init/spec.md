## MODIFIED Requirements

### Requirement: Simplified pre-flight
The solon-init skill MUST remove the `which openspec` CLI check, as it is redundant with the init command's own failure handling.

The solon-init skill MUST keep the following checks:
- Git repo warning (non-blocking): warn if `.git/` does not exist
- Git remote warning (non-blocking): warn if no git remote is configured
- Already-initialized check (blocking): stop if `openspec/` directory exists

If `openspec init --tools Claude` fails, solon-init MUST stop and point the user to /solon-debug.

The solon-init skill MUST use Bash directly for the `openspec init` command, as no skill exists for bootstrapping.

#### Scenario: CLI check removed
- **WHEN** solon-init runs its pre-flight checks
- **THEN** it does not run `which openspec` or any equivalent CLI existence check

#### Scenario: Git repo warning preserved
- **WHEN** `.git/` directory does not exist
- **THEN** solon-init warns that the project is not a git repo but continues (non-blocking)

#### Scenario: Git remote warning preserved
- **WHEN** no git remote is configured
- **THEN** solon-init warns that no remote is configured but continues (non-blocking)

#### Scenario: Already-initialized check preserved
- **WHEN** `openspec/` directory already exists
- **THEN** solon-init stops and reports that OpenSpec is already set up (blocking)

#### Scenario: Init command fails
- **WHEN** `openspec init --tools Claude` exits with an error
- **THEN** solon-init stops and reports: "OpenSpec initialization failed. Run /solon-debug to diagnose."

#### Scenario: Init uses Bash directly
- **WHEN** solon-init runs the initialization command
- **THEN** it invokes `openspec init --tools Claude` via Bash directly, not through an OpenSpec skill

#### Scenario: Successful initialization
- **WHEN** all non-blocking checks pass and `openspec init --tools Claude` succeeds
- **THEN** solon-init confirms the `openspec/` directory structure was created and resumes the original intent
