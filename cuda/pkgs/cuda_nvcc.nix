{
  buildRedist,
  lib,
  libnvvm,
  patchelf,
  stdenv,
}:
buildRedist {
  redistName = "cuda";
  pname = "cuda_nvcc";

  # nvcc and cicc are large binaries that get corrupted by patchelf operations
  # (both shrink-rpath and the set-interpreter/set-rpath from autoPatchelf).
  # We disable all automatic ELF patching and manually set interpreters.
  dontPatchELF = true;
  dontAutoPatchelf = true;

  # Headers contain preprocessor line markers referencing /usr/include
  allowFHSReferences = true;

  outputs = [
    "out"
    "dev"
    "bin"
    "include"
  ];

  # Move bundled nvvm into the bin output so nvcc can find cicc via TOP-relative
  # paths without cross-output references (which cause cycles).
  # For CUDA 13+, nvvm is a separate package and we patch nvcc.profile instead.
  postInstall = lib.optionalString (!(libnvvm.meta.available or false)) ''
    if [[ -d "$out/nvvm" ]]; then
      nixLog "moving bundled nvvm into bin output"
      mv "$out/nvvm" "''${!outputBin:?}/nvvm"
    fi
  '';

  # Manually set interpreter on all ELF binaries since we disabled autoPatchelf.
  postFixup = ''
    local interp="${stdenv.cc.libc}/lib/ld-linux-x86-64.so.2"
    if [[ -f "$interp" ]]; then
      local f
      for f in "''${!outputBin:?}"/bin/*; do
        [[ -f "$f" && -x "$f" ]] || continue
        [[ "$(head -c4 "$f" 2>/dev/null)" == $'\x7fELF' ]] || continue
        nixLog "setting interpreter on $(basename "$f")"
        ${lib.getExe patchelf} --set-interpreter "$interp" "$f"
      done
      # Handle cicc (in bin output for 12.x, or in libnvvm for 13.x)
      if [[ -f "''${!outputBin:?}/nvvm/bin/cicc" ]]; then
        nixLog "setting interpreter on bundled cicc"
        ${lib.getExe patchelf} --set-interpreter "$interp" "''${!outputBin:?}/nvvm/bin/cicc"
      fi
    fi
  ''
  + ''
    local binOut="''${!outputBin:?}"
  ''
  # In CUDA 13+, nvvm was split into a separate libnvvm package.
  + lib.optionalString (libnvvm.meta.available or false) ''
    if [[ -f "$binOut/bin/nvcc.profile" ]]; then
      nixLog "patching nvcc.profile to reference libnvvm"
      sed -i \
        -e "s|^CICC_PATH.*|CICC_PATH = ${libnvvm}/nvvm/bin|" \
        -e "s|^NVVMIR_LIBRARY_DIR.*|NVVMIR_LIBRARY_DIR = ${libnvvm}/nvvm/libdevice|" \
        "$binOut/bin/nvcc.profile"
    fi
    ln -sfn "${libnvvm}/nvvm" "$binOut/nvvm"
  '';

  meta = {
    description = "CUDA NVCC compiler";
    homepage = "https://developer.nvidia.com/cuda-toolkit";
  };
}
