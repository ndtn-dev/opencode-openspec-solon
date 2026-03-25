---
name: solon-debug
description: Diagnose and remediate OpenSpec dependency issues. Run when Solon or OpenSpec skills report missing dependencies.
allowed-tools: Bash, Read, Glob
---

# Solon Debug

Centralized diagnostic and remediation skill for all OpenSpec dependencies. Run the checks below in order -- report all issues found, not just the first.

## Check 1: CLI Installed

```bash
which openspec
```

- **Pass**: Path returned.
- **Fail**: Report: "OpenSpec CLI is missing. Install it with: `bun add -g openspec`"

## Check 2: Project Initialized

```bash
test -d openspec
```

- **Pass**: Directory exists.
- **Fail**: Report: "Project is not initialized. Run: `openspec init --tools Claude`"

## Check 3: Required Skills Present

Verify these three files exist:
- `.claude/skills/openspec-explore/SKILL.md`
- `.claude/skills/openspec-new-change/SKILL.md`
- `.claude/skills/openspec-continue-change/SKILL.md`

Use Glob to check each path.

- **Pass**: All three exist.
- **Fail**: Report which specific skills are missing. Include the fix: "Run `openspec update --force` to reinstall skills, or check your OpenSpec profile with `openspec config profile`."

## Check 4: Profile Detection

Determine whether the installed profile is **core** or **expanded**:
- **Expanded**: Includes `openspec-new-change` and `openspec-continue-change` skills (both present in Check 3).
- **Core**: Lacks one or both of those skills.

- **Expanded detected**: Report "OpenSpec profile: expanded (correct for Solon)."
- **Core detected**: Report "OpenSpec profile: core. Solon requires the expanded profile. Switch with: `openspec config profile`"

## Check 5: Version Staleness

```bash
openspec --version
```

Compare the output against `.solon/openspec-version.txt` (read with Read tool).

- **Current**: Versions match. Report "OpenSpec version is current."
- **Marker missing** (first run): Report "No version marker found. Writing current version as baseline." Write the marker directly:
  ```bash
  openspec --version > .solon/openspec-version.txt
  ```
  This is NOT an error — it's expected on first run. Do not suggest `openspec update --force`.
- **Stale**: Versions differ (marker exists but doesn't match). Report "OpenSpec version is stale." and proceed to remediation.

## Remediation

Run remediation when Check 3 fails (missing skills) or Check 5 detects staleness (versions differ, not just marker missing).

```bash
openspec update --force
```

- **Success**: Report the update succeeded. Then write the version marker:
  ```bash
  openspec --version > .solon/openspec-version.txt
  ```
  Confirm the marker was written.

- **Failure**: Report the error output. Suggest manual steps:
  1. `bun add -g openspec` (reinstall CLI)
  2. `openspec init --tools Claude` (re-initialize if needed)
  3. `openspec config profile` (check/switch profile)

## Reporting

After all checks complete, output a summary:

- List each check with its pass/fail status.
- For each failure, include the actionable fix command.
- If all checks pass: "OpenSpec environment is healthy. No issues found."

## Constraints

- Use only Bash, Read, and Glob tools. No Agent, Write, or other tools.
- Version marker writes go through Bash (`openspec --version > .solon/openspec-version.txt`), not the Write tool.
- Solon path restrictions apply: only write to `.solon/`.
