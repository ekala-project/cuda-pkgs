{ buildRedist }:
buildRedist {
  redistName = "cuda";
  pname = "cuda_nvml_dev";

  outputs = [
    "out"
    "dev"
    "include"
    "lib"
    "stubs"
  ];

  meta = {
    description = "NVIDIA Management Library (NVML) development files";
    homepage = "https://developer.nvidia.com/nvidia-management-library-nvml";
  };
}
