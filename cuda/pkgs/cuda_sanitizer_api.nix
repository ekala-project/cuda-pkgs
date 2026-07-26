{ buildRedist }:
buildRedist {
  redistName = "cuda";
  pname = "cuda_sanitizer_api";

  # Contains docs with /usr/local/cuda references
  allowFHSReferences = true;

  outputs = [
    "out"
  ];

  meta = {
    description = "CUDA Compute Sanitizer API";
    homepage = "https://developer.nvidia.com/cuda-toolkit";
  };
}
