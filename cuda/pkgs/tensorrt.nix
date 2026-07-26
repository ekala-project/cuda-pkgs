{ buildRedist }:
buildRedist {
  redistName = "tensorrt";
  pname = "tensorrt";

  allowFHSReferences = true;

  outputs = [
    "out"
    "dev"
    "bin"
    "include"
    "lib"
    "static"
  ];

  # Remove broken symlinks left by multi-output splitting
  preFixup = ''
    find "$out" -xtype l -delete 2>/dev/null || true
  '';

  meta = {
    description = "High-performance deep learning inference optimizer and runtime";
    homepage = "https://developer.nvidia.com/tensorrt";
  };
}
