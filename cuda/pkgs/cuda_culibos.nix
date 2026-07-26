{ buildRedist }:
buildRedist {
  redistName = "cuda";
  pname = "cuda_culibos";

  outputs = [
    "out"
    "static"
  ];

  meta = {
    description = "CUDA OS-independent library";
    homepage = "https://developer.nvidia.com/cuda-toolkit";
  };
}
