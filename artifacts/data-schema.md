---
id: data-schema
name: Data Schema Definition
format: json
category: technical
tags: [schema, json, validation, data]
description: JSON Schema specification for structured data validation. Includes field definitions, types, constraints, and examples.
author: mentiko
version: 1.0
---

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://mentiko.com/schemas/{SCHEMA_ID}",
  "title": "{SCHEMA_TITLE}",
  "description": "{SCHEMA_DESCRIPTION}",
  "type": "object",
  "properties": {
    "id": {
      "type": "string",
      "description": "Unique identifier",
      "format": "uuid"
    },
    "name": {
      "type": "string",
      "description": "Human-readable name",
      "minLength": 1,
      "maxLength": 100
    },
    "createdAt": {
      "type": "string",
      "format": "date-time",
      "description": "ISO 8601 timestamp"
    },
    "updatedAt": {
      "type": "string",
      "format": "date-time",
      "description": "ISO 8601 timestamp"
    },
    "status": {
      "type": "string",
      "enum": ["active", "inactive", "pending", "archived"],
      "default": "pending"
    },
    "metadata": {
      "type": "object",
      "description": "Additional key-value pairs",
      "additionalProperties": true
    }
  },
  "required": ["id", "name", "createdAt"],
  "additionalProperties": false
}
```

## Example
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Example Resource",
  "createdAt": "2025-01-15T10:30:00Z",
  "updatedAt": "2025-01-15T14:22:00Z",
  "status": "active",
  "metadata": {
    "source": "api",
    "version": "1.0"
  }
}
```
