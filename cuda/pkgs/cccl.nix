{ buildRedist, manifests }:
buildRedist {
  redistName = "cuda";
  pname = "cccl";

  # NVIDIA renamed cuda_cccl to cccl in CUDA 13.3
  release = manifests.cuda.cccl or manifests.cuda.cuda_cccl or null;

  outputs = [
    "out"
    "dev"
    "include"
  ];

  meta = {
    description = "CXX Core Compute Libraries";
    homepage = "https://github.com/NVIDIA/cccl";
  };
}
