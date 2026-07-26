{ buildRedist }:
buildRedist {
  redistName = "cutensor";
  pname = "libcutensor";

  outputs = [
    "out"
    "dev"
    "include"
    "lib"
    "static"
  ];

  meta = {
    description = "GPU-accelerated tensor linear algebra library";
    homepage = "https://developer.nvidia.com/cutensor";
  };
}
