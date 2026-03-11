# Persona Engineering

How the role/title you assign in a system prompt affects model behavior,
and which persona fits which agent type.

---

## Why It Matters

The persona phrase in a system prompt ("You are a senior architect") acts as
a behavioral prior. The model has trained on millions of examples of how
people in that role communicate, what they prioritize, and what they produce.
The persona sets the baseline vibe; the rest of the prompt refines it.

It's a nudge, not a deterministic switch. 157 lines of explicit behavioral
rules matter far more than the title. But the wrong persona creates friction --
the model's instincts fight the rules instead of reinforcing them.

---

## Persona Comparison

| Persona | Model infers | Biased toward | Best for |
|---------|-------------|---------------|----------|
| **Senior engineer** | Writes good code, follows best practices, ships reliably | Implementation, code output | Execution agents (Sisyphus, Hephaestus) |
| **Tech lead** | Coordinates people, makes pragmatic trade-offs, unblocks teams | Prioritization, delegation, team dynamics | Orchestration agents, project coordination |
| **Staff engineer** | Cross-team technical leadership, deep expertise, strong opinions | Opinionated review, pushing back on decisions | Review/validation agents (Momus-like) |
| **Architect** | Systems thinking, trade-off analysis, long-term vision | Design over implementation | Planning agents, spec writers |
| **Senior architect** | Architect + experience + patience + collaborative instinct | Thoughtful design, listening before drawing | Collaborative design partners |

---

## Modifier Effects

### "Senior" modifier

Adds patience, collaborative instinct, and willingness to listen before
acting. A "junior architect" might over-assert or jump to conclusions.
A "senior architect" asks questions first, considers context, and explains
reasoning. Use "senior" when the agent should be thoughtful and measured.

### "Principal" / "Distinguished" modifier

Adds authority and conviction. The model becomes more opinionated and less
likely to defer. Can be useful for review agents that need to push back
firmly. Risky for collaborative agents -- may override user preferences.

### No modifier (just "architect" / "engineer")

Neutral baseline. The model follows the explicit rules more closely without
strong persona-driven instincts pulling in any direction. Good when you want
maximum control via the prompt rules themselves.

---

## Anti-Patterns

### "You are an AI assistant"

Generic, produces generic behavior. The model falls back to safe,
people-pleasing defaults. Avoid for specialized agents.

### "You are the best / world-class / expert"

Superlatives add confidence but also reduce self-correction. The model
becomes less likely to say "I'm not sure" or "let me check." Risky for
planning agents where catching uncertainty is valuable.

### "You are a 10x developer"

Biases heavily toward speed and volume of output. The model tries to
produce more, faster, with less deliberation. Opposite of what a
design partner needs.

### Mixing execution and design personas

"You are a senior architect who also implements." Contradictory -- the model
oscillates between designing and coding. Pick one role per agent. Use
handoffs for the transition.

---

## For This Agent

**Chosen persona**: "senior architect"

**Why**: Systems thinking + patience + collaborative instinct. The "senior"
modifier adds the "listen before drawing" behavior that distinguishes this
agent from an eager junior planner who jumps to artifact generation.

**What it reinforces**: Asking "why" before "how", surfacing trade-offs,
considering second-order effects, deferring to user priorities.

**What the rules must still enforce**: The persona doesn't inherently prevent
code output (architects sometimes prototype). The explicit "you do not write
code" rule in the prompt is still necessary. Persona sets the vibe, rules
set the boundaries.

---

## General Guidance for Agent Persona Selection

1. **Match persona to output type.** If the agent produces code, use an
   engineer persona. If it produces designs, use an architect persona.
   If it produces reviews, use a staff/principal engineer persona.

2. **Match modifier to interaction style.** "Senior" for patient and
   collaborative. "Principal" for authoritative and opinionated. No modifier
   for neutral/rule-driven.

3. **One persona per agent.** Don't combine "architect who also codes."
   Separate agents, separate personas, clean handoffs.

4. **Persona + rules should reinforce, not fight.** If you tell the model
   it's an architect but then give it 50 rules about code style, the rules
   win but the model burns effort resolving the contradiction. Align them.
