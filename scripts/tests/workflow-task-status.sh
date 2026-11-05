#!/usr/bin/env bash
set -euo pipefail

test_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
workflow=$test_dir/../workflow-task.sh
scratch=$(mktemp -d "${TMPDIR:-/tmp}/workflow-task-status.XXXXXX")
trap 'rm -rf -- "$scratch"' EXIT
export TMPDIR=$scratch LC_ALL=C
unset BASH_ENV GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR GIT_INDEX_FILE \
  GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_COUNT=0

total=0
failures=0
task_relative=2000/01/02/target/task.md

write_task() {
  printf '%s\n' '---' "status: $1" "created-at: '2000-01-02T03:04:05+00:00'" '---'
  cat <<'EOF'

# Task: Status transition fixture

## Goal

Preserve the contract, metadata, and this example:

```yaml
status: draft
```
EOF
}

setup_fixture() {
  repo="$scratch/case $total"
  git init --quiet --template= "$repo"
  task=$repo/.copilot/$task_relative
  other=$repo/.copilot/2000/01/02/current/task.md
  mkdir -p "$(dirname "$task")" "$(dirname "$other")"
  write_task "$1" > "$task"
  write_task approved > "$other"
  printf '%s\n' '.copilot/2000/01/02/current/task.md' > "$repo/.copilot/current-task.txt"
  expected=$repo/expected
  cp -R "$repo/.copilot" "$expected"
}

expect_success() {
  local status=$1 output
  if output=$(cd "$repo" && bash "$workflow" \
    -Action set-status -TaskPath "$task" -Status "$status" 2> "$repo/stderr"); then
    if [ "$output" != "$task" ]; then
      printf '  Expected task path %s, got %s\n' "$task" "$output" >&2
      return 1
    fi
  else
    printf '  set-status %s should succeed:\n' "$status" >&2
    cat "$repo/stderr" >&2
    return 1
  fi
}

expect_status() {
  write_task "$1" > "$expected/$task_relative"
  diff -ru "$expected" "$repo/.copilot"
}

approve() {
  expect_success approved
  expect_status approved
}

implement() {
  expect_success in-progress
  expect_status in-progress
  expect_success implemented
  expect_status implemented
}

reject() {
  if (cd "$repo" && bash "$workflow" \
    -Action set-status -TaskPath "$task" -Status "$1" > "$repo/stdout" 2> "$repo/stderr"); then
    printf '  set-status %s should be rejected\n' "$1" >&2
    return 1
  fi
  diff -ru "$expected" "$repo/.copilot"
}

run_case() {
  local label=$1 initial=$2 scenario=$3 result
  shift 3
  total=$((total + 1))
  set +e
  (
    set -e
    trap - EXIT
    setup_fixture "$initial"
    "$scenario" "$@"
  )
  result=$?
  set -e
  if [ "$result" -eq 0 ]; then
    printf 'PASS: %s\n' "$label"
  else
    printf 'FAIL: %s\n' "$label" >&2
    failures=$((failures + 1))
  fi
}

run_case 'draft -> approved' draft approve
run_case 'approved -> approved is idempotent' approved approve
run_case 'approved -> in-progress -> implemented' approved implement
run_case 'in-progress -> approved is rejected without changes' in-progress reject approved
run_case 'implemented -> approved is rejected without changes' implemented reject approved
run_case 'draft -> in-progress is rejected without changes' draft reject in-progress

printf '%d passed; %d failed\n' "$((total - failures))" "$failures"
[ "$failures" -eq 0 ]
