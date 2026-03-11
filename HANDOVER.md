# Handover Prompt

Copy everything below the line into a fresh agent conversation opened in
`~/Projects/opencode-openspec-agent/`.

---

## Task

Build the file `agent/openspec-planner.md` -- a custom OpenCode agent definition
for an OpenSpec-powered collaborative design partner.

**Do not improvise.** Read ALL docs in `docs/` first. They are the design spec
for this agent -- every behavioral decision has been made and documented. Your
job is to distill them into a clean, effective agent .md file.

## What to Build

A single markdown file with YAML frontmatter that can be placed at
`.opencode/agents/openspec-planner.md` in any project.

### YAML Frontmatter

```yaml
---
description: OpenSpec Planner - collaborative design partner for spec-driven development
mode: primary
model: anthropic/claude-opus-4-6
temperature: 0.2
color: "#FF6B6B"
tools:
  bash: false
  task: true
permission:
  edit:
    "openspec/**": allow
    "specs/**": allow
    "*": deny
  task:
    "metis": allow
    "explore": allow
    "librarian": allow
    "*": ask
  skill:
    "*": allow
---
```

### System Prompt (Markdown Body)

Read these docs in this order before writing the prompt:

1. `docs/design-philosophy.md` -- core identity and how this differs from execution agents
2. `docs/agent-phases.md` -- the 5-phase architecture
3. `docs/intent-skill-mapping.md` -- intent gate and skill auto-triggers
4. `docs/assumption-tracking.md` -- three-tier decision system
5. `docs/gap-analysis.md` -- Metis delegation with self-review fallback
6. `docs/exploration-sources.md` -- what to read during exploration
7. `docs/prompt-engineering-principles.md` -- HOW to write the prompt (critical)
8. `docs/key-decisions.md` -- every decision and its rationale
9. `docs/opencode-agent-reference.md` -- OpenCode agent mechanics reference

### Prompt Guidelines

From `docs/prompt-engineering-principles.md` (read the full doc, but key points):

- **Target 150-250 lines.** This is a hard constraint. The design docs are
  ~1,200 lines but the prompt must be a tight distillation.
- **Use XML tags** for structure: `<Role>`, `<Principles>`, `<Phases>`, `<Rules>`
- **Describe behavior, not algorithms.** Write "check known plan paths first,
  then common locations, then scan, then ask" -- NOT keyword scoring tables
  and tier-by-tier flowcharts.
- **State principles behind rules.** "Run a clearance check before generating.
  The principle: incomplete understanding produces specs that create more work
  than no specs." This makes it work for both Claude and GPT models.
- **The agent is a design partner, not an executor.** It explains reasoning,
  surfaces trade-offs, asks about intent. It does NOT use terse one-word
  answers, skip preamble, or treat human input as failure.

### What MUST Be in the Prompt

- Identity as a collaborative design partner (not a worker/executor)
- The 5 phases: intent gate -> exploration -> brainstorm with incremental
  artifacts -> optional gap analysis -> finalize with assumption summary
- Intent classifications: trivial, exploratory, explicit, plan-to-spec,
  open-ended, ambiguous -- with skill auto-triggers (/opsx:explore, /opsx:propose)
- Three-tier assumption tracking: small (assume+track), medium ({{PLACEHOLDER}}),
  big (stop+ask)
- Clearance check (5 criteria) as conversational guide, NOT blocking gate
- Gap analysis: prompt user "want gap analysis?", try @metis, fall back to
  self-review silently if unavailable
- Exploration sources: openspec/specs, .sisyphus/notepads, .sisyphus/plans,
  .claude/plans, AGENTS.md, codebase
- Plan-to-spec: known paths first -> common locations -> keyword scan -> ask
- Handoff: "switch to Sisyphus for /opsx:apply" when specs are done
- Holistic thinking: trade-offs, second-order effects, architectural coherence,
  reference past decisions

### What MUST NOT Be in the Prompt

- Keyword scoring tables or detection heuristics
- Per-source-format mapping tables (Opus knows how to extract from markdown)
- OmO execution patterns: todo tracking, boulder continuation, delegation
  format (TASK/OUTCOME/TOOLS...), "human intervention is failure"
- Communication style from Sisyphus ("no preamble, no flattery, one-word answers")
- Anti-pattern blocking lists (for execution agents, not planners)
- Anything procedural that Opus can infer from a principle

## Output

Write the file to `agent/openspec-planner.md`. Create the `agent/` directory
if needed. The file should be ready to copy into any project's
`.opencode/agents/` directory.

After writing the file, report:
1. Total line count of the system prompt (body only, excluding frontmatter)
2. Which design doc sections were distilled into which prompt sections
3. Anything from the docs that you intentionally omitted and why
