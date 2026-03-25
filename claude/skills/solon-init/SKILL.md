---
name: solon-init
description: OpenSpec project initialization with pre-flight checks. Invoke when user wants to set up OpenSpec in a project.
allowed-tools: Bash, Read, Glob
---

# Solon Init Skill

## Role

Initializes OpenSpec in a project with pre-flight environment checks.

## Pre-flight Checks

### 1. CLI Installed

Check if `openspec` command is available.

```bash
which openspec
```

**If not found:**
Report: "OpenSpec CLI isn't installed. You need it to proceed — run `bun add -g openspec`."
**STOP** — do not proceed.

### 2. Git Repo

Check if `.git/` directory exists.

```bash
test -d .git
```

**If not found:**
Warn: "This project isn't a git repo yet. OpenSpec works without git, but anything worth speccing is probably worth versioning. Consider running `git init` first."
**Continue** (non-blocking).

### 3. Git Remote

Check if a remote is configured.

```bash
git remote -v | grep -q .
```

**If not found:**
Warn: "No git remote configured. Specs work locally but you'll want a remote for backup and collaboration."
**Continue** (non-blocking).

### 4. Not Already Initialized

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

## Return

Report success or failure. If initialization succeeded, resume the original intent or ask what the user wants to do next.
