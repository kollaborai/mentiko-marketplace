# DevOps Deployment Pipeline

Automated CI/CD pipeline with build, parallel testing, deploy, and verify agents.

## Agents

1. Build - Compiles code and creates artifacts
2. Unit Test - Runs unit tests with coverage
3. Integration Test - Tests API and external integrations
4. Security Scan - Scans for vulnerabilities
5. Deploy - Deploys to environment
6. Verify - Confirms deployment health

## Features Demonstrated

- **Parallel Testing**: Unit, integration, and security tests run simultaneously
- **Quality Gates**: Each stage must pass before proceeding
- **Rollback Support**: Failed deployments can be rolled back
- **Health Verification**: Post-deployment smoke tests

## Running

```bash
# Set deployment parameters
export APP_NAME=myapp
export ENVIRONMENT=staging
export REGION=us-east-1
export REGISTRY=ghcr.io/myorg
export CLUSTER=eks-staging

# Run the pipeline
chain-runner examples/dev-ops/chain.json
```

## Workspace Structure

```
workspace/
  build/
    build-report.md    - build output
    artifacts/         - compiled outputs
    image-tag.txt      - docker image reference
  test/
    unit/
      test-report.md   - unit test results
      coverage-report.md
    integration/
      test-report.md   - integration results
      api-test-results.md
    security/
      security-report.md   - vulnerability scan
      dependencies.md      - vulnerable deps
  deploy/
    deploy-report.md   - deployment output
    deployment-info.json
    health-check.md
  verify/
    verification-report.md  - final health check
    health-checks.md
    smoke-tests.md
    metrics.md
```

## Configuration

Create spec files before running:

- `specs/build-config.md` - Build commands and docker settings
- `specs/test-config.md` - Test commands and coverage thresholds
- `specs/security-config.md` - Security scanning tools and rules
- `specs/deploy-config.md` - Deployment targets and strategies
- `specs/verify-config.md` - Health check endpoints and smoke tests

## Production Deployment

For production, add approval requirement by editing the deploy agent's authorities section.
