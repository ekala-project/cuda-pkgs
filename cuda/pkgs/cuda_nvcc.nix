{
  buildRedist,
  lib,
  libnvvm,
}:
buildRedist {
  redistName = "cuda";
  pname = "cuda_nvcc";

  # In CUDA 12.x, cicc is bundled and large; patchelf shrink-rpath corrupts it.
  # In CUDA 13.x, cicc moved to libnvvm package.
  dontPatchELF = true;

  # Headers contain references to /usr/include/math.h
  allowFHSReferences = true;

  outputs = [
    "out"
    "dev"
    "bin"
    "include"
  ];

  # In CUDA 13+, nvvm was split into a separate libnvvm package.
  # In CUDA 12.x, nvvm is bundled inside cuda_nvcc and works out of the box.
  postInstall = lib.optionalString (libnvvm.meta.available or false) ''
    local binOut="''${!outputBin:?}"

    # Patch nvcc.profile to use absolute paths for cicc and libdevice
    if [[ -f "$binOut/bin/nvcc.profile" ]]; then
      nixLog "patching nvcc.profile to reference libnvvm"
      sed -i \
        -e "s|^CICC_PATH.*|CICC_PATH = ${libnvvm}/nvvm/bin|" \
        -e "s|^NVVMIR_LIBRARY_DIR.*|NVVMIR_LIBRARY_DIR = ${libnvvm}/nvvm/libdevice|" \
        "$binOut/bin/nvcc.profile"
    fi

    # Also create a nvvm symlink so tools using TOP-relative paths work
    ln -sfn "${libnvvm}/nvvm" "$binOut/nvvm"
  '';

  meta = {
    description = "CUDA NVCC compiler";
    homepage = "https://developer.nvidia.com/cuda-toolkit";
  };
}
