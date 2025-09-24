# Merge Queue Status Check Action

Determines whether checks should be run when a PR is added to a merge queue by analyzing PR status and merge queue events.

## Usage

```yaml
jobs:
  check-conditions:
    runs-on: ubuntu-latest
    outputs:
      should_run_checks: ${{ steps.status.outputs.should-run-checks }}
    steps:
      - name: Check if checks should run
        id: status
        uses: ./.github/actions/merge-queue-status
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          merge-group-event: ${{ toJSON(github.event.merge_group) }}

  checks:
    needs: check-conditions
    if: needs.check-conditions.outputs.should_run_checks == 'true'
    uses: ./.github/workflows/run_checks_suite.yml
```

## Inputs

- `token` - GitHub token for API access (required)
- `merge-group-event` - Complete merge_group event as JSON (required)
- `pr-workflow-path` - Path to PR workflow file (default: `.github/workflows/update_pr.yml`)
- `checks-job-name` - Name of checks job to monitor (default: `checks / status`)

## Outputs

- `should-run-checks` - Whether checks should be run (boolean)
- `reason` - Reason for the decision (string)

## Logic

Runs checks if either of :

1. Most recent PR event (sync/force-push) was from `github-merge-queue[bot]`
2. Latest checks job failed/was cancelled/timed out
3. Checks job not found (conservative fallback)

**Detection Method:** The action examines the most recent `synchronize` or `head_ref_force_pushed` event in the PR timeline. If this event was created by `github-merge-queue[bot]`, we know the merge queue just acted on the PR and checks should run. Otherwise, we check the status of the last workflow run.

### Advanced Usage with Custom Parameters

```yaml
- name: Check merge queue status
  id: status
  uses: ./.github/actions/merge-queue-status
  with:
    token: ${{ secrets.GITHUB_TOKEN }}
    merge-group-event: ${{ toJSON(github.event.merge_group) }}
    # Customize these for your repository:
    pr-workflow-path: ".github/workflows/custom_pr.yml"
    checks-job-name: "validation"
```

## Inputs

| Input               | Description                            | Required | Default                           |
| ------------------- | -------------------------------------- | -------- | --------------------------------- |
| `token`             | GitHub token for API access            | Yes      | `${{ github.token }}`             |
| `merge-group-event` | The complete merge_group event as JSON | Yes      | -                                 |
| `pr-workflow-path`  | Path to the PR workflow file           | No       | `.github/workflows/update_pr.yml` |
| `checks-job-name`   | Name of the checks job to monitor      | No       | `checks`                          |

## Outputs

| Output              | Description                            | Type      |
| ------------------- | -------------------------------------- | --------- |
| `should-run-checks` | Whether checks should be run           | `boolean` |
| `reason`            | Human-readable reason for the decision | `string`  |
