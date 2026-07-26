{ buildRedist }:
buildRedist {
  redistName = "cuda";
  pname = "cuda_crt";

  # Headers contain references to /usr/include
  allowFHSReferences = true;

  outputs = [
    "out"
    "include"
  ];

  meta = {
    description = "CUDA CRT headers";
    homepage = "https://developer.nvidia.com/cuda-toolkit";
  };
}
