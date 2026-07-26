{ buildRedist }:
buildRedist {
  redistName = "cuda";
  pname = "libnvfatbin";

  outputs = [
    "out"
    "dev"
    "include"
    "lib"
    "static"
  ];

  meta = {
    description = "NVIDIA Fatbin Library";
    homepage = "https://developer.nvidia.com/cuda-toolkit";
  };
}
