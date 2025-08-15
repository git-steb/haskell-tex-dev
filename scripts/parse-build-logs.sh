#!/bin/bash
set -euo pipefail

# GitHub Actions Log Parser
# Usage: ./scripts/parse-build-logs.sh <run_id> [job_id]
# Example: ./scripts/parse-build-logs.sh 17001020624

RUN_ID="${1:-}"
JOB_ID="${2:-}"

if [[ -z "$RUN_ID" ]]; then
    echo "Usage: $0 <run_id> [job_id]"
    echo "Example: $0 17001020624"
    exit 1
fi

echo "🔍 Parsing GitHub Actions logs for run $RUN_ID..."

# Get run details
echo "📋 Run Details:"
gh run view "$RUN_ID" --json status,conclusion,createdAt,updatedAt,headBranch,headSha

# Get jobs if no specific job provided
if [[ -z "$JOB_ID" ]]; then
    echo -e "\n📋 Jobs in this run:"
    gh api "repos/git-steb/haskell-tex-dev/actions/runs/$RUN_ID/jobs" --jq '.jobs[] | "\(.id): \(.name) - \(.status)/\(.conclusion // "unknown")"'
    
    echo -e "\n💡 To get logs for a specific job, run:"
    echo "$0 $RUN_ID <job_id>"
    exit 0
fi

echo -e "\n📋 Job Details:"
gh api "repos/git-steb/haskell-tex-dev/actions/jobs/$JOB_ID" --jq '. | "Name: \(.name)\nStatus: \(.status)\nConclusion: \(.conclusion // "unknown")\nStarted: \(.started_at)\nCompleted: \(.completed_at // "not completed")"'

echo -e "\n📋 Steps:"
gh api "repos/git-steb/haskell-tex-dev/actions/jobs/$JOB_ID" --jq '.steps[] | "\(.number): \(.name) - \(.status)/\(.conclusion // "unknown")"'

# Get and parse logs
echo -e "\n📜 Full Logs (last 100 lines):"
gh run view "$RUN_ID" --log | tail -100

echo -e "\n🚨 Error Summary:"
gh run view "$RUN_ID" --log | grep -i -A5 -B5 "error\|failed\|failed to\|operation not permitted\|permission denied" || echo "No obvious errors found in last 100 lines"

echo -e "\n🔧 Docker Build Errors (if any):"
gh run view "$RUN_ID" --log | grep -i -A3 -B3 "docker\|build\|failed to build" || echo "No Docker build errors found in last 100 lines"

echo -e "\n💡 To see full logs, run:"
echo "gh run view $RUN_ID --log"
