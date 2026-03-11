# Solon — OpenSpec Design Partner for OpenCode

A custom OpenCode agent for [OpenSpec](https://github.com/Fission-AI/OpenSpec)
spec-driven development. Designed as a collaborative design partner — not an
execution agent.

Inspired by [opencode-plugin-openspec](https://github.com/Octane0411/opencode-plugin-openspec)
and [Oh My OpenAgent](https://github.com/code-yeongyu/oh-my-openagent) prompt
engineering patterns, adapted for brainstorm-first iterative spec creation.

## Install

Copy `agent/solon.md` into your project's `.opencode/agents/` directory:

```bash
mkdir -p .opencode/agents
cp agent/solon.md .opencode/agents/solon.md
```

Solon will appear in OpenCode's agent picker (Tab key). Requires
[OpenSpec](https://github.com/Fission-AI/OpenSpec) to be initialized
in the project (`openspec init`).

## What It Does

- **Incremental artifacts** — specs form during conversation, not after a long silence
- **Assumption tracking** — three-tier system (assume/placeholder/ask) keeps momentum
  while maintaining accountability
- **Intent gate** — classifies intent and auto-triggers the right OpenSpec skill
- **Plan-to-spec conversion** — converts Sisyphus plans, Claude plans, RFCs, or any
  structured markdown into OpenSpec format
- **Optional gap analysis** — tries @metis if available, falls back to self-review
- **Works with or without Oh My OpenAgent** — no hard dependencies

## Design Docs

| Document | Contents |
|----------|----------|
| [agent-phases.md](docs/agent-phases.md) | The 5-phase architecture (intent, explore, brainstorm, gap analysis, finalize) |
| [intent-skill-mapping.md](docs/intent-skill-mapping.md) | Intent classification and OpenSpec skill auto-triggers |
| [assumption-tracking.md](docs/assumption-tracking.md) | Three-tier decision tracking system |
| [gap-analysis.md](docs/gap-analysis.md) | Metis delegation with self-review fallback |
| [design-philosophy.md](docs/design-philosophy.md) | How this differs from OmO execution agents |
| [exploration-sources.md](docs/exploration-sources.md) | What the agent reads and why |
| [prompt-engineering-principles.md](docs/prompt-engineering-principles.md) | How to write effective agent prompts for Opus |
| [key-decisions.md](docs/key-decisions.md) | Every design decision with rationale |
| [persona-engineering.md](docs/persona-engineering.md) | How persona/role choice affects model behavior |
| [opencode-agent-reference.md](docs/opencode-agent-reference.md) | OpenCode agent creation quick reference |
| [open-sourcing.md](docs/open-sourcing.md) | Relationship to prior art, publish checklist |

## License

MIT
