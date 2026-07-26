{ buildRedist }:
buildRedist {
  redistName = "cuda";
  pname = "libnpp";

  outputs = [
    "out"
    "dev"
    "include"
    "lib"
    "static"
    "stubs"
  ];

  meta = {
    description = "NVIDIA Performance Primitives library";
    homepage = "https://developer.nvidia.com/npp";
  };
}
