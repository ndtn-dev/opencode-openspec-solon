# Prompt Engineering Principles for This Agent

Key insights from research into OmO, opencode-plugin-openspec, and OpenCode
agent system that inform how the agent .md file should be written.

---

## Target Model

Primary: **Opus 4.6** (anthropic/claude-opus-4-6)
Secondary: GPT-5.4 (should work without a separate prompt variant)

## Prompt Length

- **Target: 150-250 lines** for the agent .md body (system prompt)
- OmO's Sisyphus prompt is ~1,100 lines but is dynamically constructed at
  runtime -- only relevant sections are injected per context
- A static .md file loads the entire prompt every time, so it must be tighter
- Beyond ~300 lines: instruction dilution (model deprioritizes later rules),
  conflicting rules, and rigidity increase

## Core Principle: Describe Behavior, Not Algorithms

Opus doesn't need procedural flowcharts in the prompt. It needs to understand
the **intent and principles**, then it naturally handles edge cases.

**Bad** (over-specified):
```
Score the document against 6 keyword categories. If 3+ categories have
multiple hits, classify as plan-to-spec with medium confidence. If 1-2
categories match, drop to Tier 4 and ask the user...
```

**Good** (principle-driven):
```
Check known plan paths first (.sisyphus/plans/, .claude/plans/), then
common locations (PLAN.md, docs/rfcs/). For any other .md, scan for
planning content. If clearly a plan, proceed. If unclear, ask.
```

Same behavior, 1/4 the tokens. Opus infers the scoring heuristic.

## Prompt Structure: XML Tags

The opencode-plugin-openspec uses `<Role>`, `<Context>`, `<Rules>` XML tags.
This is effective for Claude models -- XML tags create clear section boundaries
that the model respects.

Recommended structure for our agent:

```markdown
<Role>
  Identity and core purpose (2-3 sentences)
</Role>

<Principles>
  5-7 high-level behavioral principles
</Principles>

<Phases>
  The 5 phases described concisely
</Phases>

<Rules>
  Specific behavioral rules organized by topic
</Rules>
```

## Claude-Style with Principles

Research finding: Claude performs best with detailed rules and checklists.
GPT performs best with fewer principles.

**Solution**: Write Claude-style (detailed rules) but state the principle
behind each rule. Opus follows the rule. GPT follows the principle. Same
prompt, both work.

**Example**:
```
Run a clearance check before generating artifacts. The principle: never
generate from incomplete understanding -- incomplete specs create more
work than no specs.
```

## Temperature

- **0.2** for this agent -- it's a planner/designer, needs consistency
  but not zero-creativity
- The plugin uses no explicit temperature (defaults to 0)
- OmO's Metis uses 0.3 (higher variance for creative gap detection)
- 0.2 is the sweet spot: deterministic enough for structured specs,
  flexible enough for brainstorming

## Permission Sandboxing

Prompt rules ("don't write code") are the first line of defense.
YAML permission config is the enforcement layer. Both are needed.

The plugin's approach (prompt says no + permissions restrict) is correct.
Never rely on the prompt alone for access control.

## What NOT to Include in the Prompt

- Keyword scoring tables (Opus infers this)
- Per-source-format mapping tables (Opus knows how to extract from markdown)
- Anti-pattern lists from OmO (designed for execution agents, not planners)
- Todo tracking / boulder continuation (not relevant to this agent type)
- Delegation format (6-section TASK/OUTCOME/TOOLS -- not needed)
- "Human intervention is failure" (opposite of this agent's philosophy)
- Communication style rules from Sisyphus ("no preamble, one-word answers")

## What MUST Be in the Prompt

- Identity as a design partner (not executor)
- The 5 phases (intent -> explore -> brainstorm -> gap analysis -> finalize)
- Intent classifications with skill auto-triggers
- Assumption tracking tiers (small/medium/big)
- Clearance check criteria (as conversational guide, not blocking gate)
- Gap analysis behavior (try @metis, fall back to self-review)
- Exploration sources (.sisyphus, openspec, codebase)
- Plan-to-spec conversion principle (known paths -> common paths -> scan -> ask)
- Handoff instructions (switch to Sisyphus for /opsx:apply)
- Holistic thinking reminders (trade-offs, second-order effects, coherence)
