#!/usr/bin/env bash
set -euo pipefail

die() { printf 'Error: %s\n' "$1" >&2; exit 1; }
case " ${*:-} " in *" -h "*|*" --help "*) printf '%s\n' "Usage: $0 -Action {compare|capture} -TaskPath PATH [-ReviewNumber N]"; exit 0;; esac
repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || die "This script must run inside a Git repository."
state_root=$repo_root/.copilot
task_path= action= review_number=
while [ "$#" -gt 0 ]; do
  case $1 in
    -Action|--action) [ $# -ge 2 ] || die "$1 requires a value."; action=$2; shift 2;;
    -TaskPath|--task-path) [ $# -ge 2 ] || die "$1 requires a value."; task_path=$2; shift 2;;
    -ReviewNumber|--review-number) [ $# -ge 2 ] || die "$1 requires a value."; review_number=$2; shift 2;;
    -h|--help) printf '%s\n' "Usage: $0 -Action {compare|capture} -TaskPath PATH [-ReviewNumber N]"; exit 0;;
    *) die "Unknown argument: $1";;
  esac
done
[ "$action" = compare ] || [ "$action" = capture ] || die "-Action must be compare or capture."
[ -n "$task_path" ] || die "-TaskPath is required."
case $task_path in /*) resolved=$task_path;; *) resolved=$repo_root/$task_path;; esac
resolved=$(cd "$(dirname "$resolved")" 2>/dev/null && printf '%s/%s' "$PWD" "$(basename "$resolved")") || die "The task file does not exist: $task_path"
case $resolved in "$state_root"/*/task.md) ;; *) die "-TaskPath must point to a task.md file under .copilot.";; esac
[ -f "$resolved" ] || die "The task file does not exist: $resolved"
task_dir=$(dirname "$resolved"); state_file=$task_dir/review-state.json
NBSP=$(printf '\302\240')

valid_path() {
  local v=$1 s oldifs
  [ -n "$v" ] && [ "$v" = "${v# }" ] && [ "$v" = "${v% }" ] || return 1
  case $v in /*|[A-Za-z]:*|*\\*) return 1;; esac
  oldifs=$IFS; IFS=/; for s in $v; do [ -n "$s" ] && [ "$s" != . ] && [ "$s" != .. ] || { IFS=$oldifs; return 1; }; case $s in *[[:space:]]*|*[\<\>:\"\|\?\*]*) IFS=$oldifs; return 1;; esac; done; IFS=$oldifs
}
valid_name() { [ -n "$1" ] && [ "$1" = "${1# }" ] && [ "$1" = "${1% }" ] && case $1 in *[\\/:\*\?\"\<\>\|]*) return 1;; esac; }
yaml_value() {
  local line=$1 prefix=$2 value
  case $line in "$prefix"*) value=${line#"$prefix"};; *) return 1;; esac
  case $value in \'*\') value=${value#\'}; value=${value%\'}; printf '%s' "${value//\'\'/\'}";; *) [[ $value =~ ^[A-Za-z0-9._-]+$ ]] || return 1; printf '%s' "$value";; esac
}
parse_metadata() {
  local front line root found=0 included=0 name path commit
  front=$(awk 'BEGIN{ok=0} NR==1&&$0=="---"{ok=1;next} ok&&$0=="---"{exit} ok{print}' "$resolved")
  [ "$(printf '%s\n' "$front" | awk '$0=="repositories:"{n++} END{print n+0}')" -eq 1 ] || die "The task must contain exactly one repositories metadata block."
  root=$(printf '%s\n' "$front" | awk -v n="$NBSP" '$0==n" root:"{r=1;next} r&&$0==n n" path: ."{p=1;next} p&&$0 ~ /^/ {print;exit}')
  # The previous awk expression intentionally finds the root commit line without parsing arbitrary YAML.
  root=$(printf '%s\n' "$front" | awk -v n="$NBSP" '$0==n" root:"{r=1;next} r&&$0 ~ ("^" n n " base-commit: "){print substr($0, index($0,"base-commit: ")+13);exit}')
  case $root in \'*\') ROOT_COMMIT=${root#\'}; ROOT_COMMIT=${ROOT_COMMIT%\'};; *) ROOT_COMMIT=$root;; esac
  [[ $ROOT_COMMIT =~ ^[0-9a-fA-F]{40,64}$ ]] || die "The task metadata contains an invalid root base commit."
  INC_NAMES=(); INC_PATHS=(); INC_COMMITS=()
  while IFS='|' read -r name path commit; do
    [ -n "$name" ] || continue
    valid_name "$name" || die "Task metadata contains an invalid included repository name."
    valid_path "$path" || die "Task metadata contains an unsafe included repository path."
    [[ $commit =~ ^[0-9a-fA-F]{40,64}$ ]] || die "Task metadata contains an invalid base commit."
    for line in "${INC_NAMES[@]:-}"; do [ "$line" != "$name" ] || die "The task metadata contains duplicate included repository names or paths."; done
    for line in "${INC_PATHS[@]:-}"; do [ "$line" != "$path" ] || die "The task metadata contains duplicate included repository names or paths."; done
    INC_NAMES+=("$name"); INC_PATHS+=("$path"); INC_COMMITS+=("$commit")
  done < <(printf '%s\n' "$front" | awk -v n="$NBSP" '
    $0==n" included:" {on=1;next} on && $0 ~ n n" - name: " {name=$0; sub("^" n n" - name: ","",name); next} on && $0 ~ n n n" path: " {path=$0; sub("^" n n n" path: ","",path); next} on && $0 ~ n n n" base-commit: " {commit=$0; sub("^" n n n" base-commit: ","",commit); print name "|" path "|" commit; name=path=commit=""}
  ' | while IFS='|' read -r n p c; do
    case $n in "'"*"'") n=${n#\'}; n=${n%\'}; n=${n//\'\'/\'};; esac
    case $p in "'"*"'") p=${p#\'}; p=${p%\'}; p=${p//\'\'/\'};; esac
    case $c in "'"*"'") c=${c#\'}; c=${c%\'};; esac
    printf '%s|%s|%s\n' "$n" "$p" "$c"
  done)
  if printf '%s\n' "$front" | grep -Fqx "$NBSP included: []"; then [ "${#INC_PATHS[@]}" -eq 0 ] || die "The task metadata contains invalid included repository metadata."; fi
}
sha256() { if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}'; else shasum -a 256 "$1" | awk '{print $1}'; fi; }
changed_paths() { git -C "$1" cat-file -e "$2^{commit}" || die "The task metadata contains an invalid base commit."; { git -C "$1" diff --name-only --no-renames --diff-filter=ACDMRTUXB "$2" --; git -C "$1" ls-files --others --exclude-standard; } | awk 'NF' | sort -u; }
path_state() {
  local root=$1 rel=$2 display=$3 full=$1/$2 head dirty_text hash
  if [ ! -e "$full" ]; then printf '{"path":"%s","state":"deleted","sha256":null}' "$display"; return; fi
  if [ -d "$full" ]; then
    head=$(git -C "$full" rev-parse HEAD); dirty_text=$(git -C "$full" status --porcelain=v1 --untracked-files=all)
    hash=$(printf '%s\n%s' "$head" "$dirty_text" | sha256sum 2>/dev/null | awk '{print $1}')
    [ -n "$hash" ] || hash=$(printf '%s\n%s' "$head" "$dirty_text" | shasum -a 256 | awk '{print $1}')
    printf '{"path":"%s","state":"directory","sha256":"%s"}' "$display" "$hash"
  else printf '{"path":"%s","state":"file","sha256":"%s"}' "$display" "$(sha256 "$full")"; fi
}
get_files() {
  FILE_LINES=()
  while IFS= read -r path; do [ -n "$path" ] && FILE_LINES+=("$(path_state "$repo_root" "$path" "$path")"); done < <(changed_paths "$repo_root" "$ROOT_COMMIT")
  for i in "${!INC_PATHS[@]}"; do
    full=$repo_root/${INC_PATHS[$i]}; top=$(git -C "$full" rev-parse --show-toplevel 2>/dev/null) || die "Included repository path is not a Git repository: ${INC_PATHS[$i]}"
    [ "$(cd "$top" && pwd -P)" = "$(cd "$full" && pwd -P)" ] || die "Included repository path must be the Git repository root: ${INC_PATHS[$i]}"
    while IFS= read -r path; do [ -n "$path" ] && FILE_LINES+=("$(path_state "$full" "$path" "${INC_PATHS[$i]}/$path")"); done < <(changed_paths "$full" "${INC_COMMITS[$i]}")
  done
  sorted=$(printf '%s\n' "${FILE_LINES[@]:-}" | sort -t'"' -k4,4 -u)
  FILE_LINES=()
  while IFS= read -r line; do
    [ -n "$line" ] && FILE_LINES+=("$line")
  done <<< "$sorted"
}
parse_metadata; get_files
if [ "$action" = compare ]; then
  [ -f "$state_file" ] || { printf '%s\n' FIRST_REVIEW; for line in "${FILE_LINES[@]:-}"; do printf 'CHANGED %s\n' "$(printf '%s' "$line" | awk -F'"path":"' '{print $2}' | cut -d'"' -f1)"; done; exit 0; }
  version=$(awk -F: '/"version"/{gsub(/[ ,]/,"",$2);print $2;exit}' "$state_file"); [ "$version" = 2 ] || die "Unsupported or malformed review-state.json."
  state_repos=$(awk '/"repositories"/{on=1;next} on&&/\]/{exit} on&&/"path"/{print}' "$state_file")
  printf '%s\n' "$state_repos" | grep -Fq "\"baseCommit\":\"$ROOT_COMMIT\"" || die "Task repository metadata changed after the last completed review."
  [ "$(printf '%s\n' "$state_repos" | grep -Fc '"path":"."')" -eq 1 ] || die "Task repository metadata changed after the last completed review."
  for i in "${!INC_PATHS[@]}"; do
    printf '%s\n' "$state_repos" | grep -Fq "\"path\":\"${INC_PATHS[$i]}\",\"baseCommit\":\"${INC_COMMITS[$i]}\"" || die "Task repository metadata changed after the last completed review."
  done
  [ "$(printf '%s\n' "$state_repos" | grep -Fc '"path"')" -eq $((1 + ${#INC_PATHS[@]})) ] || die "Task repository metadata changed after the last completed review."
  baseline=$(awk -F: '/"lastCompletedReview"/{gsub(/[ ,]/,"",$2);print $2;exit}' "$state_file"); printf 'BASELINE_REVIEW %s\n' "$baseline"
  old=$(awk '/"files"/{on=1;next} on&&/^  \]/{exit} on&&/"path"/{print}' "$state_file")
  differences=0
  for line in "${FILE_LINES[@]:-}"; do path=$(printf '%s' "$line" | awk -F'"path":"' '{print $2}' | cut -d'"' -f1); printf '%s\n' "$old" | grep -Fq "\"path\":\"$path\"" || { printf 'ADDED_TO_DIFF %s\n' "$path"; differences=$((differences+1)); }; done
  while IFS= read -r line; do [ -n "$line" ] || continue; path=$(printf '%s' "$line" | awk -F'"path":"' '{print $2}' | cut -d'"' -f1); printf '%s\n' "${FILE_LINES[@]:-}" | grep -Fq "\"path\":\"$path\"" || { printf 'REMOVED_FROM_DIFF %s\n' "$path"; differences=$((differences+1)); }; done <<EOF
$old
EOF
  [ "$differences" -gt 0 ] || printf '%s\n' NO_CHANGES; exit 0
fi
[ "$review_number" -ge 1 ] 2>/dev/null && [ "$review_number" -le 999999 ] || die "-ReviewNumber is required when -Action is capture."
relative=${resolved#"$repo_root"/}; tmp=$state_file.tmp
{
  printf '{\n  "version": 2,\n  "lastCompletedReview": %s,\n  "capturedAt": "%s",\n  "task": "%s",\n  "repositories": [\n    {"path":".","baseCommit":"%s"}' "$review_number" "$(date -u +%Y-%m-%dT%H:%M:%S%z)" "$relative" "$ROOT_COMMIT"
  for i in "${!INC_PATHS[@]}"; do printf ',\n    {"path":"%s","baseCommit":"%s"}' "${INC_PATHS[$i]}" "${INC_COMMITS[$i]}"; done
  printf '\n  ],\n  "files": [\n'
  for i in "${!FILE_LINES[@]}"; do [ "$i" -gt 0 ] && printf ',\n'; printf '    %s' "${FILE_LINES[$i]}"; done
  printf '\n  ]\n}\n'
} > "$tmp"; mv "$tmp" "$state_file"; printf '%s\n' "$state_file"
