{ buildRedist }:
buildRedist {
  redistName = "cuda";
  pname = "cuda_profiler_api";

  outputs = [
    "out"
    "dev"
    "include"
  ];

  meta = {
    description = "CUDA Profiler API";
    homepage = "https://developer.nvidia.com/cuda-toolkit";
  };
}
