---
id: form-schema
name: Dynamic Form Schema
format: json
category: web
tags: [form, validation, ui, schema, dynamic]
description: Field definitions for dynamic form generation. Drives client-side rendering and validation without hardcoded components. Supports text, select, checkbox, file, and custom field types.
author: mentiko
version: 1.0
schema:
  type: object
  properties:
    id:
      type: string
      description: Unique form identifier (kebab-case)
    title:
      type: string
      description: Human-readable form heading
    description:
      type: ["string", "null"]
      description: Optional sub-heading or instructions shown above the form
    fields:
      type: array
      minItems: 1
      description: Ordered list of form field definitions
      items:
        type: object
        properties:
          id:
            type: string
            description: Field identifier (camelCase), used as form data key
          label:
            type: string
            description: Visible label text
          type:
            type: string
            enum: [text, email, password, number, tel, url, textarea, select, multiselect, checkbox, radio, file, date, datetime-local, hidden]
          required:
            type: boolean
          placeholder:
            type: ["string", "null"]
          default_value:
            description: Pre-filled value
          validation:
            type: object
            description: Validation constraints
            properties:
              min_length: { type: integer }
              max_length: { type: integer }
              min: { type: number }
              max: { type: number }
              pattern: { type: string, description: "Regex pattern string" }
              pattern_message: { type: string }
              custom_rule: { type: string, description: "Human-readable description of a custom validation rule" }
          options:
            type: array
            description: Required for select, multiselect, radio types
            items:
              type: object
              properties:
                value: { type: string }
                label: { type: string }
                disabled: { type: boolean }
              required: [value, label]
          help_text:
            type: ["string", "null"]
            description: Helper text shown below the field
          depends_on:
            type: object
            description: Conditionally show this field based on another field's value
            properties:
              field: { type: string }
              value: {}
        required: [id, label, type, required]
    submit_action:
      type: string
      description: Absolute or relative URL the form POSTs to, or a named action identifier
    submit_label:
      type: string
      description: Text on the submit button
    success_message:
      type: string
      description: Message displayed after successful submission
    cancel_action:
      type: ["string", "null"]
      description: URL or action identifier for cancel button (null if no cancel)
    layout:
      type: string
      enum: [single-column, two-column, wizard]
      description: Suggested rendering layout
  required: [id, title, fields, submit_action, submit_label, success_message]
validation_rules:
  - all field ids must be unique within the form
  - options array is required when field type is select, multiselect, or radio
  - depends_on.field must reference an existing field id in the same form
  - submit_action must be a valid URL path or named action identifier (non-empty string)
  - password type fields must not set default_value
  - validation.pattern must be a valid JavaScript regex string
  - hidden type fields must have a default_value
related_artifacts: [ui-component, http-request-spec, api-response]
---

```json
{
  "id": "workspace-invite",
  "title": "Invite Team Member",
  "description": "Send an invitation to collaborate on this workspace. They'll receive an email with a sign-up link.",
  "layout": "single-column",
  "fields": [
    {
      "id": "email",
      "label": "Email address",
      "type": "email",
      "required": true,
      "placeholder": "colleague@company.com",
      "validation": {
        "max_length": 254,
        "pattern": "^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$",
        "pattern_message": "Enter a valid email address"
      },
      "help_text": null
    },
    {
      "id": "role",
      "label": "Role",
      "type": "select",
      "required": true,
      "placeholder": null,
      "default_value": "member",
      "options": [
        { "value": "admin", "label": "Admin — full access", "disabled": false },
        { "value": "member", "label": "Member — can view and run chains", "disabled": false },
        { "value": "guest", "label": "Guest — read-only", "disabled": false }
      ],
      "help_text": "Admins can manage members and billing."
    },
    {
      "id": "sendWelcome",
      "label": "Send welcome email",
      "type": "checkbox",
      "required": false,
      "default_value": true,
      "help_text": "Sends a personalised onboarding email after the invite is accepted."
    },
    {
      "id": "personalNote",
      "label": "Personal note",
      "type": "textarea",
      "required": false,
      "placeholder": "Add a message to include in the invite email…",
      "validation": { "max_length": 500 },
      "help_text": null,
      "depends_on": { "field": "sendWelcome", "value": true }
    },
    {
      "id": "workspaceId",
      "label": "Workspace ID",
      "type": "hidden",
      "required": true,
      "default_value": "ws_prod_main"
    }
  ],
  "submit_action": "/api/orgs/invites",
  "submit_label": "Send invite",
  "success_message": "Invite sent! They'll receive an email within a few minutes.",
  "cancel_action": "/settings/members"
}
```
