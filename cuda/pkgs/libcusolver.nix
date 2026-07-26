{
  buildRedist,
  lib,
  libcublas,
  libcusparse,
  libnvjitlink,
}:
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

  buildInputs = [
    (lib.getLib libcublas)
    (lib.getLib libcusparse)
    (lib.getLib libnvjitlink)
  ];

  meta = {
    description = "CUDA Direct Solver library";
    homepage = "https://developer.nvidia.com/cusolver";
  };
}
