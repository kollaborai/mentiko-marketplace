---
id: security-scan-report
name: Security Scan Report
format: json
category: security
tags: [sast, dast, security, vulnerabilities, cve, owasp]
description: Automated SAST/DAST security scan results with CWE/OWASP mappings, code-level findings, and remediation guidance. Complements manual audits.
author: mentiko
version: 1.0
schema:
  type: object
  properties:
    tool:
      type: string
      description: Scanner name and version (e.g. "semgrep 1.63.0")
    scan_type:
      type: string
      enum: [sast, dast, sca, iast, secrets]
      description: Type of scan performed
    target:
      type: string
      description: Path, URL, or repo scanned
    scanned_at:
      type: string
      format: date-time
    duration_ms:
      type: number
      description: Total scan duration in milliseconds
    vulnerabilities:
      type: array
      items:
        type: object
        properties:
          id:
            type: string
            description: Internal finding ID (e.g. "SCAN-001")
          cwe:
            type: string
            description: CWE identifier (e.g. "CWE-89")
          owasp_category:
            type: string
            description: OWASP Top 10 category (e.g. "A03:2021-Injection")
          severity:
            type: string
            enum: [critical, high, medium, low, info]
          file:
            type: string
            description: Relative file path
          line:
            type: integer
            description: Line number of finding
          column:
            type: integer
            description: Column number (optional)
          rule_id:
            type: string
            description: Scanner rule that triggered
          description:
            type: string
            description: Human-readable description of the vulnerability
          code_snippet:
            type: string
            description: Relevant code excerpt (max 10 lines)
          recommendation:
            type: string
            description: Specific fix guidance
          references:
            type: array
            items:
              type: string
            description: Links to CVE, CWE, docs
        required: [id, cwe, severity, file, line, description, recommendation]
    stats:
      type: object
      properties:
        critical:
          type: integer
        high:
          type: integer
        medium:
          type: integer
        low:
          type: integer
        info:
          type: integer
        total:
          type: integer
      required: [critical, high, medium, low, info, total]
    files_scanned:
      type: integer
    rules_applied:
      type: integer
    false_positive_filter:
      type: boolean
      description: Whether suppression rules were applied
  required: [tool, scan_type, target, scanned_at, vulnerabilities, stats]
validation_rules:
  - stats.total must equal sum of stats.critical + stats.high + stats.medium + stats.low + stats.info
  - each vulnerability.id must be unique within the report
  - severity must be one of critical, high, medium, low, info
  - scan_type must be one of sast, dast, sca, iast, secrets
  - file paths in vulnerabilities must be relative (not absolute)
  - code_snippet must not exceed 20 lines
  - duration_ms must be a positive number
related_artifacts: [security-audit, threat-model, dependency-audit]
---

{
  "tool": "semgrep 1.63.0",
  "scan_type": "sast",
  "target": "src/",
  "scanned_at": "2026-03-13T09:14:22Z",
  "duration_ms": 4831,
  "files_scanned": 127,
  "rules_applied": 340,
  "false_positive_filter": true,
  "vulnerabilities": [
    {
      "id": "SCAN-001",
      "cwe": "CWE-89",
      "owasp_category": "A03:2021-Injection",
      "severity": "critical",
      "file": "src/db/query-builder.ts",
      "line": 84,
      "column": 22,
      "rule_id": "typescript.sequelize.sql-injection",
      "description": "User-controlled input is concatenated directly into a SQL query string without parameterization. An attacker can inject arbitrary SQL via the `filter` parameter.",
      "code_snippet": "const rows = await db.query(\n  `SELECT * FROM users WHERE name = '${req.query.filter}'`\n);",
      "recommendation": "Use parameterized queries or an ORM query builder. Replace string interpolation with a bound parameter: db.query('SELECT * FROM users WHERE name = $1', [req.query.filter])",
      "references": [
        "https://cwe.mitre.org/data/definitions/89.html",
        "https://owasp.org/Top10/A03_2021-Injection/"
      ]
    },
    {
      "id": "SCAN-002",
      "cwe": "CWE-798",
      "owasp_category": "A02:2021-Cryptographic_Failures",
      "severity": "high",
      "file": "src/integrations/stripe.ts",
      "line": 12,
      "column": 30,
      "rule_id": "typescript.secrets.hardcoded-api-key",
      "description": "A Stripe secret key is hardcoded as a string literal. This will be exposed in version control history and any environment with access to the source.",
      "code_snippet": "const stripe = new Stripe('sk_live_4xT9...mK2p', { apiVersion: '2023-10-16' });",
      "recommendation": "Move all credentials to environment variables or a secrets manager. Use process.env.STRIPE_SECRET_KEY and ensure the key is rotated immediately.",
      "references": [
        "https://cwe.mitre.org/data/definitions/798.html"
      ]
    },
    {
      "id": "SCAN-003",
      "cwe": "CWE-22",
      "owasp_category": "A01:2021-Broken_Access_Control",
      "severity": "high",
      "file": "src/api/files/download.ts",
      "line": 31,
      "column": 16,
      "rule_id": "typescript.path-traversal",
      "description": "File path is constructed from user input without sanitization. An attacker can request paths like ../../etc/passwd to read arbitrary files.",
      "code_snippet": "const filePath = path.join(UPLOAD_DIR, req.params.filename);\nconst data = fs.readFileSync(filePath);",
      "recommendation": "Normalize and validate paths before use. Ensure the resolved path starts with the expected base directory: if (!resolvedPath.startsWith(UPLOAD_DIR)) return res.status(403).send('Forbidden');",
      "references": [
        "https://cwe.mitre.org/data/definitions/22.html",
        "https://owasp.org/Top10/A01_2021-Broken_Access_Control/"
      ]
    }
  ],
  "stats": {
    "critical": 1,
    "high": 2,
    "medium": 0,
    "low": 0,
    "info": 0,
    "total": 3
  }
}
