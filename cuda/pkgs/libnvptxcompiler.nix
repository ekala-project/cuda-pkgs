{ buildRedist }:
buildRedist {
  redistName = "cuda";
  pname = "libnvptxcompiler";

  outputs = [
    "out"
    "dev"
    "include"
    "static"
  ];

  meta = {
    description = "NVIDIA PTX Compiler Library";
    homepage = "https://developer.nvidia.com/cuda-toolkit";
  };
}
