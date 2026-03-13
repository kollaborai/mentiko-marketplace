---
id: css-stylesheet
name: Generated CSS Stylesheet
format: code
category: web
tags: [css, tailwind, styles, frontend, ui, design]
description: Agent-generated styles for a UI element or component. Covers Tailwind utility classes and/or custom CSS, with responsive breakpoints and dark mode variants.
author: mentiko
version: 1.0
schema:
  type: object
  properties:
    framework:
      type: string
      enum: [tailwind, css-modules, plain-css, sass, styled-components, emotion]
      description: CSS methodology or framework used
    target_element:
      type: string
      description: Component or element these styles apply to (e.g. "PricingCard", "nav.main-nav")
    classes:
      type: ["array", "null"]
      items:
        type: string
      description: Tailwind utility class list (null if framework is not tailwind)
    class_string:
      type: ["string", "null"]
      description: Pre-joined class string for direct use in className or class attributes
    custom_css:
      type: ["string", "null"]
      description: Raw CSS string for properties not achievable with utilities alone
    css_variables:
      type: object
      description: CSS custom property definitions (key = variable name including --)
      additionalProperties:
        type: string
    responsive_breakpoints:
      type: object
      description: Breakpoint-specific class overrides keyed by Tailwind breakpoint prefix (sm, md, lg, xl, 2xl)
      properties:
        sm: { type: array, items: { type: string } }
        md: { type: array, items: { type: string } }
        lg: { type: array, items: { type: string } }
        xl: { type: array, items: { type: string } }
        "2xl": { type: array, items: { type: string } }
    dark_mode_classes:
      type: ["array", "null"]
      items:
        type: string
      description: dark: prefixed Tailwind classes (or empty if handled in custom_css)
    animations:
      type: array
      items:
        type: object
        properties:
          name: { type: string }
          keyframes: { type: string }
          usage_class: { type: string }
        required: [name, keyframes, usage_class]
      description: Custom @keyframe animations defined for this component
  required: [framework, target_element]
validation_rules:
  - classes must be null when framework is not tailwind
  - custom_css must be valid CSS syntax (no SCSS nesting unless framework is sass)
  - class_string must equal classes joined by a single space if both are present
  - css_variables keys must start with -- (CSS custom property convention)
  - responsive_breakpoints keys must be valid Tailwind breakpoint names (sm, md, lg, xl, 2xl)
  - dark_mode_classes entries must begin with dark: prefix
  - animation.keyframes must contain at least one keyframe percentage or from/to keyword
related_artifacts: [ui-component, html-template]
---

```json
{
  "framework": "tailwind",
  "target_element": "PricingCard",
  "classes": [
    "relative",
    "flex",
    "flex-col",
    "gap-6",
    "rounded-md",
    "bg-card",
    "p-6",
    "transition-colors",
    "duration-150"
  ],
  "class_string": "relative flex flex-col gap-6 rounded-md bg-card p-6 transition-colors duration-150",
  "dark_mode_classes": [
    "dark:bg-card",
    "dark:text-foreground"
  ],
  "responsive_breakpoints": {
    "md": ["p-8", "gap-8"],
    "lg": ["p-10"]
  },
  "css_variables": {
    "--pricing-card-glow": "0 0 0 1px hsl(var(--primary) / 0.4)"
  },
  "custom_css": ".pricing-card--featured {\n  box-shadow: var(--pricing-card-glow);\n}\n\n.pricing-card__price-amount {\n  font-variant-numeric: tabular-nums;\n  letter-spacing: -0.03em;\n}\n\n.pricing-card__feature-list li + li {\n  margin-top: 0.5rem;\n}\n\n@media (prefers-reduced-motion: no-preference) {\n  .pricing-card--featured {\n    animation: pulse-glow 3s ease-in-out infinite;\n  }\n}",
  "animations": [
    {
      "name": "pulse-glow",
      "keyframes": "@keyframes pulse-glow {\n  0%, 100% { box-shadow: 0 0 0 1px hsl(var(--primary) / 0.4); }\n  50% { box-shadow: 0 0 0 3px hsl(var(--primary) / 0.2); }\n}",
      "usage_class": "animate-[pulse-glow_3s_ease-in-out_infinite]"
    }
  ]
}
```
