# solon-mem

## Purpose

Defines the solon-mem decision staging skill. solon-mem handles per-decision classification (key/routine), local staging file persistence, Clio dispatch, supersession tracking, and Phase 5 evolution summaries.

## Requirements

### Requirement: Two-tier decision classification
solon-mem SHALL classify each decision as either "key" or "routine." A decision is "key" if it meets ANY of the following criteria: evolved (changed or superseded during conversation), architectural (affects system structure, data flow, API boundaries, event models, or component relationships), or contentious (user debated alternatives or explicitly chose between options). All other decisions — accepted without debate and not affecting system structure — are "routine." When classification is ambiguous, solon-mem SHALL default to "key." solon-mem MUST NOT use a three-tier or multi-tier classification system.

#### Scenario: Classify an architectural decision as key
- **WHEN** solon-mem receives a decision about system structure (e.g., "use push model over pull model", "hierarchical event filter with wildcards", "batch ingress per invocation instead of per-decision")
- **THEN** solon-mem classifies it as "key"

#### Scenario: Classify a data-flow or API boundary decision as key
- **WHEN** solon-mem receives a decision that determines how data moves between components or defines an interface contract (e.g., "structured payload format for Clio dispatch", "single staging file per spec")
- **THEN** solon-mem classifies it as "key"

#### Scenario: Classify a straightforward decision as routine
- **WHEN** solon-mem receives a decision that was accepted without debate and does not affect system structure (e.g., "use kebab-case for file names", "include timestamp in header")
- **THEN** solon-mem classifies it as "routine"

#### Scenario: Classify an evolved decision as key
- **WHEN** solon-mem receives a decision that supersedes a prior decision from the same session
- **THEN** solon-mem classifies it as "key"

#### Scenario: Default ambiguous classification to key
- **WHEN** solon-mem cannot confidently determine whether a decision is routine or key
- **THEN** solon-mem classifies it as "key"

### Requirement: Session ID resolution
solon-mem SHALL obtain the Claude session ID from the conversation context. In Claude Code, the session ID is derived from the `CLAUDE_SESSION_ID` environment variable if available, or from the conversation's unique identifier. If the session ID cannot be determined by either method, solon-mem SHALL generate a fallback identifier using the current ISO 8601 timestamp (e.g., `session-2026-03-25T14:30:00`). The resolved session ID MUST be used consistently for all operations within the remainder of the session.

#### Scenario: Session ID from environment variable
- **WHEN** solon-mem initializes and `CLAUDE_SESSION_ID` is set
- **THEN** solon-mem uses the value of `CLAUDE_SESSION_ID` as the session ID for all staging entries and dispatches

#### Scenario: Session ID unavailable
- **WHEN** solon-mem initializes and the session ID cannot be determined from the environment variable or conversation context
- **THEN** solon-mem generates a fallback identifier using the current ISO 8601 timestamp (e.g., `session-2026-03-25T14:30:00`) and uses it consistently for the remainder of the session

#### Scenario: Session ID consistency within a session
- **WHEN** solon-mem resolves a session ID (from any source)
- **THEN** the same session ID is used for all staging entries, Clio dispatches, checkpoint files, and the staging file header for the duration of the session

### Requirement: Local staging file persistence
solon-mem SHALL write every decision from the caller's prompt to a local staging file at `.solon/staging/{spec-name}.md`. The staging file MUST be written regardless of Clio availability. solon-mem MUST process ALL decisions provided in a single invocation — it MUST NOT return after writing only the first decision. Processing follows three phases: setup (file creation or session handling), iteration (write each decision entry), and completion (verify count and proceed to Clio dispatch). Each entry MUST include: a sequential decision ID (D-001, D-002, ...), the current phase, classification (key/routine), Claude session ID, verbose context with raw conversation excerpts and quoted user/assistant statements, and the decision text.

#### Scenario: Write first decision to staging file
- **WHEN** solon-mem stages a decision for a spec named "api-gateway" and no staging file exists
- **THEN** solon-mem creates `.solon/staging/api-gateway.md` with a header containing spec name, session ID, and date, and writes the decision as entry D-001

#### Scenario: Append subsequent decision to existing staging file
- **WHEN** solon-mem stages a second decision for spec "api-gateway" and the staging file already exists with D-001
- **THEN** solon-mem appends the decision as entry D-002 to the existing staging file

#### Scenario: Process all decisions in a single invocation
- **WHEN** solon-mem receives a prompt containing 4 decisions to stage
- **THEN** solon-mem writes all 4 entries (D-001 through D-004, or continuing from the last existing ID) to the staging file before proceeding to Clio dispatch
- **AND** solon-mem does NOT return or yield control after writing fewer than 4 entries

#### Scenario: Completion verification
- **WHEN** solon-mem finishes writing decision entries
- **THEN** solon-mem verifies the count of entries written matches the count of decisions received and reports: "Staged N decisions (D-001 through D-NNN)"

#### Scenario: Resume same session with existing staging file
- **WHEN** solon-mem stages decisions for spec "api-gateway" and a staging file exists whose header session ID matches the current session ID
- **THEN** solon-mem appends to the existing staging file, continuing the decision ID sequence

#### Scenario: New session with existing staging file from different session
- **WHEN** solon-mem stages a decision for spec "api-gateway" and a staging file exists whose header session ID does NOT match the current session ID
- **THEN** solon-mem renames the existing file to `.solon/staging/api-gateway.{old-session-id}.md` (archiving it), then creates a new `.solon/staging/api-gateway.md` with a fresh header for the current session and writes the decision as entry D-001

#### Scenario: Archived staging file naming
- **WHEN** a staging file is archived due to a session ID mismatch
- **THEN** the archived file name includes the old session ID as a suffix (e.g., `.solon/staging/api-gateway.session-2026-03-24T10:00:00.md`) and its contents are preserved unmodified

#### Scenario: Include verbose context in staging entry
- **WHEN** solon-mem stages a decision
- **THEN** the staging entry includes raw conversation excerpts and quoted user/assistant statements that led to the decision

#### Scenario: Include session ID on every entry
- **WHEN** solon-mem stages a decision
- **THEN** the staging entry includes the Claude session/conversation ID

### Requirement: Decision supersession tracking
solon-mem SHALL track when a new decision supersedes a prior decision within the same staging file. The new entry MUST include a "Supersedes" reference to the prior decision ID. The superseded entry MUST be annotated with `[SUPERSEDED by D-NNN]` in its title. The superseded entry's status MUST be set to "superseded."

#### Scenario: Supersede a prior decision
- **WHEN** solon-mem stages decision D-005 that replaces the approach from D-002
- **THEN** D-005 includes "Supersedes: D-002" and D-002's title is annotated with `[SUPERSEDED by D-005]` and its status is set to "superseded"

#### Scenario: Preserve superseded entry content
- **WHEN** a decision is superseded
- **THEN** the original decision entry content is preserved in the staging file (not deleted or overwritten)

### Requirement: Clio batch dispatch per invocation
solon-mem SHALL dispatch all staged decisions to Clio in a single background agent call after writing all entries to the staging file. The dispatch MUST use a structured batch payload containing: spec name, session ID, group_id, and a numbered list of decisions where each decision includes its title, classification (key/routine), context (verbose excerpt), decision text, and supersedes reference (if applicable). The group_id is determined by solon-mem from the project's .graphiti/config.yaml or from the caller's context. If group_id cannot be determined, solon-mem SHALL still write to the staging file but skip the Clio dispatch and log that group_id was unavailable. solon-mem MUST NOT dispatch Clio more than once per invocation.

#### Scenario: Batch dispatch to Clio when available
- **WHEN** solon-mem stages 4 decisions and Clio is available and group_id is known
- **THEN** solon-mem dispatches a single Clio agent in the background with all 4 decisions in a structured batch payload

#### Scenario: Batch payload structure
- **WHEN** solon-mem dispatches to Clio
- **THEN** the payload includes a header (spec name, session ID, group_id) and a numbered `Decisions:` list where each item contains title, classification, context, decision text, and optional supersedes reference

#### Scenario: Skip Clio dispatch when group_id unavailable
- **WHEN** solon-mem stages decisions but group_id cannot be determined from .graphiti/config.yaml or caller context
- **THEN** solon-mem writes all decisions to the staging file, skips the Clio dispatch, and logs that group_id was unavailable

#### Scenario: Graceful degradation when Clio is unavailable
- **WHEN** solon-mem stages decisions and Clio is unavailable (dispatch fails or agent not found)
- **THEN** solon-mem continues without error; the staging file is the durable record

#### Scenario: One dispatch per invocation
- **WHEN** solon-mem processes multiple decisions in a single invocation
- **THEN** solon-mem dispatches exactly one Clio agent call containing all decisions, not one call per decision

### Requirement: Phase 5 evolution summary
solon-mem SHALL produce an evolution summary when invoked at Phase 5. The summary MUST be generated by reading the full staging file for the current spec. The summary MUST describe: which decisions evolved (were superseded and why), what was finalized, and the overall narrative arc of the session's decisions. solon-mem SHALL write the evolution summary to the staging file and dispatch it to Clio as an evolution summary (separate knowledge type from individual decisions).

#### Scenario: Generate evolution summary at Phase 5
- **WHEN** solon-mem is invoked for Phase 5 summary and the staging file contains decisions D-001 through D-008 with two supersessions
- **THEN** solon-mem produces a summary describing the evolution of decisions, including what changed and why, and appends it to the staging file

#### Scenario: Dispatch evolution summary to Clio
- **WHEN** solon-mem produces an evolution summary and Clio is available
- **THEN** solon-mem dispatches the summary to Clio as an evolution summary with spec name, session ID, group_id, and summary text

#### Scenario: Evolution summary without Clio
- **WHEN** solon-mem produces an evolution summary and Clio is unavailable
- **THEN** solon-mem writes the summary to the staging file and continues without error

### Requirement: Staging file format
solon-mem SHALL use the following markdown format for the staging file header and decision entries. The header MUST include the spec name, session ID, and start date. Each decision entry MUST use the structured format with decision ID, phase, classification, session ID, context block, decision text, and optional supersedes/status fields.

#### Scenario: Staging file header format
- **WHEN** solon-mem creates a new staging file
- **THEN** the header follows the format: `# Decision Ledger: {spec-name}` with `Session: {id} | Started: {date}`

#### Scenario: Decision entry format
- **WHEN** solon-mem writes a decision entry
- **THEN** the entry uses the format: `## D-NNN: {title}` with bullet fields for Phase, Classification, Session, Context (with quoted excerpts), Decision, and optional Supersedes/Status
