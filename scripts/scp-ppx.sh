#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: mise run scp -- <repo-relative-path>" >&2
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel)"
input_path="$1"

if [[ "$input_path" = /* ]]; then
  source_path="$input_path"
else
  source_path="$repo_root/$input_path"
fi

if [[ ! -e "$source_path" ]]; then
  echo "Error: path does not exist: $input_path" >&2
  exit 1
fi

source_path="$(readlink -f "$source_path")"

case "$source_path" in
  "$repo_root"/*) ;;
  "$repo_root") ;;
  *)
    echo "Error: path must be inside the repository: $input_path" >&2
    exit 1
    ;;
esac

if [[ "$source_path" == "$repo_root" ]]; then
  echo "Error: copying the repository root itself is not supported" >&2
  exit 1
fi

relative_path="${source_path#"$repo_root"/}"
remote_target="~/parallel-programming-exp/$relative_path"
remote_parent="\$HOME/parallel-programming-exp/$(dirname "$relative_path")"

ssh ppx "mkdir -p $remote_parent"

if [[ -d "$source_path" ]]; then
  scp -r "$source_path" "ppx:$remote_target"
else
  scp "$source_path" "ppx:$remote_target"
fi