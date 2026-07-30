{
  buildRedist,
  gmp,
  expat,
  ncurses,
}:
buildRedist {
  redistName = "cuda";
  pname = "cuda_gdb";

  allowFHSReferences = true;

  outputs = [
    "out"
    "bin"
  ];

  buildInputs = [
    gmp
    expat
    ncurses
  ];

  # cuda-gdb bundles python3.8 and may link libcrypt from older glibc
  autoPatchelfIgnoreMissingDeps = [
    "libpython*"
    "libcrypt*"
  ];

  meta = {
    description = "CUDA GDB Debugger";
    homepage = "https://developer.nvidia.com/cuda-toolkit";
  };
}
