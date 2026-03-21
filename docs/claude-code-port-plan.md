# Porting Solon to Claude Code

Plan for converting the Solon OpenCode agent into a Claude Code agent,
assuming Claude Code also has graffiti-mcp configured.

---

## Scope

Port the Solon design-partner agent from OpenCode format to Claude Code format.

**In scope:**
- Agent definition (`agent/solon.md` -> `.claude/agents/solon.md`)
- All 6 OpenCode skills -> `.claude/skills/` equivalents
- Phase 0 intent routing adapted for Claude Code skill invocation
- Subagent dispatch adapted for Claude Code Agent tool

**Out of scope:**
- Prometheus hooks / handoff references (remove)
- OmO-specific delegation patterns (remove)
- Oh My OpenAgent hard dependencies (remove)

---

## Architecture Mapping

| OpenCode Concept | Claude Code Equivalent | Notes |
|------------------|----------------------|-------|
| `.opencode/agents/solon.md` | `.claude/agents/solon.md` | Different frontmatter schema |
| `.opencode/skills/<name>/SKILL.md` | `.claude/skills/<name>.md` | Same concept, different path |
| `load_skills=['solon-spec']` on self | Skill tool invocation | Skills inject into agent context the same way |
| `task(subagent_type='metis', load_skills=[...])` | Agent tool with dedicated agent definition | Need `.claude/agents/` entries for each |
| `permission.edit: "openspec/**": allow` | Prompt-enforced only | Claude Code lacks path-based edit permissions |
| `permission.bash: deny` | `disallowedTools: ["Bash"]` | Direct equivalent |
| `permission.task: "metis": allow` | No equivalent | Agent tool has no allow/deny per subagent |
| `model: openai/gpt-5.4` | Omit (inherit) or set Claude model | |
| `temperature: 0.2` | Not configurable | Claude Code agents don't expose temperature |
| `mode: primary` | No equivalent needed | Claude Code agents always appear in picker |

---

## Tasks

### 1. Translate agent frontmatter

Convert OpenCode YAML frontmatter to Claude Code format.

**From (OpenCode):**
```yaml
name: Solon (OpenSpec)
description: Solon (OpenSpec) — collaborative design partner for spec-driven development
mode: primary
model: openai/gpt-5.4
temperature: 0.2
color: "#FF6B6B"
permission:
  bash: deny
  edit:
    "openspec/**": allow
    "specs/**": allow
    ".solon/**": allow
    ".graphiti/**": allow
    "*": deny
  task:
    "metis": allow
    "explore": allow
    "librarian": allow
    "*": ask
  skill:
    "solon-spec": allow
    "solon-reconcile": allow
    "solon-init": allow
    "solon-handoff": allow
    "solon-ingress": allow
    "graphiti-ledger-status": allow
    "*": deny
```

**To (Claude Code):**
```yaml
description: Solon (OpenSpec) — collaborative design partner for spec-driven development
disallowedTools:
  - Bash
  - Write
```

Path-based edit restrictions move into prompt body as rules.

### 2. Convert 6 skills to Claude Code format

Each OpenCode skill in `.opencode/skills/<name>/SKILL.md` becomes a
`.claude/skills/<name>.md` file. The skill body (instructions) should
port nearly verbatim. Changes needed per skill:

- `solon-spec` — Core phases 1-5. Replace any `task()` dispatch syntax
  with Claude Code Agent tool references.
- `solon-reconcile` — Replace `task(subagent_type='metis', ...)` with
  Agent tool dispatch.
- `solon-init` — Likely minimal changes.
- `solon-handoff` — Remove Prometheus references, simplify to generic
  "hand off to execution agent" language.
- `solon-ingress` — Likely minimal changes.
- `graphiti-ledger-status` — Keep as-is if graffiti-mcp is configured.
  Verify MCP tool names match.

### 3. Adapt Phase 0 routing table

Update dispatch syntax in the prompt body:

| Intent | OpenCode | Claude Code |
|--------|----------|-------------|
| Reconcile | `task(subagent_type='metis', load_skills=['solon-reconcile'], ...)` | `Agent tool` with dedicated reconcile agent, or Skill tool for solon-reconcile |
| Spec | `load solon-spec on self` | Invoke Skill tool for solon-spec |
| Init | `dispatch sub-agent with load_skills=['solon-init']` | Agent tool with solon-init prompt |
| Handoff | `dispatch sub-agent with load_skills=['solon-handoff']` | Agent tool with solon-handoff prompt |

### 4. Adapt ledger auto-verify

**From:**
```
task(category='quick', load_skills=['graphiti-ledger-status'],
     run_in_background=true, prompt='CHECK LEDGER STATUS: verify')
```

**To:**
Inline Agent tool call instruction in prompt body:
```
On every activation, dispatch a background Agent:
  Agent(subagent_type="general-purpose", run_in_background=true,
        prompt="Using graffiti-mcp, verify ledger status.")
```

Or: configure as a Claude Code hook if preferred.

### 5. Handle permission softening

Claude Code cannot enforce path-based edit restrictions via config.
Mitigate by:

- Adding explicit rules in the prompt body:
  "You may ONLY write files inside: openspec/, specs/, .solon/, .graphiti/"
- Using `disallowedTools: ["Bash"]` to prevent shell escape
- Disabling Write tool (force Edit-only for tighter control)
- Accepting that this is prompt-enforced, not hard-enforced

### 6. Remove Prometheus / OmO references

- Phase 5 handoff message mentions Prometheus and `/start-work` — replace
  with generic execution-agent language
- Remove any `@prometheus` or OmO-specific dispatch patterns
- Remove references to Sisyphus boulder/todo patterns if present in skills

### 7. Verify graffiti-mcp integration

- Confirm MCP tool names match between OpenCode and Claude Code configs
- The `graphiti-ledger-status` skill likely calls MCP tools — verify the
  tool names are the same or update references
- Test ledger verify flow end-to-end

---

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| Soft edit permissions (prompt-only) | Low | Solon doesn't run bash, and the persona discourages writing outside spec dirs. Unlikely to drift. |
| No temperature control | Low | Claude defaults work fine for this use case. |
| Skill loading differences | Low | Claude Code skills inject into context the same way. Syntax differs but behavior matches. |
| Subagent dispatch without skill loading | Medium | For reconcile (needs Metis), create a dedicated `.claude/agents/metis-reconcile.md` that embeds the reconcile instructions. |
| MCP tool name mismatches | Medium | Verify graffiti-mcp tool names in Claude Code config before testing. |

---

## Estimated Effort

~2-4 hours of careful translation, mostly spent on:
- Reading and adapting the 6 skill files (bulk of the work)
- Testing Phase 0 routing with Claude Code's skill/agent dispatch
- Verifying graffiti-mcp tool compatibility
