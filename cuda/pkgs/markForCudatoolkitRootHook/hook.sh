# shellcheck shell=bash

((${hostOffset:?} == -1 && ${targetOffset:?} == 0)) || return 0

echo "Sourcing mark-for-cudatoolkit-root-hook" >&2

markForCUDAToolkit_ROOT() {
  mkdir -p "${prefix:?}/nix-support"
  local markerPath="$prefix/nix-support/include-in-cudatoolkit-root"

  [[ -f $markerPath ]] && return 0

  touch "$markerPath"

  [[ -n ${strictDeps-} ]] && return 0

  echo "${pname:?}-${output:?}" >"$markerPath"
}

fixupOutputHooks+=(markForCUDAToolkit_ROOT)
