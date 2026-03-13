---
id: openapi-spec
name: OpenAPI Specification
format: json
category: api
tags: [openapi, swagger, api, rest, spec, documentation]
description: OpenAPI 3.1 specification for an API surface. Can be a full spec or a focused excerpt covering a single resource. Used by agents to understand available endpoints before making requests.
author: mentiko
version: 1.0
schema:
  type: object
  properties:
    openapi:
      type: string
      description: OpenAPI version string (e.g. "3.1.0")
    info:
      type: object
      properties:
        title:
          type: string
        version:
          type: string
        description:
          type: ["string", "null"]
        contact:
          type: object
          properties:
            name: { type: string }
            email: { type: string, format: email }
            url: { type: string, format: uri }
      required: [title, version]
    servers:
      type: array
      minItems: 1
      items:
        type: object
        properties:
          url: { type: string, format: uri }
          description: { type: string }
        required: [url]
    paths:
      type: object
      description: Path item objects keyed by path template (e.g. /users/{id})
      additionalProperties:
        type: object
    components:
      type: object
      description: Reusable schemas, responses, parameters, securitySchemes
      properties:
        schemas:
          type: object
        securitySchemes:
          type: object
        responses:
          type: object
    security:
      type: array
      items:
        type: object
      description: Global security requirements
    excerpt:
      type: boolean
      description: True if this is a partial spec (not all paths included)
  required: [openapi, info, servers, paths]
validation_rules:
  - openapi must be "3.0.x" or "3.1.x" format string
  - info.title must be non-empty
  - servers must contain at least one entry with a valid http/https URL
  - each path must start with a forward slash
  - each path item must contain at least one HTTP method operation (get, post, put, patch, delete)
  - operationId must be unique across all operations in the spec
  - $ref values must point to existing definitions within components or be absolute URIs
related_artifacts: [http-request-spec, api-response, graphql-query]
---

```json
{
  "openapi": "3.1.0",
  "excerpt": true,
  "info": {
    "title": "Mentiko Platform API",
    "version": "2.0.0",
    "description": "REST API for chain orchestration, agent management, and run lifecycle.",
    "contact": {
      "name": "Mentiko Support",
      "email": "support@mentiko.com",
      "url": "https://mentiko.com/docs"
    }
  },
  "servers": [
    { "url": "https://mentiko.com/api", "description": "Production" },
    { "url": "http://localhost:3000/api", "description": "Local development" }
  ],
  "security": [
    { "bearerAuth": [] }
  ],
  "paths": {
    "/chains": {
      "get": {
        "operationId": "listChains",
        "summary": "List all chains in the current org",
        "tags": ["Chains"],
        "parameters": [
          {
            "name": "limit",
            "in": "query",
            "schema": { "type": "integer", "default": 50, "maximum": 200 }
          },
          {
            "name": "cursor",
            "in": "query",
            "schema": { "type": "string" }
          }
        ],
        "responses": {
          "200": {
            "description": "Paginated chain list",
            "content": {
              "application/json": {
                "schema": { "$ref": "#/components/schemas/ChainList" }
              }
            }
          },
          "401": { "$ref": "#/components/responses/Unauthorized" }
        }
      },
      "post": {
        "operationId": "createChain",
        "summary": "Create a new chain definition",
        "tags": ["Chains"],
        "requestBody": {
          "required": true,
          "content": {
            "application/json": {
              "schema": { "$ref": "#/components/schemas/ChainInput" }
            }
          }
        },
        "responses": {
          "201": {
            "description": "Created chain",
            "content": {
              "application/json": {
                "schema": { "$ref": "#/components/schemas/Chain" }
              }
            }
          },
          "400": { "$ref": "#/components/responses/ValidationError" },
          "401": { "$ref": "#/components/responses/Unauthorized" }
        }
      }
    },
    "/chains/{chainId}/run": {
      "post": {
        "operationId": "runChain",
        "summary": "Trigger a chain execution",
        "tags": ["Runs"],
        "parameters": [
          {
            "name": "chainId",
            "in": "path",
            "required": true,
            "schema": { "type": "string" }
          }
        ],
        "requestBody": {
          "content": {
            "application/json": {
              "schema": {
                "type": "object",
                "properties": {
                  "task": { "type": "string" },
                  "workspace_id": { "type": "string" },
                  "dry_run": { "type": "boolean", "default": false }
                }
              }
            }
          }
        },
        "responses": {
          "202": {
            "description": "Run accepted",
            "content": {
              "application/json": {
                "schema": { "$ref": "#/components/schemas/RunRef" }
              }
            }
          }
        }
      }
    }
  },
  "components": {
    "schemas": {
      "Chain": {
        "type": "object",
        "properties": {
          "id": { "type": "string" },
          "name": { "type": "string" },
          "description": { "type": ["string", "null"] },
          "version": { "type": "string" },
          "created_at": { "type": "string", "format": "date-time" },
          "updated_at": { "type": "string", "format": "date-time" }
        },
        "required": ["id", "name", "version"]
      },
      "ChainList": {
        "type": "object",
        "properties": {
          "data": { "type": "array", "items": { "$ref": "#/components/schemas/Chain" } },
          "has_more": { "type": "boolean" },
          "next_cursor": { "type": ["string", "null"] }
        }
      },
      "ChainInput": {
        "type": "object",
        "properties": {
          "name": { "type": "string", "minLength": 1, "maxLength": 120 },
          "description": { "type": "string" },
          "agents": { "type": "array", "minItems": 1 }
        },
        "required": ["name", "agents"]
      },
      "RunRef": {
        "type": "object",
        "properties": {
          "run_id": { "type": "string" },
          "status": { "type": "string", "enum": ["queued", "running"] },
          "status_url": { "type": "string", "format": "uri" }
        }
      }
    },
    "responses": {
      "Unauthorized": {
        "description": "Missing or invalid authentication",
        "content": {
          "application/json": {
            "schema": {
              "type": "object",
              "properties": {
                "error": { "type": "string" },
                "code": { "type": "string" }
              }
            }
          }
        }
      },
      "ValidationError": {
        "description": "Request body failed validation",
        "content": {
          "application/json": {
            "schema": {
              "type": "object",
              "properties": {
                "error": { "type": "string" },
                "fields": { "type": "object" }
              }
            }
          }
        }
      }
    },
    "securitySchemes": {
      "bearerAuth": {
        "type": "http",
        "scheme": "bearer",
        "bearerFormat": "JWT"
      }
    }
  }
}
```
