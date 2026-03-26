# solon-agent-lean

## Purpose

Defines the lean Solon agent configuration, removing graphiti/ledger dependencies from DoubleWriting gates and PathRestrictions. Solon no longer owns `.graphiti/` state or performs ledger auto-verification.

## Requirements

### Requirement: DoubleWriting confirmation gates
The DoubleWriting section SHALL require explicit user confirmation for critical transitions. The rules MUST include: "Reconcile -> Spec requires explicit confirmation before loading solon-spec" and "Confirmation must be user-authored in the active conversation; no implied consent." The rules SHALL NOT reference "ingress checkpoints" or "ingress checkpoint confirmation before entering Phase 6 writes."

#### Scenario: DoubleWriting without ingress checkpoint language
- **WHEN** the DoubleWriting section is evaluated
- **THEN** it requires confirmation for Reconcile -> Spec transitions and user-authored confirmation, without mentioning ingress checkpoints

### Requirement: PathRestrictions without .graphiti/
The PathRestrictions section SHALL list permitted write directories as: `openspec/`, `specs/`, `.solon/`. The PathRestrictions section SHALL NOT include `.graphiti/` as a permitted directory. Clio owns `.graphiti/` state.

#### Scenario: .graphiti/ excluded from write paths
- **WHEN** solon attempts to write to `.graphiti/`
- **THEN** the operation is outside PathRestrictions and is not permitted

#### Scenario: .solon/ remains a permitted write path
- **WHEN** solon writes to `.solon/staging/` or `.solon/checkpoints/`
- **THEN** the operation is within PathRestrictions and is permitted
