---
id: data-schema
name: Data Schema Definition
format: json
category: data
tags: [schema, json, validation, data]
description: >
  JSON Schema specification for structured data validation. Includes field definitions,
  types, constraints, valid and invalid examples. Produced by a schema-design agent
  when defining or documenting a data contract.
author: mentiko
version: 1.0
schema:
  type: object
  properties:
    schema_id:
      type: string
      description: Kebab-case identifier for this schema definition
    title:
      type: string
      description: Human-readable schema name
    version:
      type: string
      description: Semantic version of the schema
      pattern: "^\\d+\\.\\d+\\.\\d+$"
    schema:
      type: object
      description: The JSON Schema definition itself (draft-07 or later)
    examples:
      type: array
      items:
        type: object
        properties:
          valid:
            type: boolean
            description: Whether this example passes schema validation
          data:
            type: object
            description: The example data payload
          description:
            type: string
            description: Why this example is valid or invalid
  required: [schema_id, title, schema]
validation_rules:
  - schema must be valid JSON Schema (draft-07 or later)
  - at least one example must have valid set to true
  - at least one example must have valid set to false
  - schema_id must be kebab-case (lowercase letters, numbers, hyphens only)
related_artifacts:
  - json-schema-def
  - api-response
---

```json
{
  "schema_id": "agent-config",
  "title": "Agent Configuration",
  "version": "2.1.0",
  "description": "Defines the configuration object for a Mentiko agent. Validated before agent launch.",
  "schema": {
    "$schema": "http://json-schema.org/draft-07/schema#",
    "$id": "https://mentiko.com/schemas/agent-config",
    "title": "Agent Configuration",
    "type": "object",
    "properties": {
      "id": {
        "type": "string",
        "description": "Unique agent identifier (kebab-case)",
        "pattern": "^[a-z0-9-]+$",
        "minLength": 2,
        "maxLength": 64
      },
      "name": {
        "type": "string",
        "description": "Human-readable agent name",
        "minLength": 1,
        "maxLength": 100
      },
      "model": {
        "type": "string",
        "description": "AI model to use for this agent",
        "enum": ["claude-opus-4-5", "claude-sonnet-4-5", "claude-haiku-3-5", "gpt-4o", "gpt-4-turbo"]
      },
      "authorities": {
        "type": "array",
        "description": "Capabilities granted to this agent",
        "items": {
          "type": "string",
          "enum": ["read_files", "write_files", "execute_commands", "network_access", "spawn_agents"]
        }
      },
      "timeout": {
        "type": "integer",
        "description": "Maximum execution time in seconds",
        "minimum": 30,
        "maximum": 3600
      },
      "retry": {
        "type": "object",
        "description": "Retry configuration on failure",
        "properties": {
          "max_attempts": {
            "type": "integer",
            "minimum": 1,
            "maximum": 10
          },
          "backoff_seconds": {
            "type": "integer",
            "minimum": 1,
            "maximum": 300
          }
        },
        "required": ["max_attempts"]
      },
      "triggers": {
        "type": "array",
        "description": "Events that start this agent",
        "items": {
          "type": "string"
        },
        "minItems": 1
      },
      "emits": {
        "type": "array",
        "description": "Events this agent produces on completion",
        "items": {
          "type": "string"
        }
      }
    },
    "required": ["id", "name", "model", "triggers"],
    "additionalProperties": false
  },
  "examples": [
    {
      "valid": true,
      "description": "Minimal valid agent config with required fields only",
      "data": {
        "id": "code-reviewer",
        "name": "Code Reviewer",
        "model": "claude-sonnet-4-5",
        "triggers": ["pr-opened"]
      }
    },
    {
      "valid": true,
      "description": "Full agent config with retry, authorities, and emits",
      "data": {
        "id": "security-scanner",
        "name": "Security Scanner",
        "model": "claude-opus-4-5",
        "authorities": ["read_files", "execute_commands"],
        "timeout": 600,
        "retry": {
          "max_attempts": 3,
          "backoff_seconds": 30
        },
        "triggers": ["deploy-requested"],
        "emits": ["security-scan-complete", "security-scan-failed"]
      }
    },
    {
      "valid": false,
      "description": "Invalid: model not in allowed enum, timeout below minimum",
      "data": {
        "id": "bad-agent",
        "name": "Bad Agent",
        "model": "gpt-3.5-turbo",
        "timeout": 5,
        "triggers": ["start"]
      }
    },
    {
      "valid": false,
      "description": "Invalid: id contains uppercase and spaces, triggers is empty array",
      "data": {
        "id": "My Agent",
        "name": "My Agent",
        "model": "claude-sonnet-4-5",
        "triggers": []
      }
    }
  ]
}
```
