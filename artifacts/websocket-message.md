---
id: websocket-message
name: WebSocket Message Payload
format: json
category: api
tags: [websocket, realtime, event, message, pubsub]
description: Structured WebSocket message envelope for real-time agent communication. Covers both inbound commands and outbound events with correlation tracking and session binding.
author: mentiko
version: 1.0
schema:
  type: object
  properties:
    event_type:
      type: string
      description: Dot-separated event identifier (e.g. "run.agent.output", "chain.complete")
    direction:
      type: string
      enum: [inbound, outbound]
      description: From the server's perspective — inbound = client sent, outbound = server sent
    payload:
      type: object
      description: Event-specific data (structure varies by event_type)
    timestamp:
      type: string
      format: date-time
      description: ISO 8601 timestamp when the message was emitted
    correlation_id:
      type: string
      description: UUID linking request/response pairs or event chains
    session_id:
      type: string
      description: WebSocket session identifier for the originating connection
    run_id:
      type: ["string", "null"]
      description: Associated chain run ID if this message belongs to a run
    agent_id:
      type: ["string", "null"]
      description: Agent session name if the message is scoped to a specific agent
    sequence:
      type: integer
      minimum: 0
      description: Monotonically increasing per-session message counter for ordering
    version:
      type: integer
      description: Message format version (increment when payload schema changes)
    ack_required:
      type: boolean
      description: True if the sender expects an acknowledgement message with the same correlation_id
  required: [event_type, direction, payload, timestamp, correlation_id, session_id, sequence, version]
validation_rules:
  - event_type must use dot notation with at least two segments (e.g. "run.started" not "started")
  - timestamp must be a valid ISO 8601 date-time with timezone offset or Z suffix
  - correlation_id must be a non-empty string (UUID v4 recommended)
  - session_id must be a non-empty string
  - sequence must be a non-negative integer
  - version must be a positive integer
  - payload must not be null or an empty object when event_type is not "ping" or "pong"
  - if ack_required is true, no response should include ack_required: true (prevents ack loops)
related_artifacts: [api-response, http-request-spec]
---

```json
{
  "event_type": "run.agent.output",
  "direction": "outbound",
  "version": 1,
  "sequence": 47,
  "timestamp": "2026-03-13T11:22:04.831Z",
  "correlation_id": "550e8400-e29b-41d4-a716-446655440000",
  "session_id": "ws_7xKpQ2mRnL9v",
  "run_id": "run_c3f8a1b9d2e4",
  "agent_id": "researcher-1",
  "ack_required": false,
  "payload": {
    "chunk": "Searching for recent papers on retrieval-augmented generation with sparse attention...\n\nFound 14 results. Filtering by citation count ≥ 50 and published after 2024-01-01.\n\nTop candidates:\n1. \"RagSparse: Efficient RAG with Block-Sparse Transformers\" (2024) — 312 citations\n2. \"Context Window Compression for Long-Document RAG\" (2025) — 89 citations\n",
    "type": "text",
    "is_final": false,
    "token_count": 82,
    "tool_call": null
  }
}
```

---

outbound ping keepalive:

```json
{
  "event_type": "connection.ping",
  "direction": "outbound",
  "version": 1,
  "sequence": 120,
  "timestamp": "2026-03-13T11:22:30.000Z",
  "correlation_id": "ping-120",
  "session_id": "ws_7xKpQ2mRnL9v",
  "run_id": null,
  "agent_id": null,
  "ack_required": true,
  "payload": {
    "server_time": "2026-03-13T11:22:30.000Z"
  }
}
```

inbound pong (client response):

```json
{
  "event_type": "connection.pong",
  "direction": "inbound",
  "version": 1,
  "sequence": 121,
  "timestamp": "2026-03-13T11:22:30.041Z",
  "correlation_id": "ping-120",
  "session_id": "ws_7xKpQ2mRnL9v",
  "run_id": null,
  "agent_id": null,
  "ack_required": false,
  "payload": {
    "client_time": "2026-03-13T11:22:30.038Z",
    "latency_ms": 38
  }
}
```
