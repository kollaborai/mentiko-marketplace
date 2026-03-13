---
id: config-file
name: Config File
format: text
category: cli
tags: [config, json, yaml, toml, env, dotenv, settings]
description: >
  A generated configuration file in any format (JSON, YAML, TOML, .env).
  Includes the file path, format name, content, and which variables must
  be set before use. Produced by agents that scaffold or configure projects.
author: mentiko
version: 1.0
schema:
  type: object
  properties:
    format:
      type: string
      enum: [json, yaml, toml, env, ini, xml, hcl]
      description: file format
    path:
      type: string
      description: intended file path relative to project root
    content:
      type: string
      description: full file content as a string
    schema_version:
      type: [string, "null"]
      description: schema or spec version this config targets (null if not applicable)
    required_vars:
      type: array
      description: environment variable names that must be set before this config is valid
      items:
        type: string
    description:
      type: string
      description: what this config file controls
    overrides:
      type: object
      description: key-value map of fields that should be changed per-environment
      additionalProperties:
        type: string
  required: [format, path, content, required_vars, description]
validation_rules:
  - format must be one of json, yaml, toml, env, ini, xml, hcl
  - path must be relative (no leading slash)
  - content must be non-empty
  - required_vars items must be UPPER_SNAKE_CASE
  - if format is env, content must have lines in KEY=VALUE or # comment format
  - if format is json, content must be valid JSON
related_artifacts:
  - shell-script
  - deployment-manifest
  - command-output
---

## .env example

```json
{
  "format": "env",
  "path": "web/.env.local",
  "schema_version": null,
  "description": "Local development environment variables for the mentiko web app. Copy to web/.env.local and fill in required values.",
  "required_vars": [
    "BETTER_AUTH_SECRET",
    "BETTER_AUTH_URL",
    "DATABASE_URL"
  ],
  "overrides": {
    "BETTER_AUTH_URL": "https://mentiko.com (production)",
    "DATABASE_URL": "postgresql://... (production postgres)"
  },
  "content": "# mentiko web — local development\n# Copy this file to web/.env.local\n# Lines marked REQUIRED must be set before the app will start.\n\n# Auth\nBETTER_AUTH_SECRET=change-me-use-openssl-rand-base64-32\nBETTER_AUTH_URL=http://localhost:3000\n\n# Database (sqlite for local, postgres for production)\nDATABASE_URL=file:web/data/auth.db\n\n# Namespace\nNAMESPACE_ID=default\nORG_ID=default\n\n# Marketplace\nMARKETPLACE_URL=https://raw.githubusercontent.com/kollaborai/mentiko-marketplace/main\n\n# OAuth (optional for local dev)\n# GITHUB_CLIENT_ID=\n# GITHUB_CLIENT_SECRET=\n# GOOGLE_CLIENT_ID=\n# GOOGLE_CLIENT_SECRET=\n\n# Stripe (optional — uses mock server locally)\n# STRIPE_SECRET_KEY=sk_test_...\n# STRIPE_WEBHOOK_SECRET=whsec_...\n"
}
```

## next.js config example

```json
{
  "format": "json",
  "path": "web/next.config.json",
  "schema_version": "15.2.0",
  "description": "Next.js configuration with standalone output, image domains, and webpack alias for path resolution.",
  "required_vars": [],
  "overrides": {},
  "content": "{\n  \"output\": \"standalone\",\n  \"images\": {\n    \"remotePatterns\": [\n      { \"protocol\": \"https\", \"hostname\": \"avatars.githubusercontent.com\" },\n      { \"protocol\": \"https\", \"hostname\": \"lh3.googleusercontent.com\" }\n    ]\n  },\n  \"webpack\": \"// see next.config.ts for webpack customization\",\n  \"experimental\": {\n    \"serverActions\": { \"bodySizeLimit\": \"2mb\" }\n  }\n}"
}
```
