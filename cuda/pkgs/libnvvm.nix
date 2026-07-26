{ buildRedist }:
buildRedist {
  redistName = "cuda";
  pname = "libnvvm";

  outputs = [
    "out"
    "dev"
    "include"
    "lib"
  ];

  meta = {
    description = "NVIDIA Virtual Machine Library";
    homepage = "https://developer.nvidia.com/cuda-toolkit";
  };
}
