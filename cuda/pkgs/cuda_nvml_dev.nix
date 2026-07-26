{ buildRedist }:
buildRedist {
  redistName = "cuda";
  pname = "cuda_nvml_dev";

  # Contains example Makefiles with /usr/ paths
  allowFHSReferences = true;

  outputs = [
    "out"
    "dev"
    "include"
    "stubs"
  ];

  meta = {
    description = "NVIDIA Management Library (NVML) development files";
    homepage = "https://developer.nvidia.com/nvidia-management-library-nvml";
  };
}
