{ buildRedist }:
buildRedist {
  redistName = "tensorrt";
  pname = "tensorrt";

  outputs = [
    "out"
    "dev"
    "include"
    "lib"
    "static"
  ];

  meta = {
    description = "High-performance deep learning inference optimizer and runtime";
    homepage = "https://developer.nvidia.com/tensorrt";
  };
}
