---
id: dependency-audit
name: Dependency Audit Report
format: json
category: security
tags: [dependencies, npm, pip, cargo, vulnerabilities, cve, licenses, supply-chain]
description: Full dependency audit covering outdated packages, CVE vulnerabilities, and license compatibility. Works with npm audit, pip-audit, cargo audit, etc.
author: mentiko
version: 1.0
schema:
  type: object
  properties:
    package_manager:
      type: string
      enum: [npm, yarn, pnpm, pip, cargo, go, composer, maven, gradle]
    manifest_file:
      type: string
      description: Package manifest that was audited (e.g. "package.json", "requirements.txt")
    audited_at:
      type: string
      format: date-time
    total_deps:
      type: integer
      description: Total direct + transitive dependencies
    direct_deps:
      type: integer
      description: Directly declared dependencies
    transitive_deps:
      type: integer
      description: Indirect/transitive dependencies
    outdated:
      type: array
      description: Packages with available updates
      items:
        type: object
        properties:
          name:
            type: string
          current:
            type: string
            description: Installed version
          wanted:
            type: string
            description: Latest compatible version (respects semver range)
          latest:
            type: string
            description: Absolute latest published version
          breaking:
            type: boolean
            description: True if latest is a major version bump
          deprecated:
            type: boolean
            description: True if current version is officially deprecated
          update_urgency:
            type: string
            enum: [critical, high, medium, low]
            description: Urgency based on age, deprecation, and vulnerability status
        required: [name, current, latest, breaking, update_urgency]
    vulnerable:
      type: array
      description: Packages with known CVEs
      items:
        type: object
        properties:
          name:
            type: string
          version:
            type: string
          cve:
            type: string
            description: CVE identifier (e.g. "CVE-2024-21538")
          cvss_score:
            type: number
            minimum: 0
            maximum: 10
          severity:
            type: string
            enum: [critical, high, moderate, low]
          title:
            type: string
            description: Brief vulnerability title
          description:
            type: string
          fix_version:
            type: string
            description: Minimum version that fixes the CVE
          path:
            type: string
            description: Dependency chain showing how it's included
          patched:
            type: boolean
            description: Whether a fix is available
        required: [name, version, cve, severity, title, fix_version, patched]
    licenses:
      type: array
      description: License analysis for all dependencies
      items:
        type: object
        properties:
          license:
            type: string
            description: SPDX license identifier
          package_count:
            type: integer
          packages:
            type: array
            items:
              type: string
          compatible:
            type: boolean
            description: Whether compatible with your project license
          risk:
            type: string
            enum: [none, low, medium, high]
        required: [license, package_count, compatible]
    stats:
      type: object
      properties:
        outdated_count:
          type: integer
        vulnerable_count:
          type: integer
        critical_vulns:
          type: integer
        high_vulns:
          type: integer
        incompatible_licenses:
          type: integer
    summary:
      type: string
  required: [package_manager, manifest_file, audited_at, total_deps, outdated, vulnerable, licenses, stats]
validation_rules:
  - stats.vulnerable_count must equal vulnerable array length
  - stats.outdated_count must equal outdated array length
  - cvss_score must be between 0.0 and 10.0
  - severity must align with cvss_score (critical >= 9.0, high >= 7.0, moderate >= 4.0)
  - fix_version must be a valid semver string when patched is true
  - each cve identifier must match pattern CVE-YYYY-NNNNN
  - direct_deps + transitive_deps should equal total_deps
related_artifacts: [security-scan-report, security-audit]
---

{
  "package_manager": "npm",
  "manifest_file": "package.json",
  "audited_at": "2026-03-13T08:00:00Z",
  "total_deps": 487,
  "direct_deps": 42,
  "transitive_deps": 445,
  "stats": {
    "outdated_count": 6,
    "vulnerable_count": 3,
    "critical_vulns": 1,
    "high_vulns": 1,
    "incompatible_licenses": 1
  },
  "outdated": [
    {
      "name": "next",
      "current": "15.1.4",
      "wanted": "15.2.3",
      "latest": "16.0.1",
      "breaking": false,
      "deprecated": false,
      "update_urgency": "high"
    },
    {
      "name": "better-auth",
      "current": "1.1.8",
      "wanted": "1.2.1",
      "latest": "1.2.1",
      "breaking": false,
      "deprecated": false,
      "update_urgency": "medium"
    },
    {
      "name": "sharp",
      "current": "0.32.6",
      "wanted": "0.32.6",
      "latest": "0.33.5",
      "breaking": true,
      "deprecated": true,
      "update_urgency": "high"
    },
    {
      "name": "ws",
      "current": "8.14.2",
      "wanted": "8.18.0",
      "latest": "8.18.0",
      "breaking": false,
      "deprecated": false,
      "update_urgency": "critical"
    },
    {
      "name": "@types/node",
      "current": "20.14.0",
      "wanted": "22.13.4",
      "latest": "22.13.4",
      "breaking": false,
      "deprecated": false,
      "update_urgency": "low"
    },
    {
      "name": "eslint",
      "current": "8.57.1",
      "wanted": "8.57.1",
      "latest": "9.22.0",
      "breaking": true,
      "deprecated": false,
      "update_urgency": "low"
    }
  ],
  "vulnerable": [
    {
      "name": "ws",
      "version": "8.14.2",
      "cve": "CVE-2024-37890",
      "cvss_score": 9.1,
      "severity": "critical",
      "title": "ws: DoS via headers with an excessive number of values",
      "description": "A request with a number of headers exceeding the server.maxHeadersCount threshold could be used to crash a ws server, causing a Denial of Service attack.",
      "fix_version": "8.17.1",
      "path": "ws (direct)",
      "patched": true
    },
    {
      "name": "express",
      "version": "4.18.2",
      "cve": "CVE-2024-43796",
      "cvss_score": 7.3,
      "severity": "high",
      "title": "express: XSS in res.redirect() when URL contains HTML entities",
      "description": "In express 4.x before 4.19.2, passing untrusted user input to res.redirect() can lead to a reflected XSS vulnerability when the Location header is echoed into the response body.",
      "fix_version": "4.19.2",
      "path": "express (direct)",
      "patched": true
    },
    {
      "name": "semver",
      "version": "5.7.1",
      "cve": "CVE-2022-25883",
      "cvss_score": 5.3,
      "severity": "moderate",
      "title": "semver: Regular Expression Denial of Service (ReDoS)",
      "description": "Versions prior to 7.5.2 are vulnerable to Regular Expression Denial of Service via the coerce() function when parsing untrusted input.",
      "fix_version": "7.5.2",
      "path": "npm > node-gyp > semver@5.7.1",
      "patched": true
    }
  ],
  "licenses": [
    {
      "license": "MIT",
      "package_count": 381,
      "packages": ["react", "next", "tailwindcss", "zustand"],
      "compatible": true,
      "risk": "none"
    },
    {
      "license": "Apache-2.0",
      "package_count": 62,
      "packages": ["@anthropic-ai/sdk", "googleapis"],
      "compatible": true,
      "risk": "none"
    },
    {
      "license": "BSD-3-Clause",
      "package_count": 28,
      "packages": ["qs", "commander"],
      "compatible": true,
      "risk": "none"
    },
    {
      "license": "GPL-3.0",
      "package_count": 1,
      "packages": ["gpl-licensed-util"],
      "compatible": false,
      "risk": "high"
    },
    {
      "license": "ISC",
      "package_count": 15,
      "packages": ["glob", "semver"],
      "compatible": true,
      "risk": "none"
    }
  ],
  "summary": "3 vulnerable packages found, including a critical DoS vulnerability in ws@8.14.2 (CVE-2024-37890) — fix immediately by upgrading to ws@8.17.1+. 1 GPL-3.0 licensed dependency detected (gpl-licensed-util) which is license-incompatible with a commercial product. 6 packages are outdated; sharp@0.32.6 is deprecated and needs a breaking-change upgrade."
}
