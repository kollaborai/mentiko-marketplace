---
id: json-schema-def
name: JSON Schema Definition
format: json
category: data
tags: [json-schema, validation, data, schema, contract]
description: A self-contained JSON Schema definition for data validation. Includes the schema itself plus valid and invalid examples for agent-driven contract testing.
author: mentiko
version: 1.0
schema:
  type: object
  properties:
    schema_id:
      type: string
      description: Unique identifier for this schema (URI or short ID)
    title:
      type: string
      description: Human-readable schema name
    description:
      type: string
      description: What data this schema validates and in what context it's used
    json_schema_version:
      type: string
      enum: ["draft-07", "draft-2019-09", "draft-2020-12"]
      description: JSON Schema draft version
    schema:
      type: object
      description: The actual JSON Schema object (must be a valid JSON Schema document)
    example_valid:
      type: object
      description: A concrete example that passes validation against schema
    example_invalid:
      type: array
      description: One or more examples that fail validation, each with an explanation
      items:
        type: object
        properties:
          data:
            description: The invalid data sample
          reason:
            type: string
            description: Human-readable explanation of why validation fails
        required: [data, reason]
    used_by:
      type: array
      items:
        type: string
      description: API routes, agents, or systems that reference this schema
    breaking_change_policy:
      type: string
      enum: [strict, additive-only, versioned]
      description: How breaking changes to this schema are handled
  required: [schema_id, title, description, json_schema_version, schema, example_valid, example_invalid]
validation_rules:
  - schema must contain a type or $ref at the top level
  - schema.$schema should match json_schema_version dialect URI
  - example_valid must conform to the schema field (agent should verify with a JSON Schema validator)
  - example_invalid must each fail validation against the schema field
  - schema_id must be unique within the artifact registry
  - schema must not contain circular $ref chains
  - if breaking_change_policy is strict, any modification to required fields or removal of properties is prohibited without a new schema_id
related_artifacts: [api-response, form-schema, openapi-spec]
---

```json
{
  "schema_id": "mentiko/agent-config/v1",
  "title": "Agent Configuration",
  "description": "Validates an agent definition object as stored in {orgRoot}/agents/{id}/agent.json. Used by the chain runner and web UI on load.",
  "json_schema_version": "draft-2020-12",
  "used_by": ["lib/chain-runner.sh", "web/lib/agent-loader.ts", "web/app/api/agents/route.ts"],
  "breaking_change_policy": "versioned",
  "schema": {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "$id": "mentiko/agent-config/v1",
    "title": "Agent Configuration",
    "type": "object",
    "properties": {
      "id": {
        "type": "string",
        "pattern": "^[a-z0-9][a-z0-9-]{0,62}[a-z0-9]$",
        "description": "Kebab-case agent identifier"
      },
      "name": {
        "type": "string",
        "minLength": 1,
        "maxLength": 120
      },
      "description": {
        "type": ["string", "null"],
        "maxLength": 500
      },
      "version": {
        "type": "string",
        "pattern": "^\\d+\\.\\d+(\\.\\d+)?$"
      },
      "role": {
        "type": "string",
        "minLength": 1
      },
      "prompt": {
        "type": "string",
        "minLength": 10
      },
      "model": {
        "type": ["string", "null"],
        "examples": ["claude-opus-4-5", "claude-sonnet-4-5", "o4-mini"]
      },
      "triggers": {
        "type": "array",
        "items": { "type": "string", "minLength": 1 },
        "minItems": 1
      },
      "emits": {
        "type": "array",
        "items": { "type": "string", "minLength": 1 }
      },
      "timeout": {
        "type": ["integer", "null"],
        "minimum": 30,
        "maximum": 86400,
        "description": "Execution timeout in seconds"
      },
      "retry": {
        "type": "object",
        "properties": {
          "max_attempts": { "type": "integer", "minimum": 1, "maximum": 10 },
          "backoff_seconds": { "type": "integer", "minimum": 1 }
        },
        "required": ["max_attempts"]
      },
      "artifacts": {
        "type": "object",
        "properties": {
          "produces": {
            "type": "array",
            "items": { "type": "string" }
          },
          "consumes": {
            "type": "array",
            "items": { "type": "string" }
          }
        }
      },
      "marketplace": {
        "type": "object",
        "properties": {
          "tags": { "type": "array", "items": { "type": "string" } },
          "category": { "type": "string" },
          "author": { "type": "string" }
        }
      }
    },
    "required": ["id", "name", "version", "role", "prompt", "triggers"],
    "additionalProperties": false
  },
  "example_valid": {
    "id": "web-researcher",
    "name": "Web Researcher",
    "description": "Searches the web and summarizes findings into a structured research report.",
    "version": "1.2",
    "role": "You are a precise research assistant. Search, read, and synthesize information into clear structured reports.",
    "prompt": "Research the following topic thoroughly: {TASK}. Produce a research-summary artifact when complete.",
    "model": "claude-sonnet-4-5",
    "triggers": ["research.requested"],
    "emits": ["research.complete"],
    "timeout": 900,
    "retry": { "max_attempts": 2, "backoff_seconds": 30 },
    "artifacts": {
      "produces": ["research-summary"],
      "consumes": []
    },
    "marketplace": {
      "tags": ["research", "web", "summarization"],
      "category": "analysis",
      "author": "mentiko"
    }
  },
  "example_invalid": [
    {
      "data": {
        "id": "Web Researcher",
        "name": "Web Researcher",
        "version": "1.0",
        "role": "researcher",
        "prompt": "Do research on {TASK}",
        "triggers": ["research.requested"]
      },
      "reason": "id 'Web Researcher' contains uppercase letters and spaces; pattern requires lowercase kebab-case"
    },
    {
      "data": {
        "id": "web-researcher",
        "name": "Web Researcher",
        "version": "1.0",
        "role": "researcher",
        "prompt": "Do research on {TASK}",
        "triggers": []
      },
      "reason": "triggers array is empty; minItems: 1 requires at least one trigger event"
    },
    {
      "data": {
        "id": "web-researcher",
        "name": "Web Researcher",
        "version": "1",
        "role": "researcher",
        "prompt": "Do research on {TASK}",
        "triggers": ["research.requested"],
        "unknown_field": true
      },
      "reason": "version '1' does not match semantic version pattern; also 'unknown_field' violates additionalProperties: false"
    }
  ]
}
```
