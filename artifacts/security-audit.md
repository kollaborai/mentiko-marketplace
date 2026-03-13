---
id: security-audit
name: Security Audit Report
format: markdown
category: security
tags: [security, owasp, audit, vulnerability]
description: >
  Comprehensive security assessment following OWASP Top 10 and CWE Top 25. Documents
  vulnerabilities with CVSS scores, CWE IDs, and remediation steps. Produced by a
  security agent after static analysis, dependency scanning, and manual review.
author: mentiko
version: 1.0
schema:
  type: object
  properties:
    audit_id:
      type: string
      description: Unique audit identifier
    scope:
      type: string
      description: What was audited (codebase, service, API surface)
    methodology:
      type: array
      items:
        type: string
      description: Analysis methods used
    findings:
      type: array
      items:
        type: object
        properties:
          id:
            type: string
            description: Finding identifier e.g. SEC-001
          severity:
            type: string
            enum: [critical, high, medium, low, info]
          cvss_score:
            type: number
            minimum: 0
            maximum: 10
          cwe:
            type: string
            description: CWE identifier e.g. CWE-307
          title:
            type: string
          description:
            type: string
          remediation:
            type: string
    compliance:
      type: object
      description: Compliance status per framework
    risk_rating:
      type: string
      enum: [acceptable, mitigation-required, unacceptable]
      description: Overall risk disposition
  required: [scope, findings, risk_rating]
validation_rules:
  - severity must be one of critical, high, medium, low, info
  - cvss_score must be 0.0 to 10.0 inclusive
  - every critical or high finding must have a non-empty remediation field
  - risk_rating must be acceptable, mitigation-required, or unacceptable
related_artifacts:
  - security-scan-report
  - threat-model
---

# Security Audit Report

## Metadata

- Audit ID: SEC-AUDIT-2026-0312
- Audit date: 2026-03-12
- Auditor: Mentiko Security Agent v1.4 (reviewed by: Priya Sharma)
- Scope: Mentiko platform API — Next.js API routes, auth middleware, chain execution endpoints
- Methodology: OWASP Top 10 (2021), CWE Top 25, static analysis (semgrep), dependency audit (npm audit)

## Executive Summary

| Metric | Value |
|--------|-------|
| Total findings | 6 |
| Critical | 0 |
| High | 2 |
| Medium | 1 |
| Low | 1 |
| Info | 2 |
| Overall risk rating | mitigation-required |

Two high-severity findings require remediation before the next production deployment:
missing rate limiting on the chain execution endpoint (SEC-001) and stack trace exposure
in API error responses (SEC-002). The medium finding (weak session configuration) should
be addressed within 30 days. No critical findings were identified.

## Findings

---

### SEC-001: Missing Rate Limiting on Chain Execution Endpoint

**Severity:** High
**CVSS Score:** 7.5 (CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H)
**CWE:** CWE-770 — Allocation of Resources Without Limits or Throttling

**Description:**
The `POST /api/chains/run` endpoint does not implement rate limiting. An authenticated
user can submit an unlimited number of chain run requests in rapid succession. Each chain
run spawns one or more PTY agent sessions and consumes significant compute resources.
During testing, 200 concurrent chain run requests were submitted in under 2 seconds,
causing a 40% degradation in API response times for all other users.

**Attack Vector:**
An authenticated attacker (or a compromised account) sends rapid POST requests to
`/api/chains/run`. Each request spawns PTY sessions. System resources are exhausted
within seconds.

**Impact:**
Denial of service against the entire platform. All active chains and user sessions
are degraded or terminated. Estimated blast radius: 100% of concurrent users affected
for duration of attack.

**Remediation:**
Implement rate limiting at the API middleware layer using `next-rate-limit` or a Redis
token-bucket approach. Recommended limits: 10 chain run requests per user per minute,
50 per hour. Return HTTP 429 with `Retry-After` header on limit breach. Also add a
per-org concurrent chain cap (default: 5) enforced in `chain-runner.sh`.

**Evidence:**
```
# Load test: 200 requests in 1.8 seconds
ab -n 200 -c 200 -H "Cookie: session=..." http://localhost:3000/api/chains/run

Results:
  Requests per second: 111.2
  Failed requests: 0
  Time per request: 9.0ms (mean)
  API p99 (other endpoints during test): 2840ms (baseline: 180ms)
```

---

### SEC-002: Stack Traces Exposed in API Error Responses

**Severity:** High
**CVSS Score:** 7.1 (CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:N/A:N)
**CWE:** CWE-209 — Generation of Error Message Containing Sensitive Information

**Description:**
Unhandled exceptions in several API routes return full Node.js stack traces in the
JSON response body. The traces expose internal file paths, library versions, and
application structure. In `/api/runs/[id]/output`, an error in the file reading logic
returns the absolute path to internal log files (e.g. `/opt/mentiko/platform-build/web/.next/`).
This information significantly aids an attacker in fingerprinting the deployment environment.

**Attack Vector:**
Send a malformed request to any API endpoint that triggers an unhandled exception.
Inspect the `error.stack` field in the JSON response.

**Impact:**
Information disclosure. Internal file structure, library versions, and deployment paths
are visible to unauthenticated callers who can trigger errors. This is frequently the
first step in targeted exploitation.

**Remediation:**
Add a global error handler in `web/app/api/_middleware.ts` (or equivalent) that catches
all unhandled errors and returns a sanitized `{ error: "Internal server error", code: "ERR_INTERNAL" }`
response in production. Log the full stack trace server-side only. Set `NODE_ENV=production`
to disable Next.js development error overlays. Add `X-Content-Type-Options: nosniff`
and `X-Frame-Options: DENY` headers.

**Evidence:**
```json
POST /api/runs/invalid-id/output
HTTP 500

{
  "error": "ENOENT: no such file or directory, open '/opt/mentiko/platform-build/web/.next/server/app/api/runs/invalid-id/output/route.js'",
  "stack": "Error: ENOENT...\n    at Object.openSync (node:fs:596:3)\n    at /opt/mentiko/platform-build/web/.next/server/app/api/runs/..."
}
```

---

### SEC-003: Weak Session Cookie Configuration

**Severity:** Medium
**CVSS Score:** 5.3 (CVSS:3.1/AV:N/AC:H/PR:N/UI:R/S:U/C:H/I:N/A:N)
**CWE:** CWE-614 — Sensitive Cookie in HTTPS Session Without 'Secure' Attribute

**Description:**
The better-auth session cookie `better-auth.session_token` is set without the `SameSite=Strict`
attribute. The current configuration uses `SameSite=Lax`, which allows the cookie to be
sent with top-level cross-site navigations. Additionally, the session expiry is set to
30 days with no inactivity timeout, meaning a stolen session token remains valid for
the full 30-day period with no automatic invalidation.

**Remediation:**
Update `web/lib/auth.ts` to set `sameSite: "strict"` on the session cookie. Implement
an inactivity timeout of 7 days: if no API request is made for 7 days, invalidate the
session and require re-authentication. Add a `Max-Active-Sessions: 5` limit to prevent
session proliferation.

---

### SEC-004: Verbose Error Messages in Development Mode Left in Production Build

**Severity:** Low
**CVSS Score:** 3.1
**CWE:** CWE-532 — Insertion of Sensitive Information into Log File

**Description:**
Several API routes include `console.log(req.headers)` calls that were added during
development and not removed. In production, these log the full Authorization header
and Cookie values to stdout, which are captured in the platform's log aggregation system.
Any engineer with log access can extract session tokens.

**Remediation:**
Remove all `console.log(req.headers)` calls from production API routes. Add an ESLint
rule (`no-console` in production builds) to prevent recurrence. Audit existing logs
and rotate session tokens as a precaution.

---

### SEC-005: Dependency — jsonwebtoken 8.5.1 Has Known Vulnerability (Info)

**Severity:** Info
**CVSS Score:** 2.6
**CWE:** CWE-347 — Improper Verification of Cryptographic Signature

**Description:**
`jsonwebtoken@8.5.1` is pinned in `package.json`. Version 8.5.1 has CVE-2022-23529
(CVSS 7.6 — algorithm confusion attack). However, Mentiko does not use JWT verification
directly in user-facing code; this library is a transitive dependency of `better-auth`.
Risk is mitigated by better-auth's own verification layer, but the dependency should
be updated.

**Remediation:**
Run `npm audit fix` to update jsonwebtoken to 9.x. Verify better-auth compatibility
with the updated version.

---

### SEC-006: CORS Policy Allows All Origins in Development Build (Info)

**Severity:** Info
**CVSS Score:** 0.0
**CWE:** CWE-942 — Permissive Cross-domain Policy

**Description:**
`web/next.config.ts` sets `Access-Control-Allow-Origin: *` when `NODE_ENV !== 'production'`.
This is a development convenience but has been observed in the staging environment where
`NODE_ENV` is not explicitly set. Verify that staging sets `NODE_ENV=production`.

**Remediation:**
Explicitly set `NODE_ENV=production` in staging deployment configuration. Add an assertion
in the deployment checklist.

---

## Compliance Assessment

| Framework | Status | Notes |
|-----------|--------|-------|
| OWASP Top 10 (2021) | Partial | A01 (Broken Access Control): pass; A03 (Injection): pass; A04 (Insecure Design): fail (rate limiting); A05 (Misconfiguration): fail (stack traces) |
| SOC 2 Type II | Not assessed | Formal assessment required; current findings would block certification |
| GDPR | Partial | Data retention and deletion implemented; session management needs improvement |

## Recommendations

1. Immediate (within 1 sprint — High findings):
   - Implement rate limiting on `/api/chains/run` (SEC-001)
   - Add global error handler to suppress stack traces in production (SEC-002)

2. Short-term (within 30 days — Medium findings):
   - Update session cookie to `SameSite=Strict` and add inactivity timeout (SEC-003)
   - Remove debug `console.log` calls from production routes (SEC-004)

3. Long-term (next quarter — Low/Info):
   - Update jsonwebtoken transitive dependency (SEC-005)
   - Audit all environments for correct `NODE_ENV=production` (SEC-006)
   - Engage external penetration testing firm for full assessment before SOC 2 audit

## Conclusion

Risk rating: mitigation-required

No critical vulnerabilities were found. The two high findings (missing rate limiting
and stack trace exposure) are straightforward to fix and should be addressed before
the next production deployment. The overall security posture is appropriate for an
early-stage SaaS product and will reach acceptable with the recommended remediations.
