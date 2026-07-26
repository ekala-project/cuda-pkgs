{ buildRedist }:
buildRedist {
  redistName = "cuda";
  pname = "cuda_sanitizer_api";

  outputs = [
    "out"
    "bin"
    "include"
    "lib"
  ];

  meta = {
    description = "CUDA Compute Sanitizer API";
    homepage = "https://developer.nvidia.com/cuda-toolkit";
  };
}
