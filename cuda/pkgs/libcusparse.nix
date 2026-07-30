{
  buildRedist,
  lib,
  libnvjitlink,
}:
buildRedist {
  redistName = "cuda";
  pname = "libcusparse";

  outputs = [
    "out"
    "dev"
    "include"
    "lib"
    "static"
    "stubs"
  ];

  buildInputs = [
    (lib.getLib libnvjitlink)
  ];

  meta = {
    description = "CUDA Sparse Matrix library";
    homepage = "https://developer.nvidia.com/cusparse";
  };
}
