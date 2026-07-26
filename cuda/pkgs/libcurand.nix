{ buildRedist }:
buildRedist {
  redistName = "cuda";
  pname = "libcurand";

  outputs = [
    "out"
    "dev"
    "include"
    "lib"
    "static"
    "stubs"
  ];

  meta = {
    description = "CUDA Random Number Generation library";
    homepage = "https://developer.nvidia.com/curand";
  };
}
