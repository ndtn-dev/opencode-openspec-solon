## ADDED Requirements

### Requirement: Read entity dictionary
graphiti-entities SHALL read the entity dictionary from `.graphiti/entities.yaml` in the current project. If the file does not exist, graphiti-entities SHALL report that no dictionary is available and return the original input unchanged.

#### Scenario: Dictionary exists
- **WHEN** graphiti-entities reads `.graphiti/entities.yaml` and the file exists
- **THEN** the dictionary is loaded with canonical names and their synonyms

#### Scenario: Dictionary missing
- **WHEN** graphiti-entities attempts to read `.graphiti/entities.yaml` and the file does not exist
- **THEN** graphiti-entities reports no dictionary available and returns the original term unchanged

#### Scenario: Dictionary malformed
- **WHEN** graphiti-entities reads `.graphiti/entities.yaml` and the file contains invalid YAML (syntax errors, missing required fields, wrong types)
- **THEN** graphiti-entities reports the parse error, treats it as no dictionary available, and returns the original term unchanged

### Requirement: Query expansion for egress
graphiti-entities SHALL expand search terms using the entity dictionary. If a search term matches a synonym, the canonical name is added. If a search term matches a canonical name, its synonyms are added. Expansion is additive (the original term is always included) and one level only (no recursive expansion of synonyms of synonyms).

#### Scenario: Expand a synonym to canonical
- **WHEN** graphiti-entities expands "graphiti-mcp" and the dictionary has canonical="Graphiti MCP Server" with synonym "graphiti-mcp"
- **THEN** graphiti-entities returns ["graphiti-mcp", "Graphiti MCP Server"]

#### Scenario: Expand a canonical to synonyms
- **WHEN** graphiti-entities expands "Graphiti MCP Server" and the dictionary has synonyms ["graphiti-mcp", "graphiti mcp"]
- **THEN** graphiti-entities returns ["Graphiti MCP Server", "graphiti-mcp", "graphiti mcp"]

#### Scenario: No dictionary match
- **WHEN** graphiti-entities expands "kubernetes" and no dictionary entry matches
- **THEN** graphiti-entities returns ["kubernetes"] (original term only)

#### Scenario: One level expansion only
- **WHEN** graphiti-entities expands a term and finds a match
- **THEN** only direct synonyms/canonical are added; synonyms of synonyms are NOT recursively expanded

### Requirement: Synonym lookup for normalization
graphiti-entities SHALL provide synonym-to-canonical lookup for use by graphiti-normalizer during ingress. Given a term, return the canonical name if the term is a known synonym, or the term itself if no match exists.

#### Scenario: Lookup a known synonym
- **WHEN** graphiti-normalizer asks graphiti-entities for the canonical name of "graphiti-mcp"
- **THEN** graphiti-entities returns "Graphiti MCP Server"

#### Scenario: Lookup an unknown term
- **WHEN** graphiti-normalizer asks graphiti-entities for the canonical name of "kubernetes"
- **THEN** graphiti-entities returns "kubernetes" (unchanged)
