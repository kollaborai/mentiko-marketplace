---
id: html-template
name: Generated HTML Template
format: code
category: web
tags: [html, template, markup, email, jinja, handlebars, ui]
description: Agent-generated HTML markup, optionally with template engine syntax. Covers static pages, email templates, and server-rendered partials with variable bindings declared explicitly.
author: mentiko
version: 1.0
schema:
  type: object
  properties:
    template_engine:
      type: ["string", "null"]
      enum: [handlebars, jinja2, liquid, mustache, nunjucks, mjml, null]
      description: Template engine syntax used, or null for plain static HTML
    purpose:
      type: string
      enum: [page, partial, email, component, email-plain-text]
      description: Intended rendering context
    markup:
      type: string
      description: Full HTML string (or MJML if template_engine is mjml)
    variables:
      type: array
      description: Template variables referenced in markup
      items:
        type: object
        properties:
          name:
            type: string
            description: Variable name as used in template (without engine delimiters)
          type:
            type: string
            description: JavaScript/Python type (string, number, boolean, object, array)
          required:
            type: boolean
          description:
            type: string
          example:
            description: Example value for this variable
        required: [name, type, required, description]
    requires_js:
      type: boolean
      description: True if the markup includes inline scripts or relies on client-side JS to function
    inline_styles:
      type: boolean
      description: True if CSS is inlined (typical for email templates)
    doctype:
      type: boolean
      description: True if the markup includes a DOCTYPE declaration
    encoding:
      type: string
      enum: [utf-8, utf-16, iso-8859-1]
      description: Character encoding declared in meta tag
    accessibility_notes:
      type: ["string", "null"]
      description: Brief description of accessibility features or known gaps
  required: [template_engine, purpose, markup, variables, requires_js]
validation_rules:
  - markup must be a non-empty string containing at least one HTML tag
  - all variable names listed in variables must appear in the markup string
  - if purpose is email, inline_styles must be true and requires_js must be false
  - if template_engine is null, markup must not contain {{ }}, {% %}, or {{{ }}} syntax
  - if template_engine is handlebars, variables should use {{variableName}} syntax in markup
  - if template_engine is jinja2, variables should use {{ variable_name }} syntax in markup
  - doctype must be true when purpose is page
related_artifacts: [ui-component, css-stylesheet, form-schema]
---

```json
{
  "template_engine": "handlebars",
  "purpose": "email",
  "inline_styles": true,
  "requires_js": false,
  "doctype": false,
  "encoding": "utf-8",
  "accessibility_notes": "Plain-text fallback should be provided alongside this HTML version. Alt text on all images.",
  "variables": [
    { "name": "recipientName", "type": "string", "required": true, "description": "Recipient's display name", "example": "Alice Nguyen" },
    { "name": "inviterName", "type": "string", "required": true, "description": "Name of the person who sent the invite", "example": "Marco Almazan" },
    { "name": "orgName", "type": "string", "required": true, "description": "Organisation name", "example": "Acme Engineering" },
    { "name": "acceptUrl", "type": "string", "required": true, "description": "One-time invite acceptance URL", "example": "https://mentiko.com/invite?token=abc123" },
    { "name": "expiresIn", "type": "string", "required": true, "description": "Human-readable expiry (e.g. '7 days')", "example": "7 days" },
    { "name": "personalNote", "type": "string", "required": false, "description": "Optional personal message from inviter", "example": "Looking forward to having you on the team!" }
  ],
  "markup": "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n<html xmlns=\"http://www.w3.org/1999/xhtml\" lang=\"en\">\n<head>\n  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />\n  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\" />\n  <title>You're invited to {{orgName}}</title>\n</head>\n<body style=\"margin:0;padding:0;background-color:#0a0a0a;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;\">\n  <table width=\"100%\" cellpadding=\"0\" cellspacing=\"0\" style=\"background-color:#0a0a0a;\">\n    <tr>\n      <td align=\"center\" style=\"padding:40px 16px;\">\n        <table width=\"560\" cellpadding=\"0\" cellspacing=\"0\" style=\"background-color:#111111;border-radius:8px;overflow:hidden;max-width:560px;width:100%;\">\n          <!-- Header -->\n          <tr>\n            <td style=\"padding:32px 40px 24px;\">\n              <img src=\"https://mentiko.com/email-logo.png\" alt=\"Mentiko\" width=\"120\" height=\"28\" style=\"display:block;\" />\n            </td>\n          </tr>\n          <!-- Body -->\n          <tr>\n            <td style=\"padding:0 40px 32px;\">\n              <p style=\"margin:0 0 16px;font-size:24px;font-weight:600;color:#f5f5f5;line-height:1.3;\">Hi {{recipientName}},</p>\n              <p style=\"margin:0 0 16px;font-size:15px;color:#a3a3a3;line-height:1.6;\">{{inviterName}} has invited you to join <strong style=\"color:#f5f5f5;\">{{orgName}}</strong> on Mentiko.</p>\n              {{#if personalNote}}\n              <blockquote style=\"margin:0 0 24px;padding:16px;background:#1a1a1a;border-left:3px solid #3b82f6;border-radius:4px;\">\n                <p style=\"margin:0;font-size:14px;color:#d4d4d4;font-style:italic;line-height:1.6;\">&#8220;{{personalNote}}&#8221;</p>\n              </blockquote>\n              {{/if}}\n              <a href=\"{{acceptUrl}}\" style=\"display:inline-block;padding:12px 24px;background-color:#3b82f6;color:#ffffff;text-decoration:none;font-size:14px;font-weight:600;border-radius:6px;margin-bottom:24px;\">Accept invitation</a>\n              <p style=\"margin:0;font-size:13px;color:#525252;\">This invite expires in {{expiresIn}}. If you weren't expecting this, you can safely ignore it.</p>\n            </td>\n          </tr>\n          <!-- Footer -->\n          <tr>\n            <td style=\"padding:24px 40px;border-top:1px solid #1f1f1f;\">\n              <p style=\"margin:0;font-size:12px;color:#404040;\">Mentiko &mdash; AI agent orchestration &bull; <a href=\"https://mentiko.com/unsubscribe\" style=\"color:#525252;\">Unsubscribe</a></p>\n            </td>\n          </tr>\n        </table>\n      </td>\n    </tr>\n  </table>\n</body>\n</html>"
}
```
