#!/usr/bin/env bash
# Evaluate every derivation in one or more scopes, one nix-instantiate per attribute
# (tryEval cannot catch missing-attribute errors), and summarize the failures.
#
# Usage: maintainers/eval-sweep.sh [-s SYSTEM]... [-j JOBS] [SCOPE...]
#   SCOPE defaults to every cudaPackages_* attribute; SYSTEM defaults to x86_64-linux
#   and aarch64-linux. Exits 1 if any attribute fails to evaluate; attributes that are
#   only unsupported on a platform (meta.platforms) are reported as skipped.
set -euo pipefail
cd "$(dirname "$0")/.."

systems=()
jobs=$(nproc)
while getopts "s:j:" opt; do
  case $opt in
    s) systems+=("$OPTARG") ;;
    j) jobs=$OPTARG ;;
    *) exit 2 ;;
  esac
done
shift $((OPTIND - 1))
[[ ${#systems[@]} -gt 0 ]] || systems=(x86_64-linux aarch64-linux)

config='{ allowUnfree = true; }'
scopes=("$@")
if [[ ${#scopes[@]} -eq 0 ]]; then
  mapfile -t scopes < <(nix-instantiate --eval --json -E \
    "builtins.filter (n: builtins.match \"cudaPackages_[0-9_]+\" n != null) (builtins.attrNames (import ./. { config = $config; }))" \
    | tr -d '[]"' | tr , '\n')
fi

out=$(mktemp -d)
trap 'rm -rf "$out"' EXIT

eval_one() {
  local system=$1 attr=$2 log
  if log=$(nix-instantiate --system "$system" --arg config "$config" -A "$attr" 2>&1 >/dev/null); then
    echo "OK   $system $attr"
  else
    local msg
    msg=$(grep -E '^ *error: .+' <<<"$log" | tail -1 | sed 's/^ *error: *//')
    # meta.platforms / unsupported-version markers are expected, not eval bugs.
    if [[ $msg == *"is not available on the requested hostPlatform"* ]]; then
      echo "SKIP $system $attr :: unsupported on this platform"
    else
      echo "FAIL $system $attr :: ${msg:0:160}"
    fi
  fi
}
export -f eval_one
export config

for system in "${systems[@]}"; do
  for scope in "${scopes[@]}"; do
    # Only attributes that are derivations (skip helpers like buildRedist, cudaAtLeast, ...).
    nix-instantiate --system "$system" --eval --json -E "
      let s = (import ./. { config = $config; }).$scope; in
      builtins.filter (n: (builtins.tryEval (s.\${n}.type or null == \"derivation\")).value or false)
        (builtins.attrNames s)" | tr -d '[]"' | tr , '\n' | sed "s/^/$system $scope./"
  done
done > "$out/attrs"

# shellcheck disable=SC2016 # expanded by the child bash, not here
xargs -P "$jobs" -L1 bash -c 'eval_one "$0" "$1"' < "$out/attrs" | sort -k2,3 > "$out/results"

[[ -n ${VERBOSE:-} ]] && grep '^SKIP' "$out/results"
grep '^FAIL' "$out/results" || true
ok=$(grep -c '^OK' "$out/results" || true)
skip=$(grep -c '^SKIP' "$out/results" || true)
fail=$(grep -c '^FAIL' "$out/results" || true)
echo "ok: $ok, unsupported (skipped): $skip, failed: $fail (set VERBOSE=1 to list skipped)"
[[ $fail -eq 0 ]]
