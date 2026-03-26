## ADDED Requirements

### Requirement: Multi-group search with minimum 2 groups
graphiti-egress SHALL execute searches using graphiti's search_memory_facts and search_nodes MCP tools. graphiti-egress MUST enforce a minimum of 2 group_ids on every search call. Single-group searches MUST be rejected because of a FalkorDB driver bug where the `handle_multiple_group_ids` decorator only activates when `len(group_ids) > 1`, causing single-group searches to use the initial driver context instead of the requested graph.

#### Scenario: Search with 2 groups
- **WHEN** graphiti-egress receives a query with group_ids ["mem_bricknet", "ndtn_preferences"]
- **THEN** graphiti-egress calls search_memory_facts with both group_ids and returns raw results

#### Scenario: Search with 3 groups (cross-reference)
- **WHEN** graphiti-egress receives a query with group_ids ["mem_bricknet", "mem_homelab", "ndtn_preferences"]
- **THEN** graphiti-egress calls search_memory_facts with all 3 group_ids and returns raw results

#### Scenario: Reject single-group search
- **WHEN** graphiti-egress receives a query with only 1 group_id
- **THEN** graphiti-egress rejects the search and reports that minimum 2 group_ids are required (FalkorDB driver bug)

### Requirement: Fact search
graphiti-egress SHALL support searching for facts using search_memory_facts. The caller provides the query text and group_ids. graphiti-egress returns raw, unfiltered results including all metadata (timestamps, validity status, source).

#### Scenario: Fact search returns raw results
- **WHEN** graphiti-egress executes a fact search
- **THEN** raw results are returned including fact text, timestamps, validity/expired status, and source metadata

### Requirement: Node search
graphiti-egress SHALL support searching for nodes (entities) using search_nodes. Node search supports an optional center_node_uuid parameter to find facts related to a specific entity.

#### Scenario: Node search for entity lookup
- **WHEN** graphiti-egress receives a node search for "Traefik"
- **THEN** graphiti-egress calls search_nodes and returns matching nodes with their UUIDs and properties

#### Scenario: Fact search centered on a node
- **WHEN** graphiti-egress receives a fact search with center_node_uuid from a prior node lookup
- **THEN** graphiti-egress calls search_memory_facts with the center_node_uuid to find related facts

### Requirement: Graceful degradation
graphiti-egress SHALL report clearly when the graphiti MCP server is unavailable or returns errors.

#### Scenario: MCP unavailable
- **WHEN** graphiti-egress attempts a search and the MCP server is unreachable
- **THEN** graphiti-egress reports that the knowledge graph is unavailable

#### Scenario: MCP returns error
- **WHEN** graphiti-egress attempts a search and the MCP server returns an error
- **THEN** graphiti-egress reports the error and that results may be incomplete
