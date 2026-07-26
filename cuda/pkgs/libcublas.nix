{ buildRedist }:
buildRedist {
  redistName = "cuda";
  pname = "libcublas";

  outputs = [
    "out"
    "dev"
    "include"
    "lib"
    "static"
    "stubs"
  ];

  meta = {
    description = "CUDA Basic Linear Algebra Subroutine library";
    homepage = "https://developer.nvidia.com/cublas";
  };
}
