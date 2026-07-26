{ buildRedist }:
buildRedist {
  redistName = "cuda";
  pname = "libcusolver";

  outputs = [
    "out"
    "dev"
    "include"
    "lib"
    "static"
    "stubs"
  ];

  meta = {
    description = "CUDA Direct Solver library";
    homepage = "https://developer.nvidia.com/cusolver";
  };
}
