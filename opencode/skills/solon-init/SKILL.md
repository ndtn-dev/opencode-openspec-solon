---
name: solon-init
description: OpenSpec project initialization skill with pre-flight checks
compatibility: opencode
metadata:
  category: spec
  triggers:
    - init
    - initialize
    - set up openspec
    - start speccing
---

# Solon Init Skill

## Role

Loaded by a sub-agent. Initializes OpenSpec in a project with pre-flight environment checks.

## Pre-flight Checks

### 1. Git Repo

Check if `.git/` directory exists.

```bash
test -d .git
```

**If not found:**
Warn: "This project isn't a git repo yet. OpenSpec works without git, but anything worth speccing is probably worth versioning. Consider running `git init` first."
**Continue** (non-blocking).

### 2. Git Remote

Check if a remote is configured.

```bash
git remote -v | grep -q .
```

**If not found:**
Warn: "No git remote configured. Specs work locally but you'll want a remote for backup and collaboration."
**Continue** (non-blocking).

### 3. Not Already Initialized

Check if `openspec/` directory exists.

```bash
test -d openspec
```

**If found:**
Report: "OpenSpec is already set up here."
**STOP** — do not proceed.

## Execution

If all checks pass (or only non-blocking warnings), run:

```bash
openspec init --tools Claude
```

Confirm the `openspec/` directory structure was created.

**If `openspec init` fails:**
Report: "OpenSpec initialization failed. Run /solon-debug to diagnose."
**STOP** — do not proceed.

## Return

Report success or failure to the main agent. If initialization succeeded, resume the original intent or ask what the user wants to do next.
