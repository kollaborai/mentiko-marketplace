---
id: ui-component
name: Generated UI Component
format: code
category: web
tags: [react, vue, typescript, component, frontend, ui]
description: Agent-generated React or Vue component with typed props, dependencies, and file path. Ready to drop into a project after dependency installation.
author: mentiko
version: 1.0
schema:
  type: object
  properties:
    framework:
      type: string
      enum: [react, vue, svelte, solid]
      description: Frontend framework the component targets
    component_name:
      type: string
      description: PascalCase component identifier
    file_path:
      type: string
      description: Relative path where the component should be written (e.g. src/components/UserCard.tsx)
    props:
      type: array
      description: Component prop definitions
      items:
        type: object
        properties:
          name:
            type: string
          type:
            type: string
          required:
            type: boolean
          default:
            description: Default value for optional props
          description:
            type: string
        required: [name, type, required]
    code:
      type: string
      description: Full component source code including imports
    dependencies:
      type: array
      items:
        type: string
      description: npm package names required (not in stdlib or react itself)
    peer_dependencies:
      type: array
      items:
        type: string
      description: Packages that must already be installed (react, vue, etc.)
    typescript:
      type: boolean
      description: True if the code uses TypeScript
    exports:
      type: array
      items:
        type: string
      description: Named exports in addition to the default export
  required: [framework, component_name, file_path, props, code, dependencies, typescript]
validation_rules:
  - component_name must be PascalCase (starts with uppercase letter)
  - file_path must be a relative path (no leading slash)
  - file_path extension must match framework and typescript fields (.tsx for react+ts, .vue for vue, etc.)
  - code must contain the component_name as an exported identifier
  - all required props must appear in the code signature
  - dependencies must not include react, react-dom, or vue (those belong in peer_dependencies)
  - if typescript is true, code must include at least one TypeScript type annotation
related_artifacts: [css-stylesheet, html-template, form-schema]
---

```json
{
  "framework": "react",
  "component_name": "MetricCard",
  "file_path": "src/components/dashboard/MetricCard.tsx",
  "typescript": true,
  "props": [
    { "name": "label", "type": "string", "required": true, "description": "Metric display label" },
    { "name": "value", "type": "number | string", "required": true, "description": "Primary metric value" },
    { "name": "delta", "type": "number", "required": false, "default": null, "description": "Change vs previous period (positive = up)" },
    { "name": "deltaLabel", "type": "string", "required": false, "default": "vs last period", "description": "Text next to delta value" },
    { "name": "icon", "type": "React.ReactNode", "required": false, "default": null, "description": "Optional icon rendered in card header" },
    { "name": "loading", "type": "boolean", "required": false, "default": false, "description": "Render skeleton state" },
    { "name": "onClick", "type": "() => void", "required": false, "default": null, "description": "Optional click handler" }
  ],
  "dependencies": ["clsx"],
  "peer_dependencies": ["react", "react-dom"],
  "exports": ["MetricCardSkeleton"],
  "code": "import React from 'react';\nimport clsx from 'clsx';\n\nexport interface MetricCardProps {\n  label: string;\n  value: number | string;\n  delta?: number | null;\n  deltaLabel?: string;\n  icon?: React.ReactNode;\n  loading?: boolean;\n  onClick?: (() => void) | null;\n}\n\nexport function MetricCardSkeleton() {\n  return (\n    <div className=\"rounded-md bg-muted animate-pulse p-4 h-28\" aria-busy=\"true\" />\n  );\n}\n\nexport default function MetricCard({\n  label,\n  value,\n  delta = null,\n  deltaLabel = 'vs last period',\n  icon = null,\n  loading = false,\n  onClick = null,\n}: MetricCardProps) {\n  if (loading) return <MetricCardSkeleton />;\n\n  const deltaPositive = delta !== null && delta > 0;\n  const deltaNegative = delta !== null && delta < 0;\n\n  return (\n    <div\n      className={clsx(\n        'rounded-md bg-card p-4 flex flex-col gap-2',\n        onClick && 'cursor-pointer hover:bg-accent transition-colors',\n      )}\n      onClick={onClick ?? undefined}\n      role={onClick ? 'button' : undefined}\n      tabIndex={onClick ? 0 : undefined}\n    >\n      <div className=\"flex items-center justify-between\">\n        <span className=\"text-sm text-muted-foreground\">{label}</span>\n        {icon && <span className=\"text-muted-foreground\">{icon}</span>}\n      </div>\n      <span className=\"text-2xl font-semibold tabular-nums\">{value}</span>\n      {delta !== null && (\n        <span\n          className={clsx(\n            'text-xs',\n            deltaPositive && 'text-green-500',\n            deltaNegative && 'text-red-500',\n            !deltaPositive && !deltaNegative && 'text-muted-foreground',\n          )}\n        >\n          {deltaPositive ? '+' : ''}{delta}% {deltaLabel}\n        </span>\n      )}\n    </div>\n  );\n}\n"
}
```
