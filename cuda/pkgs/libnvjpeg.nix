{ buildRedist }:
buildRedist {
  redistName = "cuda";
  pname = "libnvjpeg";

  outputs = [
    "out"
    "dev"
    "include"
    "lib"
    "static"
    "stubs"
  ];

  meta = {
    description = "NVIDIA JPEG Decoder Library";
    homepage = "https://developer.nvidia.com/nvjpeg";
  };
}
