{ buildRedist }:
buildRedist {
  redistName = "cuda";
  pname = "cuda_gdb";

  outputs = [
    "out"
    "bin"
    "lib"
  ];

  meta = {
    description = "CUDA GDB Debugger";
    homepage = "https://developer.nvidia.com/cuda-toolkit";
  };
}
