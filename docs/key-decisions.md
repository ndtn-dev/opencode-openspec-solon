# Key Decisions

Decisions made during the design of this agent, with rationale.

---

## 1. Custom .md Agent, Not Plugin

**Decision**: Build a `.opencode/agents/openspec-planner.md` file, not an npm plugin.

**Rationale**: The opencode-plugin-openspec npm package (150 LOC, 4 files) does
nothing that a single .md file can't do. The plugin's value is in its prompt and
permission config -- both expressible in YAML frontmatter + markdown body. A .md
file is simpler to maintain, customize, and doesn't create an npm dependency.

**Trade-off**: No auto-detection of OpenSpec projects. The agent is always
available regardless of whether openspec/ exists. This is acceptable -- the
agent handles non-OpenSpec contexts gracefully by exploring first.

---

## 2. Brainstorm-First, Not Monolith-Plan

**Decision**: Artifacts form incrementally during conversation, not after a
long planning interview.

**Rationale**: Prometheus's interview-then-generate pattern creates anxiety --
you wait through extensive questioning, then get a monolith that may be
significantly off. Incremental formation lets the user see the spec taking
shape, push back early, and course-correct without wasting a full generation.

**Aligns with**: OpenSpec's philosophy ("fluid not rigid, iterative not waterfall").

---

## 3. Three-Tier Assumption Tracking

**Decision**: Small (assume+track), Medium (placeholder+continue), Big (stop+ask).

**Rationale**: Solves the ask-too-much vs ask-too-little problem. Small
assumptions keep momentum. Placeholders with suggestions are easier to confirm
than open-ended questions. Big decisions get the attention they deserve.

**Classification heuristic**: Cost of being wrong < 5 min fix = Tier 1.
Rest of artifact still works without this = Tier 2. Everything else = Tier 3.

---

## 4. Optional Gap Analysis with Metis Fallback

**Decision**: Prompt user "Want gap analysis?" If yes, try @metis first, fall
back to self-review silently.

**Rationale**: Works with or without OmO installed. Metis provides fresh-eyes
review (different model, no sunk cost). Self-review is ~60-70% as effective
but always available. Making it optional avoids latency for small changes.

**Note**: Prometheus runs Metis again during execution planning, so this is an
early catch, not the last line of defense.

---

## 5. Intent Gate with Skill Auto-Triggers

**Decision**: Classify intent (trivial/exploratory/explicit/plan-to-spec/
open-ended/ambiguous) and auto-trigger the appropriate OpenSpec skill.

**Rationale**: Prevents the most common failure -- every message triggers the
full proposal pipeline. A quick question shouldn't generate a 200-line proposal.
Auto-triggering skills reduces manual ceremony.

**Plan-to-spec detection**: Tiered approach (known paths -> common paths ->
keyword scan -> ask). Evaluated BEFORE other intents because it has the most
concrete signals (file paths, conversion verbs).

---

## 6. Design Partner Identity, Not Executor

**Decision**: Fundamentally different tone and behavior from OmO execution agents.

**Key inversions from OmO patterns**:
- Human input = the entire point (not a failure signal)
- Explain reasoning and trade-offs (not terse one-word answers)
- Clearance check = conversation guide (not blocking gate)
- Explore-before-ask for facts, but actively discuss design preferences
- No todo tracking, boulder continuation, or delegation format
- No "start work immediately" -- "let me understand first"

---

## 7. .sisyphus as Design Knowledge Source

**Decision**: Read .sisyphus/notepads/ and plans/ during exploration, not just
openspec/ artifacts.

**Rationale**: Notepads contain accumulated learnings, decisions, and known
issues from past execution. This prevents the planner from proposing designs
that contradict lessons already learned. Plans provide context on what's been
built and how.

---

## 8. Plan-to-Spec Supports Any Markdown Source

**Decision**: Not limited to Sisyphus plans. Supports Claude plans, RFCs, ADRs,
PRDs, and freeform notes.

**Rationale**: Users create planning docs in many formats. The conversion
principle is the same regardless of source: extract what maps to OpenSpec
artifacts, placeholder what doesn't, flag unjustified decisions as assumptions.

**Detection tiered by confidence**: Known paths (auto) -> common paths (verify) ->
keyword scan (heuristic) -> ask user (fallback). This ordering ensures the
agent is right most of the time without being rigid.

---

## 9. Opus 4.6 Primary, GPT-Compatible Without Separate Prompt

**Decision**: Write one prompt that works for both Claude and GPT models.

**Rationale**: OmO maintains separate prompt variants per model family (Claude
~1,100 lines, GPT ~300 lines, Gemini with 6 enhancement layers). This is
necessary for their execution agents but overkill for a planning agent.

**Technique**: Write Claude-style (detailed rules) but state the principle
behind each rule. Opus follows the rule, GPT follows the principle.

---

## 10. Prompt Target: 150-250 Lines

**Decision**: Keep the agent .md system prompt between 150-250 lines.

**Rationale**: The design docs are ~1,200 lines of specification. Flattening
all of that into the prompt causes instruction dilution (model deprioritizes
later rules), conflicting rules, and rigidity. Opus performs better with
principled descriptions than procedural algorithms.

**The docs are the spec. The prompt is the distillation.**

---

## 11. task: true with Optional Metis

**Decision**: Enable the `task` tool so the agent CAN delegate to @metis if
available, but don't make it mandatory.

**Rationale**: If OmO is installed, Metis delegation provides genuine fresh-eyes
review. If not installed, the task call fails silently and self-review kicks in.
No hard dependency on OmO.

---

## 12. Skill Access

**Decision**: Allow all skills, especially `opsx:*` and `openspec-*`.

**Rationale**: The agent needs to auto-trigger OpenSpec skills based on intent
classification. Restricting skill access would break the core workflow.
