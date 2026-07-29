{
  buildRedist,
  lib,
  libnvvm,
}:
buildRedist {
  redistName = "cuda";
  pname = "cuda_nvcc";

  outputs = [
    "out"
    "dev"
    "bin"
    "include"
  ];

  # nvcc expects cicc and libdevice relative to its bin directory via nvcc.profile.
  # Patch the profile to point to the actual libnvvm store path, and symlink nvvm/
  # into the bin output so the default TOP-relative paths also work.
  postInstall = ''
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
