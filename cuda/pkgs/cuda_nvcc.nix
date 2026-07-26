{ buildRedist }:
buildRedist {
  redistName = "cuda";
  pname = "cuda_nvcc";

  outputs = [
    "out"
    "dev"
    "bin"
    "include"
  ];

  meta = {
    description = "CUDA NVCC compiler";
    homepage = "https://developer.nvidia.com/cuda-toolkit";
  };
}
