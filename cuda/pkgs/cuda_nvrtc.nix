{ buildRedist }:
buildRedist {
  redistName = "cuda";
  pname = "cuda_nvrtc";

  outputs = [
    "out"
    "dev"
    "include"
    "lib"
    "stubs"
  ];

  meta = {
    description = "CUDA Runtime Compilation Library";
    homepage = "https://developer.nvidia.com/cuda-toolkit";
  };
}
