---
name: solon-eval
description: Interactive evaluation harness for testing Solon's Phase 0 routing accuracy. Presents test prompts one at a time, user pastes back Solon's response, skill evaluates correctness.
user-invocable: true
disable-model-invocation: true
---

# Solon Eval

Interactive Phase 0 routing evaluation. Tests whether Solon correctly classifies intent and routes to the right skill.

## How It Works

1. Present a test prompt and its expected routing
2. User copies the prompt into a Solon session and pastes back the response
3. Evaluate whether the routing was correct
4. Track pass/fail across all test cases
5. Report summary at the end

## Test Cases

Run these in order. For each one, tell the user:
- The test number and category
- The exact prompt to paste into Solon
- What correct routing looks like (without revealing it to Solon)

Then wait for the user to paste Solon's response before evaluating.

### Test 1: Trivial
**Prompt**: "What file format does OpenSpec use for proposals?"
**Expected**: Answers directly. No skill invocation, no exploration, no brainstorming. Just a factual answer.
**Pass if**: Response is a short direct answer about proposal format. No mention of phases, exploration, or "let me dig into the codebase."
**Fail if**: Starts exploring files, invokes solon-spec, or begins a brainstorm flow.

### Test 2: Ambiguous
**Prompt**: "I want to change how auth works"
**Expected**: Asks one clarifying question. Does not immediately start exploring or proposing.
**Pass if**: Responds with a question like "Are you thinking about a specific part of auth?" or "Do you want to create a new spec or update an existing one?"
**Fail if**: Immediately starts reading specs and exploring, or begins artifact formation without clarifying.

### Test 3: Exploratory
**Prompt**: "I've been thinking about whether we need a caching layer — what do you think?"
**Expected**: Explores current state (reads specs, codebase) and discusses options/trade-offs. Does not immediately start writing a spec.
**Pass if**: Reads existing specs or codebase first, then discusses options. May ask about priorities or constraints. Conversational, not prescriptive.
**Fail if**: Starts writing proposal.md or design.md immediately. Or answers with a generic opinion without reading project state.

### Test 4: Explicit
**Prompt**: "Create a spec for adding WebSocket support to the API gateway"
**Expected**: Routes to solon-spec. Begins exploration (Phase 1) then moves into brainstorming with incremental artifacts.
**Pass if**: Starts by reading existing specs/codebase, then begins forming artifacts during conversation. Tracks assumptions and stages decisions via solon-mem.
**Fail if**: Asks clarifying questions instead of starting (that's Ambiguous routing). Or generates a complete spec monolith in one shot.

### Test 5: Plan-to-spec
**Prompt**: "Convert the migration plan in .sisyphus/plans/db-migration.md into an OpenSpec spec"
**Expected**: Routes to solon-spec with plan-to-spec handling. Reads the referenced plan file, maps content to OpenSpec artifacts.
**Pass if**: Reads the referenced plan file (or reports it doesn't exist). Maps motivation to proposal.md, technical decisions to design.md, tasks to tasks.md. Uses {{PLACEHOLDER}} for missing info.
**Fail if**: Asks what a plan-to-spec is. Or starts a fresh brainstorm ignoring the source document.

### Test 6: Reconcile
**Prompt**: "We finished implementing the auth rewrite. The spec needs to be updated with what actually changed — check the notepads"
**Expected**: Routes to reconcile. Reads implementation artifacts (notepads, handover docs) and compares against original spec.
**Pass if**: Reads reconcile sources (notepads, handover docs, or asks where they are). Enumerates deviations. Treats this as a structured diff, not a brainstorm.
**Fail if**: Starts brainstorming a new auth spec. Or treats it as an exploratory conversation.

### Test 7: Init
**Prompt**: "Set up OpenSpec in this project"
**Expected**: Routes to init. Runs pre-flight checks (git repo, not already initialized) then runs `openspec init --tools Claude`. No CLI existence check (solon-debug's job).
**Pass if**: Checks git status, checks if already initialized, then runs `openspec init`. On failure, references /solon-debug.
**Fail if**: Starts brainstorming what specs to write. Or runs `which openspec` as a pre-flight check. Or just runs the command without any checks.

### Test 8: Handoff
**Prompt**: "Generate a handoff document for the caching spec we just finished"
**Expected**: Routes to handoff. Writes a handoff document, then offers to trigger implementation planning.
**Pass if**: Writes or offers to write a handoff doc with spec reference, key decisions, constraints, and strategy. Offers planning agent dispatch.
**Fail if**: Starts a new brainstorm about caching. Or tries to implement the caching spec.

## Evaluation

After each test, report:
- **PASS** or **FAIL**
- Brief explanation of what was correct or incorrect
- If FAIL, what the model did vs what was expected

After all 8 tests, report summary:

```
Solon Phase 0 Routing Eval
===========================
Test 1 (Trivial):      PASS/FAIL
Test 2 (Ambiguous):    PASS/FAIL
Test 3 (Exploratory):  PASS/FAIL
Test 4 (Explicit):     PASS/FAIL
Test 5 (Plan-to-spec): PASS/FAIL
Test 6 (Reconcile):    PASS/FAIL
Test 7 (Init):         PASS/FAIL
Test 8 (Handoff):      PASS/FAIL

Score: X/8
```

If score is 7-8: Model handles Solon well.
If score is 5-6: Marginal — consider simplifying the agent for this model.
If score is < 5: Model cannot reliably run Solon.
