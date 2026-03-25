---
name: solon-handoff
description: Generate implementation handoff document from completed specs and optionally trigger implementation planning.
---

# Solon Handoff Skill

## Role

Loaded after Solon completes Phase 6. Generates an implementation handoff document and offers to trigger implementation planning.

## Step 1 — Generate Handoff Document

Write `.sisyphus/handover/[name].md` with:

- **Spec reference**: `openspec/changes/[name]/` — proposal.md, design.md, tasks.md, specs/
- **Key decisions summary**: Implementation-relevant decisions from design.md
- **Implementation constraints**: Files to not touch, required patterns, hard non-goals
- **Suggested strategy**: Parallelism opportunities, sequencing, risk areas

## Step 2 — Offer Implementation Planning

After writing the handoff document, offer to dispatch an implementation planning agent:

"Handoff document written. Want me to dispatch a planner agent to create an implementation plan from this spec?"

If the user accepts, dispatch an Agent with prompt:
"Create an implementation plan from the spec at openspec/changes/[name]/. Key constraints: [constraints from handoff doc]. Write the plan to .sisyphus/plans/."

Populate `[name]`, constraints, and file paths from the actual spec before dispatching.

## Step 3 — Failure Handling

If the planning agent dispatch fails, the handoff document is still complete. Report:

```
Planning agent couldn't be triggered automatically. To create an implementation plan manually,
say: "Create a plan from the spec at openspec/changes/[name]/"
```

## Return

1. Handoff document path: `.sisyphus/handover/[name].md`
2. Either: Plan path (`.sisyphus/plans/[name].md`) on success, or manual instructions on failure
