# Data Pipeline ETL

ETL workflow with extract, transform, load, and verification agents.

## Agents

1. Extract - Pulls raw data from source system
2. Transform - Cleans and validates data
3. Load - Pushes transformed data to target
4. Verify - Confirms data integrity

## Features Demonstrated

- **Sequential Pipeline**: Each stage depends on the previous
- **Error Tracking**: Detailed reports at each stage
- **Threshold-based Failures**: Automatic rollback on high error rates
- **Reconciliation**: Row counts verified end-to-end

## Running

```bash
# Set your source and target
export SOURCE_TYPE=api
export SOURCE_CONN=https://api.example.com/data
export TARGET_TYPE=database
export TARGET_CONN=postgresql://localhost:5432/warehouse

# Run the pipeline
chain-runner examples/data-pipeline/chain.json
```

## Workspace Structure

```
workspace/
  extract/
    raw-data.jsonl      - extracted records
    extract-report.md   - extraction stats
  transform/
    transformed-data.jsonl  - cleaned records
    rejected-records.jsonl  - bad records with reasons
    transform-report.md     - transformation stats
  load/
    load-report.md      - load results
  verify/
    verification-report.md  - final verification
```

## Configuration

Create spec files before running:

- `specs/data-source.md` - Source connection details
- `specs/transformation-rules.md` - Data cleaning rules
- `specs/target-schema.md` - Target table structure
- `specs/verification-criteria.md` - Success criteria
