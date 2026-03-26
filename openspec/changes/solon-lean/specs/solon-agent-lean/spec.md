## MODIFIED Requirements

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

## REMOVED Requirements

### Requirement: LedgerAutoVerify section
**Reason**: The LedgerAutoVerify section dispatched a background Agent to verify ledger status using graphiti-ledger-status on every Solon activation. Ledger health is now Clio's responsibility (Clio routes status requests to graphiti-ledger-status). Solon no longer has a graphiti dependency.
**Migration**: Remove the entire `<LedgerAutoVerify>` section from solon.md. Ledger verification is performed by Clio.

### Requirement: .graphiti/ path restriction
**Reason**: Solon no longer writes to `.graphiti/` directory. All graphiti state is owned by Clio.
**Migration**: Remove `.graphiti/` from the PathRestrictions permitted directory list.

### Requirement: Ingress checkpoint confirmation in DoubleWriting
**Reason**: The "Ingress checkpoints require explicit confirmation before entering Phase 6 writes" rule referenced the old Phase 5 ingress checkpoint which no longer exists. Phase 5 is now a simpler finalize step that does not require explicit confirmation.
**Migration**: Remove the ingress checkpoint confirmation line from DoubleWriting. The Phase 5 checkpoint file serves as the structural gate for Phase 6.
