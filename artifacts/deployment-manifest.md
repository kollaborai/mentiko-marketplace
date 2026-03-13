---
id: deployment-manifest
name: Deployment Manifest
format: text
category: devops
tags: [docker, compose, kubernetes, deployment, infra, containers]
description: >
  Deployment configuration for one or more services. Covers Docker Compose,
  Kubernetes manifests, and similar orchestration formats. Produced by agents
  that scaffold or update deployment infrastructure.
author: mentiko
version: 1.0
schema:
  type: object
  properties:
    platform:
      type: string
      enum: [docker-compose, kubernetes, nomad, fly, railway, render]
      description: target deployment platform
    format:
      type: string
      enum: [yaml, json, hcl, toml]
      description: file format of the manifest content
    path:
      type: string
      description: intended file path relative to repo root
    services:
      type: array
      description: logical services defined in this manifest
      items:
        type: object
        properties:
          name:
            type: string
            description: service name
          image:
            type: string
            description: container image (name:tag)
          ports:
            type: array
            items:
              type: string
            description: port mappings in HOST:CONTAINER format
          env_vars:
            type: array
            items:
              type: string
            description: environment variable names configured for this service
          volumes:
            type: array
            items:
              type: string
            description: volume mounts in HOST:CONTAINER format
          replicas:
            type: integer
            minimum: 1
            description: number of replicas for this service
        required: [name, image]
    secrets:
      type: array
      description: names of secrets that must be provisioned before deployment
      items:
        type: string
    content:
      type: string
      description: full manifest file content as a string
  required: [platform, format, path, services, secrets, content]
validation_rules:
  - platform must be one of docker-compose, kubernetes, nomad, fly, railway, render
  - services array must have at least one entry
  - content must be non-empty
  - path must be relative (no leading slash)
  - ports entries must match HOST:CONTAINER format (e.g. "3000:3000")
  - secrets must be referenced in at least one service's env_vars
related_artifacts:
  - config-file
  - shell-script
  - command-output
---

## docker compose example

```json
{
  "platform": "docker-compose",
  "format": "yaml",
  "path": "docker-compose.production.yml",
  "secrets": [
    "POSTGRES_PASSWORD",
    "BETTER_AUTH_SECRET",
    "STRIPE_SECRET_KEY",
    "STRIPE_WEBHOOK_SECRET"
  ],
  "services": [
    {
      "name": "app",
      "image": "ghcr.io/kollaborai/mentiko-platform:latest",
      "ports": ["3000:3000"],
      "env_vars": [
        "NODE_ENV",
        "DATABASE_URL",
        "BETTER_AUTH_SECRET",
        "BETTER_AUTH_URL",
        "STRIPE_SECRET_KEY",
        "STRIPE_WEBHOOK_SECRET"
      ],
      "volumes": [
        "/opt/mentiko/platform-build:/app",
        "/opt/mentiko/data:/data"
      ],
      "replicas": 1
    },
    {
      "name": "postgres",
      "image": "postgres:16-alpine",
      "ports": [],
      "env_vars": ["POSTGRES_PASSWORD", "POSTGRES_DB", "POSTGRES_USER"],
      "volumes": ["postgres_data:/var/lib/postgresql/data"],
      "replicas": 1
    },
    {
      "name": "caddy",
      "image": "caddy:2.8-alpine",
      "ports": ["80:80", "443:443"],
      "env_vars": ["CLOUDFLARE_API_TOKEN"],
      "volumes": [
        "./Caddyfile:/etc/caddy/Caddyfile",
        "caddy_data:/data",
        "caddy_config:/config"
      ],
      "replicas": 1
    }
  ],
  "content": "version: '3.9'\n\nservices:\n  app:\n    image: ghcr.io/kollaborai/mentiko-platform:latest\n    restart: unless-stopped\n    ports:\n      - '3000:3000'\n    environment:\n      NODE_ENV: production\n      DATABASE_URL: ${DATABASE_URL}\n      BETTER_AUTH_SECRET: ${BETTER_AUTH_SECRET}\n      BETTER_AUTH_URL: ${BETTER_AUTH_URL}\n      STRIPE_SECRET_KEY: ${STRIPE_SECRET_KEY}\n      STRIPE_WEBHOOK_SECRET: ${STRIPE_WEBHOOK_SECRET}\n    volumes:\n      - /opt/mentiko/platform-build:/app\n      - /opt/mentiko/data:/data\n    depends_on:\n      postgres:\n        condition: service_healthy\n\n  postgres:\n    image: postgres:16-alpine\n    restart: unless-stopped\n    environment:\n      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}\n      POSTGRES_DB: mentiko\n      POSTGRES_USER: mentiko\n    volumes:\n      - postgres_data:/var/lib/postgresql/data\n    healthcheck:\n      test: [\"CMD-SHELL\", \"pg_isready -U mentiko\"]\n      interval: 10s\n      timeout: 5s\n      retries: 5\n\n  caddy:\n    image: caddy:2.8-alpine\n    restart: unless-stopped\n    ports:\n      - '80:80'\n      - '443:443'\n    environment:\n      CLOUDFLARE_API_TOKEN: ${CLOUDFLARE_API_TOKEN}\n    volumes:\n      - ./Caddyfile:/etc/caddy/Caddyfile\n      - caddy_data:/data\n      - caddy_config:/config\n\nvolumes:\n  postgres_data:\n  caddy_data:\n  caddy_config:\n"
}
```
