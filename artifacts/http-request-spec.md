---
id: http-request-spec
name: HTTP Request Specification
format: json
category: api
tags: [http, request, rest, api, spec]
description: Complete specification for an HTTP request to be executed by an agent or tool. Includes auth strategy, retry policy, and expected response shape for downstream validation.
author: mentiko
version: 1.0
schema:
  type: object
  properties:
    method:
      type: string
      enum: [GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS]
      description: HTTP method
    url:
      type: string
      format: uri
      description: Full URL including query string if applicable
    headers:
      type: object
      description: Request headers as key-value pairs
      additionalProperties:
        type: string
    body:
      description: Request body (object for JSON, string for raw, null for no body)
    body_encoding:
      type: string
      enum: [json, form-urlencoded, multipart, raw, none]
      description: How to serialize the body field
    auth_type:
      type: ["string", "null"]
      enum: [bearer, basic, api-key, oauth2, digest, null]
      description: Authentication strategy (credentials resolved at runtime from secrets)
    auth_config:
      type: object
      description: Auth configuration (no raw credentials here — reference secret keys)
      properties:
        secret_key:
          type: string
          description: Name of the secret to resolve from the agent's secret store
        header_name:
          type: string
          description: Header name for api-key auth type
        token_url:
          type: string
          description: Token endpoint for oauth2 type
        scopes:
          type: array
          items:
            type: string
    timeout_ms:
      type: integer
      minimum: 1
      description: Request timeout in milliseconds
    retry_count:
      type: integer
      minimum: 0
      maximum: 10
      description: Number of retry attempts on 429 or 5xx responses
    retry_backoff_ms:
      type: integer
      minimum: 0
      description: Initial backoff delay in ms (doubles each retry)
    follow_redirects:
      type: boolean
      description: Whether to follow 3xx redirects
    expected_status:
      type: array
      items:
        type: integer
      description: HTTP status codes considered successful
    response_schema_ref:
      type: ["string", "null"]
      description: Artifact ID of the api-response or json-schema-def to validate the response against
  required: [method, url, headers, body_encoding, auth_type, timeout_ms, retry_count]
validation_rules:
  - method must be one of GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS
  - url must be an absolute URI with http or https scheme
  - body must be null when method is GET or HEAD
  - body_encoding must be none when body is null
  - auth_config must be present when auth_type is not null
  - auth_config must not contain raw credential values (passwords, tokens, keys) — only secret_key references
  - timeout_ms must be between 1 and 300000
  - retry_count must be between 0 and 10
  - expected_status codes must each be valid HTTP status codes (100-599)
related_artifacts: [api-response, openapi-spec]
---

```json
{
  "method": "POST",
  "url": "https://api.stripe.com/v1/payment_intents",
  "headers": {
    "Content-Type": "application/x-www-form-urlencoded",
    "Stripe-Version": "2024-11-20",
    "Idempotency-Key": "pi_create_order_8821"
  },
  "body": {
    "amount": 4999,
    "currency": "usd",
    "automatic_payment_methods[enabled]": "true",
    "metadata[order_id]": "ord_8821",
    "metadata[customer_tier]": "pro"
  },
  "body_encoding": "form-urlencoded",
  "auth_type": "bearer",
  "auth_config": {
    "secret_key": "STRIPE_SECRET_KEY"
  },
  "timeout_ms": 15000,
  "retry_count": 3,
  "retry_backoff_ms": 500,
  "follow_redirects": false,
  "expected_status": [200, 201],
  "response_schema_ref": "api-response"
}
```
