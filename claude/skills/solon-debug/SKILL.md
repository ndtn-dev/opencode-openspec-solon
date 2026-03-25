---
name: solon-debug
description: Diagnose and remediate OpenSpec dependency issues. Run when Solon or OpenSpec skills report missing dependencies.
---

# Solon Debug

Centralized diagnostic and remediation skill for all OpenSpec dependencies.

## Execution

This skill requires Bash access. Since Solon disallows Bash, dispatch an Agent with Bash access to run all checks:

```
Dispatch an Agent with prompt:
"Run all OpenSpec diagnostic checks in order. Report ALL issues found, not just the first.

Check 1 — CLI Installed:
  Run: which openspec
  Pass: path returned.
  Fail: report 'OpenSpec CLI is missing. Install it with: bun add -g openspec'

Check 2 — Project Initialized:
  Run: test -d openspec
  Pass: directory exists.
  Fail: report 'Project is not initialized. Run: openspec init --tools Claude'

Check 3 — Required Skills Present:
  Verify these three files exist (use Glob):
    .claude/skills/openspec-explore/SKILL.md
    .claude/skills/openspec-new-change/SKILL.md
    .claude/skills/openspec-continue-change/SKILL.md
  Pass: all three exist.
  Fail: report which are missing. Fix: 'Run openspec update --force to reinstall skills, or check your OpenSpec profile with openspec config profile.'

Check 4 — Profile Detection:
  Expanded = both openspec-new-change and openspec-continue-change present (from Check 3).
  Core = one or both missing.
  Expanded: report 'OpenSpec profile: expanded (correct for Solon).'
  Core: report 'OpenSpec profile: core. Solon requires the expanded profile. Switch with: openspec config profile'

Check 5 — Version Staleness:
  Run: openspec --version
  Read .solon/openspec-version.txt (may not exist).
  Current (versions match): report 'OpenSpec version is current (v[version]).'
  Marker missing (first run): report 'No version marker found. Writing current version as baseline.' Then run: openspec --version > .solon/openspec-version.txt — this is NOT an error, do not suggest openspec update --force.
  Stale (versions differ): report 'OpenSpec version is stale.' and run remediation.

Remediation (only when Check 3 fails or Check 5 detects version mismatch):
  Run: openspec update --force
  Success: report update succeeded, then run: openspec --version > .solon/openspec-version.txt
  Failure: report error output and suggest manual steps:
    1. bun add -g openspec (reinstall CLI)
    2. openspec init --tools Claude (re-initialize if needed)
    3. openspec config profile (check/switch profile)

After all checks, output a summary table with each check's pass/fail status. For each failure, include the actionable fix command. If all pass: 'OpenSpec environment is healthy. No issues found.'

After the table, on its own line: 'To check for upstream updates: openspec update'

The sub-agent may use Bash, Read, and Glob tools only. Version marker writes go through Bash, not the Write tool. Only write to .solon/."
```

Present the sub-agent's summary directly to the user. Do not reformat or drop any details — especially actionable commands.
