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

  # cuda-gdb bundles a python3.8 that we can't satisfy
  autoPatchelfIgnoreMissingDeps = [
    "libpython*"
  ];

  meta = {
    description = "CUDA GDB Debugger";
    homepage = "https://developer.nvidia.com/cuda-toolkit";
  };
}
