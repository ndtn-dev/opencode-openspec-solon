---
name: solon-handoff
description: Implementation handoff skill with auto-triggered Prometheus planning
compatibility: opencode
metadata:
  category: spec
  triggers:
    - handoff
    - hand off
    - implementation plan
    - create plan from spec
---

# Solon Handoff Skill

## Role

Loaded by a sub-agent after Solon completes Phase 6. Generates an implementation handoff document and auto-triggers Prometheus to create an implementation plan from the completed spec.

## Step 1 — Generate Handoff Document

Write `.sisyphus/handover/[name].md` with:

- **Spec reference**: `openspec/changes/[name]/` — proposal.md, design.md, tasks.md, specs/
- **Key decisions summary**: Implementation-relevant decisions from design.md
- **Implementation constraints**: Files to not touch, required patterns, hard non-goals
- **Suggested strategy**: Parallelism opportunities, sequencing, risk areas

## Step 2 — Auto-trigger Prometheus (Decision #18)

Dispatch Prometheus **synchronously** to generate an implementation plan.

> **Decision #21 — Synchronous**: `run_in_background=false` so Prometheus questions propagate to the user through the main agent. The user can watch and interact with the planning process.

```
task(
  subagent_type='prometheus',
  load_skills=[],
  run_in_background=false,
  prompt='Create an implementation plan from the spec at openspec/changes/[name]/. Key constraints: [constraints from handoff doc]. Implementation files: [paths from tasks.md]. Spec files: openspec/changes/[name]/proposal.md, openspec/changes/[name]/design.md, openspec/changes/[name]/tasks.md, openspec/changes/[name]/specs/. Write the plan to .sisyphus/plans/.'
)
```

Populate `[name]`, constraints, and file paths from the actual spec before dispatching.

## Step 3 — Failure Handling

If Prometheus dispatch fails, the handoff document is still complete. Report to the main agent:

```
Prometheus couldn't be triggered automatically. To create an implementation plan manually,
switch to your main agent and say:

  "Create a plan from the spec at openspec/changes/[name]/"
```

## Post-Implementation Workflow

The handoff document MUST include a section referencing these post-implementation steps (in order). These are for the implementer's awareness only -- solon-handoff does NOT invoke them.

1. **Apply**: `openspec-apply-change` -- Implements the delta specs from the change directory to the baseline specs.
2. **Verify**: `openspec-verify-change` -- Validates that implementation matches spec requirements.
3. **Archive**: `openspec-archive-change` -- Archives the completed change and merges delta specs into baseline.

Use the exact skill names above in the handoff document.

## Return

1. Handoff document path: `.sisyphus/handover/[name].md`
2. Either: Prometheus plan path (`.sisyphus/plans/[name].md`) on success, or manual instructions on failure
