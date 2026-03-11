# opencode-openspec-agent

A custom OpenCode agent for OpenSpec spec-driven development. Designed as a
collaborative design partner -- not an execution agent.

Built from research into [opencode-plugin-openspec](https://github.com/Octane0411/opencode-plugin-openspec)
and [Oh My OpenAgent](https://github.com/code-yeongyu/oh-my-openagent) prompt
engineering patterns, adapted for brainstorm-first iterative spec creation.

## Key Differences from Existing Solutions

- **Incremental artifacts** -- specs form during conversation, not after a long silence
- **Assumption tracking** -- three-tier system (assume/placeholder/ask) keeps momentum
  while maintaining accountability
- **Intent gate** -- classifies intent and auto-triggers the right OpenSpec skill
- **Plan-to-spec conversion** -- converts Sisyphus plans, Claude plans, RFCs, or any
  structured markdown into OpenSpec format
- **Optional gap analysis** -- tries Metis if available, falls back to self-review
- **Works with or without Oh My OpenAgent** -- no hard dependencies

## Docs

| Document | Contents |
|----------|----------|
| [agent-phases.md](docs/agent-phases.md) | The 5-phase architecture (intent -> explore -> brainstorm -> gap analysis -> finalize) |
| [intent-skill-mapping.md](docs/intent-skill-mapping.md) | Intent classification and OpenSpec skill auto-triggers |
| [assumption-tracking.md](docs/assumption-tracking.md) | Three-tier decision tracking system |
| [gap-analysis.md](docs/gap-analysis.md) | Metis delegation with self-review fallback |
| [design-philosophy.md](docs/design-philosophy.md) | How this differs from OmO execution agents |
| [exploration-sources.md](docs/exploration-sources.md) | What the agent reads and why |
| [opencode-agent-reference.md](docs/opencode-agent-reference.md) | OpenCode agent creation quick reference |

## Status

Design phase. The agent `.md` file has not been built yet -- docs capture
the design decisions and research that inform it.
