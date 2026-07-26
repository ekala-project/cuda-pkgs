{ buildRedist }:
buildRedist {
  redistName = "cuda";
  pname = "libnvjitlink";

  outputs = [
    "out"
    "dev"
    "include"
    "lib"
    "stubs"
  ];

  meta = {
    description = "NVIDIA JIT Linker Library";
    homepage = "https://developer.nvidia.com/cuda-toolkit";
  };
}
