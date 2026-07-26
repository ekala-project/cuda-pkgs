{ buildRedist }:
buildRedist {
  redistName = "cuda";
  pname = "libcufft";

  outputs = [
    "out"
    "dev"
    "include"
    "lib"
    "static"
    "stubs"
  ];

  meta = {
    description = "CUDA Fast Fourier Transform library";
    homepage = "https://developer.nvidia.com/cufft";
  };
}
