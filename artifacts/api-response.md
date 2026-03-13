---
id: api-response
name: HTTP API Response
format: json
category: api
tags: [http, api, response, rest, web]
description: Captured HTTP API response from an agent's web call. Includes full status, headers, parsed body, timing, and error state for downstream agent consumption.
author: mentiko
version: 1.0
schema:
  type: object
  properties:
    status:
      type: integer
      description: HTTP status code
      minimum: 100
      maximum: 599
    status_text:
      type: string
      description: HTTP status text (e.g. "OK", "Not Found")
    headers:
      type: object
      description: Response headers as key-value pairs (lowercase keys)
      additionalProperties:
        type: string
    body:
      description: Parsed response body (object if JSON, string otherwise)
    url:
      type: string
      format: uri
      description: Final URL after any redirects
    method:
      type: string
      enum: [GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS]
      description: HTTP method used
    duration_ms:
      type: number
      description: Round-trip request duration in milliseconds
    error:
      type: ["string", "null"]
      description: Network or parse error message, null on success
    redirected:
      type: boolean
      description: True if the request followed one or more redirects
    request_id:
      type: ["string", "null"]
      description: X-Request-ID or similar correlation header if present
  required: [status, status_text, headers, url, method, duration_ms, error]
validation_rules:
  - status must be a valid HTTP status code between 100 and 599
  - method must be one of GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS
  - duration_ms must be a non-negative number
  - url must be an absolute URI with http or https scheme
  - error must be null when status is 2xx
  - headers keys must be lowercase (normalized)
  - if body is present and content-type is application/json, body must be a parsed object or array, not a raw string
related_artifacts: [http-request-spec, openapi-spec, graphql-query]
---

```json
{
  "status": 200,
  "status_text": "OK",
  "headers": {
    "content-type": "application/json; charset=utf-8",
    "x-request-id": "req_a1b2c3d4e5f6",
    "x-ratelimit-limit": "1000",
    "x-ratelimit-remaining": "847",
    "x-ratelimit-reset": "1741910400",
    "cache-control": "no-cache, no-store",
    "strict-transport-security": "max-age=63072000; includeSubDomains",
    "transfer-encoding": "chunked"
  },
  "body": {
    "object": "list",
    "data": [
      {
        "id": "usr_8kQmP3xLvN2w",
        "email": "alice@acme.com",
        "name": "Alice Nguyen",
        "role": "admin",
        "created_at": "2025-11-03T14:22:10Z",
        "last_login": "2026-03-12T09:41:37Z",
        "active": true
      },
      {
        "id": "usr_2rJnF9yTkB4c",
        "email": "bob@acme.com",
        "name": "Bob Okafor",
        "role": "member",
        "created_at": "2025-12-18T08:05:44Z",
        "last_login": "2026-03-11T17:03:22Z",
        "active": true
      }
    ],
    "has_more": false,
    "total_count": 2,
    "next_cursor": null
  },
  "url": "https://api.acme.com/v2/users?limit=50&active=true",
  "method": "GET",
  "duration_ms": 143,
  "error": null,
  "redirected": false,
  "request_id": "req_a1b2c3d4e5f6"
}
```
