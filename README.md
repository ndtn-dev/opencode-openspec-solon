# Solon — OpenSpec Design Partner

A collaborative design partner agent for [OpenSpec](https://github.com/Fission-AI/OpenSpec)
spec-driven development. Supports both **Claude Code** and **OpenCode**.

Inspired by [opencode-plugin-openspec](https://github.com/Octane0411/opencode-plugin-openspec)
and [Oh My OpenAgent](https://github.com/code-yeongyu/oh-my-openagent) prompt
engineering patterns, adapted for brainstorm-first iterative spec creation.

## Install

### Claude Code

```bash
./install.sh claude
```

Or manually copy into your project:

```bash
cp claude/agent/solon.md .claude/agents/solon.md
cp -r claude/skills/* .claude/skills/
```

### OpenCode

```bash
./install.sh opencode
```

Or manually copy into your project:

```bash
cp opencode/agent/solon.md .opencode/agents/solon.md
cp -r opencode/skills/* .opencode/skills/
```

Solon will appear in the agent picker. Requires
[OpenSpec](https://github.com/Fission-AI/OpenSpec) to be initialized
in the project (`openspec init`).

## What It Does

- **Incremental artifacts** — specs form during conversation, not after a long silence
- **Assumption tracking** — three-tier system (assume/placeholder/ask) keeps momentum
  while maintaining accountability
- **Intent gate** — classifies intent and auto-triggers the right skill
- **Plan-to-spec conversion** — converts plans, RFCs, or any structured markdown into
  OpenSpec format
- **Gap analysis** — mandatory review before writing, with optional delegation
- **Decision persistence** — graphiti knowledge graph integration for cross-session memory

## Project Structure

```
opencode/                    # OpenCode variant (GPT/Gemini/Kimi compatible)
  agent/solon.md             # Agent definition
  skills/                    # 6 skill files
claude/                      # Claude Code variant (full complexity)
  agent/solon.md             # Agent definition
  skills/                    # 6 skill files
docs/                        # Shared design docs (governs both variants)
install.sh                   # Install script
```

Both variants implement the same 7-phase workflow. The Claude Code variant
uses Claude-native tool dispatch; the OpenCode variant uses OmO task dispatch.

## Design Docs

| Document | Contents |
|----------|----------|
| [agent-phases.md](docs/agent-phases.md) | The 5-phase architecture (intent, explore, brainstorm, gap analysis, finalize) |
| [intent-skill-mapping.md](docs/intent-skill-mapping.md) | Intent classification and skill auto-triggers |
| [assumption-tracking.md](docs/assumption-tracking.md) | Three-tier decision tracking system |
| [gap-analysis.md](docs/gap-analysis.md) | Delegation with self-review fallback |
| [design-philosophy.md](docs/design-philosophy.md) | How this differs from OmO execution agents |
| [exploration-sources.md](docs/exploration-sources.md) | What the agent reads and why |
| [prompt-engineering-principles.md](docs/prompt-engineering-principles.md) | How to write effective agent prompts |
| [key-decisions.md](docs/key-decisions.md) | Every design decision with rationale |
| [persona-engineering.md](docs/persona-engineering.md) | How persona/role choice affects model behavior |
| [opencode-agent-reference.md](docs/opencode-agent-reference.md) | OpenCode agent creation quick reference |
| [claude-code-port-plan.md](docs/claude-code-port-plan.md) | Port plan from OpenCode to Claude Code |
| [open-sourcing.md](docs/open-sourcing.md) | Relationship to prior art, publish checklist |

## License

MIT
