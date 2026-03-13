---
id: graphql-query
name: GraphQL Query or Mutation
format: json
category: api
tags: [graphql, query, mutation, api, schema]
description: A GraphQL operation with variables, expected return types, and endpoint config. Enables agents to issue typed GraphQL requests and validate response shape.
author: mentiko
version: 1.0
schema:
  type: object
  properties:
    operation_type:
      type: string
      enum: [query, mutation, subscription]
      description: GraphQL operation type
    operation_name:
      type: string
      description: PascalCase operation name matching the document
    endpoint:
      type: string
      format: uri
      description: GraphQL endpoint URL
    query:
      type: string
      description: Full GraphQL document string including operation type and name
    variables:
      type: object
      description: Variable values to pass with the operation
    variable_types:
      type: object
      description: GraphQL type signatures for each variable (e.g. {"userId": "ID!", "limit": "Int"})
      additionalProperties:
        type: string
    headers:
      type: object
      description: Additional HTTP headers for this request
      additionalProperties:
        type: string
    expected_types:
      type: array
      items:
        type: string
      description: GraphQL type names expected in the response (for validation)
    auth_secret_key:
      type: ["string", "null"]
      description: Secret store key for the bearer token (null if public)
    timeout_ms:
      type: integer
      minimum: 1
      description: Request timeout in milliseconds
    persisted_query_hash:
      type: ["string", "null"]
      description: SHA-256 hash for APQ (Automatic Persisted Queries), null if not used
  required: [operation_type, operation_name, endpoint, query, variables, expected_types, timeout_ms]
validation_rules:
  - operation_type must match the keyword at the start of the query string
  - operation_name must appear in the query string
  - query must be a valid GraphQL document (parseable, non-empty)
  - variable_types keys must match all variables declared in the query with $ prefix
  - variables keys must be a subset of variable_types keys
  - endpoint must be an absolute URI with http or https scheme
  - expected_types must reference real GraphQL type names (PascalCase, non-empty strings)
  - subscription type requires websocket-capable endpoint (wss:// or a note in headers)
related_artifacts: [api-response, openapi-spec, http-request-spec]
---

```json
{
  "operation_type": "mutation",
  "operation_name": "CreateIssue",
  "endpoint": "https://api.linear.app/graphql",
  "query": "mutation CreateIssue($title: String!, $description: String, $teamId: String!, $priority: Int, $labelIds: [String!]) {\n  issueCreate(\n    input: {\n      title: $title\n      description: $description\n      teamId: $teamId\n      priority: $priority\n      labelIds: $labelIds\n    }\n  ) {\n    success\n    issue {\n      id\n      identifier\n      title\n      url\n      priority\n      state {\n        id\n        name\n        type\n      }\n      team {\n        id\n        key\n        name\n      }\n      createdAt\n    }\n  }\n}",
  "variables": {
    "title": "Fix: API rate limiter returns 500 instead of 429 under burst load",
    "description": "## Observed\nUnder sustained burst (>500 req/s), the rate limiter middleware panics and returns HTTP 500 instead of 429 Too Many Requests.\n\n## Expected\n429 with `Retry-After` header set to the reset window.\n\n## Steps to reproduce\n1. Run `k6 run tests/load/burst.js`\n2. Watch status codes — ~2% are 500",
    "teamId": "TEAM_ENG_BACKEND",
    "priority": 1,
    "labelIds": ["LABEL_BUG", "LABEL_API"]
  },
  "variable_types": {
    "title": "String!",
    "description": "String",
    "teamId": "String!",
    "priority": "Int",
    "labelIds": "[String!]"
  },
  "headers": {
    "Content-Type": "application/json"
  },
  "expected_types": ["IssuePayload", "Issue", "WorkflowState", "Team"],
  "auth_secret_key": "LINEAR_API_KEY",
  "timeout_ms": 10000,
  "persisted_query_hash": null
}
```
