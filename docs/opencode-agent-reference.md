# OpenCode Agent Creation Reference

Quick reference for building custom agents in OpenCode. Extracted from
official docs and research.

---

## Agent File Location

- **Project-specific**: `.opencode/agents/<name>.md`
- **Global**: `~/.config/opencode/agents/<name>.md`

File basename (without `.md`) = agent ID.

---

## Markdown Agent Template

```markdown
---
description: Brief purpose (required)
mode: primary
model: anthropic/claude-opus-4-6
temperature: 0.2
color: "#FF6B6B"
tools:
  write: true
  edit: true
  bash: false
  task: true
permission:
  edit:
    "openspec/**": allow
    "specs/**": allow
    "*": deny
  skill:
    "*": allow
---

System prompt goes here. Everything after the closing --- is the prompt.
```

---

## YAML Frontmatter Fields

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `description` | string | **required** | Brief purpose statement |
| `mode` | string | `"all"` | `"primary"` = Tab picker, `"subagent"` = @-only, `"all"` = both |
| `model` | string | inherited | `provider/model-id` format |
| `temperature` | number | 0.0 | 0.0-1.0 |
| `top_p` | number | - | Response diversity |
| `steps` | number | - | Max agentic iterations |
| `color` | string | - | Hex code or theme name |
| `disable` | boolean | false | Disable agent |
| `hidden` | boolean | false | Hide from @ autocomplete |
| `tools` | object | all true | Per-tool enable/disable |
| `permission` | object | - | Per-tool permission rules |
| `reasoningEffort` | string | - | Provider passthrough |
| `textVerbosity` | string | - | Provider passthrough |

---

## Permission States

- `"allow"` -- auto-execute, no prompt
- `"ask"` -- prompt user before execution
- `"deny"` -- block entirely

**Pattern matching**: `*` = zero or more chars, `?` = one char.
**Last matching rule wins** (order matters).

---

## Permission Resources

| Resource | Matches Against |
|----------|----------------|
| `read` | File path |
| `edit` | File path (covers edit, write, patch) |
| `bash` | Command string |
| `webfetch` | URL |
| `websearch` | Query |
| `task` | Subagent name |
| `skill` | Skill name |
| `tool` | Tool name (incl. MCP) |

---

## Tool Disable vs Permission Deny

- `tools: { bash: false }` -- tool is disabled AND hidden from the model
- `permission: { bash: { "*": deny } }` -- tool exists but all calls are blocked

Use `tools: false` when the agent should never see the tool.
Use `permission: deny` when you want selective access (some patterns allowed).

---

## Common Patterns

### Read-only agent (no file modifications)
```yaml
tools:
  write: false
  edit: false
```

### Scoped write access
```yaml
permission:
  edit:
    "docs/**": allow
    "openspec/**": allow
    "*": deny
```

### Bash with allowlist
```yaml
permission:
  bash:
    "git *": allow
    "npm test": allow
    "*": deny
```

### Allow specific subagent delegation
```yaml
tools:
  task: true
permission:
  task:
    "metis": allow
    "explore": allow
    "*": deny
```

---

## Variable Substitution (JSON config only)

```json
{
  "model": "{env:OPENCODE_MODEL}",
  "prompt": "{file:./prompts/planner.txt}"
}
```

Not available in .md frontmatter.

---

## Skills vs Agents

- **Agents**: Conversation modes with model/tool/permission configs
- **Skills**: Injectable instruction sets loaded on-demand via skill tool
- Skills live in `.opencode/skills/<name>/SKILL.md`
- Agents can invoke skills; skills can't invoke agents

---

## Gotchas

1. `mode: subagent` hides from Tab picker -- use `mode: primary` to show
2. Tool disable (`tools: false`) overrides permission rules
3. Last matching permission rule wins (order matters)
4. Markdown body IS the system prompt -- no separate `prompt` field needed
5. Agent-level permissions override global permissions
