{ buildRedist }:
buildRedist {
  redistName = "cuda";
  pname = "cuda_cupti";

  outputs = [
    "out"
    "dev"
    "include"
    "lib"
    "doc"
    "samples"
  ];

  meta = {
    description = "CUDA Profiling Tools Interface";
    homepage = "https://developer.nvidia.com/cuda-toolkit";
  };
}
