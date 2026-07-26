{ buildRedist }:
buildRedist {
  redistName = "cuda";
  pname = "cuda_cupti";

  # Doc output contains HTML with /usr/ references in search index
  allowFHSReferences = true;

  outputs = [
    "out"
    "dev"
    "include"
    "lib"
    "doc"
    "samples"
  ];

  meta = {
    description = "CUDA Profiling Tools Interface";
    homepage = "https://developer.nvidia.com/cuda-toolkit";
  };
}
