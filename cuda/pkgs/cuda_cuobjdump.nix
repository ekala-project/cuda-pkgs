{ buildRedist }:
buildRedist {
  redistName = "cuda";
  pname = "cuda_cuobjdump";

  outputs = [
    "out"
    "bin"
  ];

  meta = {
    description = "CUDA Object Dump Utility";
    homepage = "https://developer.nvidia.com/cuda-toolkit";
  };
}
