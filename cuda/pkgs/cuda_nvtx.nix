{ buildRedist }:
buildRedist {
  redistName = "cuda";
  pname = "cuda_nvtx";

  outputs = [
    "out"
    "dev"
    "include"
    "lib"
  ];

  meta = {
    description = "NVIDIA Tools Extension Library";
    homepage = "https://developer.nvidia.com/cuda-toolkit";
  };
}
