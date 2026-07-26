{ buildRedist }:
buildRedist {
  redistName = "cuda";
  pname = "cuda_opencl";

  outputs = [
    "out"
    "dev"
    "include"
    "lib"
  ];

  meta = {
    description = "CUDA OpenCL Support";
    homepage = "https://developer.nvidia.com/cuda-toolkit";
  };
}
