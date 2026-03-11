# Customer Onboarding Pipeline

Automated new customer setup workflow with welcome, provision, train, and followup agents.

## Agents

1. Welcome - Sends personalized welcome email and materials
2. Provision - Creates accounts, resources, and configurations
3. Train - Prepares customized training agenda and materials
4. Followup - Creates success plan with milestones

## Features Demonstrated

- **Tier-based Logic**: Different flows for basic/pro/enterprise
- **Template System**: Personalized emails and documents from templates
- **Multi-stage Setup**: Each stage builds on the previous
- **Success Tracking**: 30-60-90 day milestones

## Running

```bash
# Set customer details
export CUSTOMER_NAME="Acme Corp"
export CONTACT_NAME="Jane Smith"
export CONTACT_EMAIL="jane@acme.com"
export TIER=enterprise
export PLAN=annual
export REGION=us-east-1
export COMPANY_SIZE="500-1000"

# Run the onboarding
chain-runner examples/customer-onboarding/chain.json
```

## Workspace Structure

```
workspace/
  welcome/
    welcome-email.md       - personalized welcome
    account-summary.md     - customer details
    onboarding-timeline.md - expected milestones
    checklist.md           - onboarding tasks
  provision/
    provisioning-report.md  - created resources
    accounts.md            - user accounts and roles
    credentials.md         - secure delivery instructions
    resources.md           - databases, storage, etc
    api-keys.md            - generated access keys
    configuration.md       - app settings
  train/
    training-agenda.md     - customized agenda
    training-schedule.md   - session dates
    materials.md           - docs and videos
    exercises.md           - hands-on activities
    role-guides/          - role-specific guides
    faq.md                - common questions
  followup/
    success-plan.md        - 30-60-90 day plan
    milestones.md          - key milestones
    checkins.md            - meeting schedule
    success-metrics.md     - KPIs to track
    support-plan.md        - ongoing support
```

## Configuration

Create template files before running:

- `templates/welcome-email.md` - Welcome email template
- `templates/onboarding-checklist.md` - Default checklist
- `templates/training-agenda.md` - Training outline
- `templates/success-plan.md` - Success plan template

- `specs/provisioning-rules.md` - Tier-based provisioning rules
