{ buildRedist }:
buildRedist {
  redistName = "cuda";
  pname = "libnvvm";

  # Non-standard layout: files under nvvm/{lib64,include,bin}/
  outputs = [
    "out"
  ];

  meta = {
    description = "NVIDIA Virtual Machine Library";
    homepage = "https://developer.nvidia.com/cuda-toolkit";
  };
}
