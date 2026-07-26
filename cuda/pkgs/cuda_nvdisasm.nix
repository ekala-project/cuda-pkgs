{ buildRedist }:
buildRedist {
  redistName = "cuda";
  pname = "cuda_nvdisasm";

  outputs = [
    "out"
    "bin"
  ];

  meta = {
    description = "CUDA Disassembler";
    homepage = "https://developer.nvidia.com/cuda-toolkit";
  };
}
