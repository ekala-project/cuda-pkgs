# shellcheck shell=bash

if [[ -n ${strictDeps:-} && ${hostOffset:-0} -ne -1 ]]; then
  nixLog "skipping sourcing build-redist-hook.bash (hostOffset=${hostOffset:-0}) (targetOffset=${targetOffset:-0})"
  return 0
fi
nixLog "sourcing build-redist-hook.bash (hostOffset=${hostOffset:-0}) (targetOffset=${targetOffset:-0})"

buildRedistHookRegistration() {
  postUnpackHooks+=(unpackCudaLibSubdir)
  nixLog "added unpackCudaLibSubdir to postUnpackHooks"

  postUnpackHooks+=(unpackCudaPkgConfigDirs)
  nixLog "added unpackCudaPkgConfigDirs to postUnpackHooks"

  prePatchHooks+=(patchCudaPkgConfig)
  nixLog "added patchCudaPkgConfig to prePatchHooks"

  if [[ -z ${allowFHSReferences-} ]]; then
    postInstallCheckHooks+=(checkCudaFhsRefs)
    nixLog "added checkCudaFhsRefs to postInstallCheckHooks"
  fi

  postInstallCheckHooks+=(checkCudaNonEmptyOutputs)
  nixLog "added checkCudaNonEmptyOutputs to postInstallCheckHooks"

  preFixupHooks+=(fixupPropagatedBuildOutputsForMultipleOutputs)
  nixLog "added fixupPropagatedBuildOutputsForMultipleOutputs to preFixupHooks"

  postFixupHooks+=(fixupCudaPropagatedBuildOutputsToOut)
  nixLog "added fixupCudaPropagatedBuildOutputsToOut to postFixupHooks"
}

buildRedistHookRegistration

unpackCudaLibSubdir() {
  local -r cudaLibDir="${NIX_BUILD_TOP:?}/${sourceRoot:?}/lib"
  local -r versionedCudaLibDir="$cudaLibDir/${cudaMajorVersion:?}"

  if [[ ! -d $versionedCudaLibDir ]]; then
    return 0
  fi

  nixLog "found versioned CUDA lib dir: $versionedCudaLibDir"

  mv --verbose --no-clobber "$versionedCudaLibDir" "${cudaLibDir}-new"
  rm --verbose --recursive "$cudaLibDir" || {
    nixErrorLog "could not delete $cudaLibDir: $(ls -laR "$cudaLibDir")"
    exit 1
  }
  mv --verbose --no-clobber "${cudaLibDir}-new" "$cudaLibDir"

  return 0
}

unpackCudaPkgConfigDirs() {
  local path
  local -r pkgConfigDir="${NIX_BUILD_TOP:?}/${sourceRoot:?}/share/pkgconfig"

  for path in "${NIX_BUILD_TOP:?}/${sourceRoot:?}"/{pkg-config,pkgconfig}; do
    [[ -d $path ]] || continue
    mkdir -p "$pkgConfigDir"
    mv --verbose --no-clobber --target-directory "$pkgConfigDir" "$path"/*
    rm --recursive --dir "$path" || {
      nixErrorLog "$path contains non-empty directories: $(ls -laR "$path")"
      exit 1
    }
  done

  return 0
}

patchCudaPkgConfig() {
  local pc

  for pc in "${NIX_BUILD_TOP:?}/${sourceRoot:?}"/share/pkgconfig/*.pc; do
    nixLog "patching $pc"
    sed -i \
      -e "s|^cudaroot\s*=.*\$|cudaroot=${!outputDev:?}|" \
      -e "s|^libdir\s*=.*/lib\$|libdir=${!outputLib:?}/lib|" \
      -e "s|^includedir\s*=.*/include\$|includedir=${!outputInclude:?}/include|" \
      "$pc"
  done

  for pc in "${NIX_BUILD_TOP:?}/${sourceRoot:?}"/share/pkgconfig/*-"${cudaMajorMinorVersion:?}.pc"; do
    nixLog "creating unversioned symlink for $pc"
    ln -s "$(basename "$pc")" "${pc%-"${cudaMajorMinorVersion:?}".pc}".pc
  done

  return 0
}

checkCudaFhsRefs() {
  nixLog "checking for FHS references..."
  local -a outputPaths=()
  local firstMatches

  mapfile -t outputPaths < <(for outputName in $(getAllOutputNames); do echo "${!outputName:?}"; done)
  firstMatches="$(grep --max-count=5 --recursive --exclude=LICENSE /usr/ "${outputPaths[@]}")" || true
  if [[ -n $firstMatches ]]; then
    nixErrorLog "detected references to /usr: $firstMatches"
    exit 1
  fi

  return 0
}

checkCudaNonEmptyOutputs() {
  local outputName
  local dirs
  local -a failingOutputNames=()

  for outputName in $(getAllOutputNames); do
    [[ ${outputName:?} == "out" || ${outputName:?} == "${outputDev:?}" ]] && continue
    dirs="$(find "${!outputName:?}" -mindepth 1 -maxdepth 1)" || true
    if [[ -z $dirs || $dirs == "${!outputName:?}/nix-support" ]]; then
      failingOutputNames+=("${outputName:?}")
    fi
  done

  if ((${#failingOutputNames[@]})); then
    nixErrorLog "detected empty (excluding nix-support) outputs: ${failingOutputNames[*]}"
    nixErrorLog "this typically indicates a failure in packaging or moveToOutput ordering"
    exit 1
  fi

  return 0
}

# Convert propagatedBuildOutputs array to space-separated string for _multioutPropagateDev
fixupPropagatedBuildOutputsForMultipleOutputs() {
  nixLog "converting propagatedBuildOutputs to a space-separated string"
  # shellcheck disable=SC2124
  export propagatedBuildOutputs="${propagatedBuildOutputs[@]}"
  return 0
}

# Propagate build outputs to out so string interpolation works
fixupCudaPropagatedBuildOutputsToOut() {
  local output

  mkdir -p "${out:?}/nix-support"

  for output in $propagatedBuildOutputs; do
    nixLog "adding ${!output:?} to propagatedBuildInputs of ${out:?}"
    printWords "${!output:?}" >>"${out:?}/nix-support/propagated-build-inputs"
  done

  return 0
}
