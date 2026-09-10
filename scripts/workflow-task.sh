#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf '%s\n' "Usage: $0 -Action {create|current|set-status} [options]" >&2
  printf '%s\n' "  create: -Name NAME [-IncludeRepository PATH ...] [-AllowDirty]" >&2
  printf '%s\n' "  set-status: -TaskPath PATH -Status {in-progress|implemented}" >&2
}
die() { printf 'Error: %s\n' "$1" >&2; exit 1; }
case " ${*:-} " in *" -h "*|*" --help "*) usage; exit 0;; esac
repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || die "This script must run inside a Git repository."
state_root=$repo_root/.copilot
current_file=$state_root/current-task.txt
NBSP=$(printf '\302\240')

yaml_quote() { printf "'%s'" "${1//\'/\'\'}"; }
lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }
safe_path() {
  local value=$1 description=$2 segment
  [ -n "$value" ] && [ "$value" = "${value# }" ] && [ "$value" = "${value% }" ] || die "$description must be a non-empty relative repository path."
  case $value in /*|[A-Za-z]:*|*\\*) die "$description must not be an absolute path.";; esac
  value=${value//\\//}
  [ "$value" != "${value#/}" ] && die "$description must be a non-empty relative repository path."
  local oldifs=$IFS; IFS=/
  for segment in $value; do
    [ -n "$segment" ] && [ "$segment" != "." ] && [ "$segment" != ".." ] || die "$description contains an unsafe or invalid path segment."
    case $segment in *[[:space:]]*|*[\<\>:\"\|\?\*]*|*$'\n'*|*$'\r'*) die "$description contains an unsafe or invalid path segment.";; esac
  done
  IFS=$oldifs
  printf '%s' "$value"
}
repository_name() {
  local value=$1 description=$2
  [ -n "$value" ] && [ "$value" = "${value# }" ] && [ "$value" = "${value% }" ] || die "$description contains invalid characters."
  case $value in *[\\/:\*\?\"\<\>\|]*|*$'\n'*|*$'\r'*) die "$description contains invalid characters.";; esac
}
dirty() { [ -n "$(git -C "$1" status --porcelain=v1 --untracked-files=all)" ]; }
iso_now() { local z; z=$(date +%z); printf '%s%s:%s' "$(date +%Y-%m-%dT%H:%M:%S)" "${z%??}" "${z#???}"; }

parse_config() {
  local config=$repo_root/mon-ai-agent.json requested=$1 line name path
  CONFIG_NAMES=(); CONFIG_PATHS=()
  [ -f "$config" ] || { [ -z "$requested" ] || die "Included repositories require a mon-ai-agent.json configuration file at the repository root."; return; }
  grep -q '"nestedRepositories"[[:space:]]*:' "$config" || die "mon-ai-agent.json must contain a nestedRepositories array."
  while IFS='|' read -r name path; do
    [ -n "$name" ] || continue
    repository_name "$name" "Nested repository name"
    path=$(safe_path "$path" "Nested repository path")
    for line in "${CONFIG_NAMES[@]:-}"; do [ "$line" != "$name" ] || die "mon-ai-agent.json contains a duplicate nested repository name: $name"; done
    for line in "${CONFIG_PATHS[@]:-}"; do [ "$line" != "$path" ] || die "mon-ai-agent.json contains a duplicate nested repository path: $path"; done
    CONFIG_NAMES+=("$name"); CONFIG_PATHS+=("$path")
  done < <(awk '
    /"nestedRepositories"[[:space:]]*:/ { inside=1 }
    inside && /"name"[[:space:]]*:/ { n=$0; sub(/^.*"name"[[:space:]]*:[[:space:]]*"/,"",n); sub(/"[[:space:]]*,?[[:space:]]*$/,"",n); name=n }
    inside && /"path"[[:space:]]*:/ { p=$0; sub(/^.*"path"[[:space:]]*:[[:space:]]*"/,"",p); sub(/"[[:space:]]*,?[[:space:]]*$/,"",p); if (name!="") { print name "|" p; name="" } }
    inside && /^[[:space:]]*\][[:space:]]*,?[[:space:]]*$/ { exit }
  ' "$config")
  [ -z "$requested" ] && return
  REQUESTED=()
  local item found i
  IFS=',' read -r -a items <<< "$requested"
  for item in "${items[@]}"; do
    item=$(safe_path "$item" "Included repository path")
    for path in "${REQUESTED[@]:-}"; do [ "$path" != "$item" ] || die "An included repository path was requested more than once: $item"; done
    found=0
    for i in "${!CONFIG_PATHS[@]}"; do
      [ "$(lower "${CONFIG_PATHS[$i]}")" = "$(lower "$item")" ] && { REQUESTED+=("$item"); found=1; break; }
    done
    [ "$found" -eq 1 ] || die "Included repository path is not configured in mon-ai-agent.json: $item"
  done
}

action= name= task_path= status= allow_dirty=0 requested=
while [ "$#" -gt 0 ]; do
  case $1 in
    -Action|--action) [ $# -ge 2 ] || die "$1 requires a value."; action=$2; shift 2;;
    -Name|--name) [ $# -ge 2 ] || die "$1 requires a value."; name=$2; shift 2;;
    -TaskPath|--task-path) [ $# -ge 2 ] || die "$1 requires a value."; task_path=$2; shift 2;;
    -Status|--status) [ $# -ge 2 ] || die "$1 requires a value."; status=$2; shift 2;;
    -IncludeRepository|--include-repository) [ $# -ge 2 ] || die "$1 requires a value."; requested=${requested:+$requested,}$2; shift 2;;
    -AllowDirty|--allow-dirty) allow_dirty=1; shift;;
    -h|--help) usage; exit 0;; *) usage; die "Unknown argument: $1";;
  esac
done
[ "$action" = create ] || [ "$action" = current ] || [ "$action" = set-status ] || { usage; die "-Action must be create, current, or set-status."; }

if [ "$action" = current ]; then
  [ -f "$current_file" ] || die "No current task is set. Run the script with -Action create first."
  relative=$(tr -d '\r\n' < "$current_file")
  [ -n "$relative" ] || die "The current task pointer is empty."
  task_path=$repo_root/${relative//\//\/}
  [ -f "$task_path" ] || die "The current task does not exist: $relative"
  printf '%s\n' "$task_path"; exit 0
fi

if [ "$action" = set-status ]; then
  [ -n "$task_path" ] || die "-TaskPath is required when -Action is set-status."
  [ "$status" = in-progress ] || [ "$status" = implemented ] || die "-Status must be in-progress or implemented."
  case $task_path in /*) resolved=$task_path;; *) resolved=$repo_root/$task_path;; esac
  resolved=$(cd "$(dirname "$resolved")" 2>/dev/null && printf '%s/%s' "$PWD" "$(basename "$resolved")") || die "The task file does not exist: $task_path"
  case $resolved in "$state_root"/*/task.md) ;; *) die "Task status can only be changed for a task.md file under .copilot.";; esac
  [ -f "$resolved" ] || die "The task file does not exist: $resolved"
  front=$(awk 'BEGIN{ok=0} NR==1&&$0=="---"{ok=1;next} ok&&$0=="---"{exit} ok{print}' "$resolved")
  count=$(printf '%s\n' "$front" | awk '$0 ~ /^status:[[:space:]]*(approved|in-progress|implemented)[[:space:]]*$/ {n++} END{print n+0}')
  [ "$count" -eq 1 ] || die "The task must contain exactly one valid status in its YAML frontmatter."
  current=$(printf '%s\n' "$front" | awk '$0 ~ /^status:/ {sub(/^status:[[:space:]]*/,""); sub(/[[:space:]]*$/,""); print; exit}')
  [ "$current" = "$status" ] && { printf '%s\n' "$resolved"; exit 0; }
  case "$current->$status" in "approved->in-progress"|"in-progress->implemented"|"implemented->in-progress") ;; *) die "Invalid task status transition: $current->$status";; esac
  tmp=$resolved.tmp
  awk -v s="$status" 'NR==1{in_fm=($0=="---")} in_fm&&$0 ~ /^status:[[:space:]]*(approved|in-progress|implemented)[[:space:]]*$/ {print "status: " s; next} in_fm&&NR>1&&$0=="---"{in_fm=0} {print}' "$resolved" > "$tmp"
  mv "$tmp" "$resolved"; printf '%s\n' "$resolved"; exit 0
fi

[ -n "$name" ] || die "-Name is required when -Action is create."
slug=$(printf '%s' "$name" | iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null | tr '[:upper:]' '[:lower:]' | sed -e 's/[^a-z0-9][^a-z0-9]*/-/g' -e 's/^-*//' -e 's/-*$//' | cut -c1-80 | sed 's/-*$//')
[ -n "$slug" ] || die "The task name must contain at least one letter or digit."
case $slug in con|prn|aux|nul|com[1-9]|lpt[1-9]) slug=task-$slug;; esac
parse_config "$requested"
root_commit=$(git -C "$repo_root" rev-parse HEAD)
root_dirty=0; dirty "$repo_root" && root_dirty=1
declare -a inc_names=() inc_paths=() inc_commits=()
for path in "${REQUESTED[@]:-}"; do
  full=$repo_root/$path; [ -d "$full" ] || die "Included repository directory does not exist: $path"
  top=$(git -C "$full" rev-parse --show-toplevel 2>/dev/null) || die "Included repository path is not a Git repository: $path"
  [ "$(cd "$top" && pwd -P)" = "$(cd "$full" && pwd -P)" ] || die "Included repository path must be the Git repository root: $path"
  dirty "$full" && root_dirty=1
  for i in "${!CONFIG_PATHS[@]}"; do [ "${CONFIG_PATHS[$i]}" = "$path" ] && inc_names+=("${CONFIG_NAMES[$i]}") && inc_paths+=("$path") && inc_commits+=("$(git -C "$full" rev-parse HEAD)"); done
done
[ "$root_dirty" -eq 0 ] || [ "$allow_dirty" -eq 1 ] || die "A selected repository working tree is not clean. Review existing changes, then rerun with -AllowDirty only after the developer accepts this baseline."
date_path=$state_root/$(date +%Y)/$(date +%m)/$(date +%d); mkdir -p "$date_path"
branch=$(git -C "$repo_root" branch --show-current); [ -n "$branch" ] || branch=DETACHED
task_dir=$date_path/$slug; suffix=2; while [ -e "$task_dir" ]; do task_dir=$date_path/$slug-$suffix; suffix=$((suffix+1)); done
mkdir -p "$task_dir/reviews"
title=$(printf '%s' "$name" | awk '{$1=$1; print}')
{
  printf '%s\n' '---' 'status: approved'
  printf "created-at: %s\nbranch: %s\nworking-tree-dirty: %s\nrepositories:\n" "$(yaml_quote "$(iso_now)")" "$(yaml_quote "$branch")" "$([ "$root_dirty" -eq 1 ] && printf true || printf false)"
  printf '%s\n' "$NBSP root:" "$NBSP$NBSP path: ." "$NBSP$NBSP base-commit: $(yaml_quote "$root_commit")"
  if [ "${#inc_paths[@]}" -eq 0 ]; then printf '%s\n' "$NBSP included: []"; else
    printf '%s\n' "$NBSP included:"
    for i in "${!inc_paths[@]}"; do printf '%s\n' "$NBSP$NBSP - name: $(yaml_quote "${inc_names[$i]}")" "$NBSP$NBSP$NBSP path: $(yaml_quote "${inc_paths[$i]}")" "$NBSP$NBSP$NBSP base-commit: $(yaml_quote "${inc_commits[$i]}")"; done
  fi
  cat <<EOF
---

# Task: $title

## Goal

## Verified Current Behavior

## Desired Behavior

## Scope

## Non-goals

## Design Decisions

## Acceptance Criteria

## Validation Plan

## Risks and Open Questions
EOF
} > "$task_dir/task.md"
mkdir -p "$state_root"
relative=${task_dir#"$repo_root"/}/task.md; printf '%s\n' "${relative//\\/\/}" > "$current_file"
printf '%s\n' "$task_dir/task.md"
