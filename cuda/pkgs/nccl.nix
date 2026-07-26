# TODO: nccl requires a combined CUDA toolkit layout where nvcc can find cicc
# (nvvm/bin/cicc) relative to its own bin directory. This needs a cudatoolkit
# wrapper or symlink forest to work properly.
{
  backendStdenv,
  cccl,
  cuda_cudart,
  cuda_nvcc,
  cudaAtLeast,
  cudaNamePrefix,
  fetchFromGitHub,
  flags,
  lib,
  python3,
  removeReferencesTo,
  which,
}:
let
  inherit (lib)
    getBin
    getInclude
    getLib
    optionalString
    versionAtLeast
    versionOlder
    ;
in
backendStdenv.mkDerivation (finalAttrs: {
  __structuredAttrs = true;
  strictDeps = true;

  name = "${cudaNamePrefix}-${finalAttrs.pname}-${finalAttrs.version}";
  pname = "nccl";

  version =
    if cudaAtLeast "12.0" then
      "2.30.7-1"
    else
      "2.25.1-1";

  src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "nccl";
    tag = "v${finalAttrs.version}";
    hash = lib.getAttr finalAttrs.version {
      "2.30.7-1" = "sha256-fdiQZweX0jYfGroP0bL5Sfv3+DkCzVBZZLEbPv8aqq8=";
      "2.25.1-1" = "sha256-3snh0xdL9I5BYqdbqdl+noizJoI38mZRVOJChgEE1I8=";
    };
  };

  outputs = [
    "out"
    "dev"
    "static"
  ];

  nativeBuildInputs = [
    cuda_nvcc
    python3
    removeReferencesTo
    which
  ];

  buildInputs = [
    (getInclude cuda_nvcc)
    cccl
    cuda_cudart
  ];

  postPatch = ''
    patchShebangs ./src/device/generate.py
    patchShebangs ./src/device/symmetric/generate.py

    nixLog "patching $PWD/makefiles/common.mk to remove NVIDIA's ccbin declaration"
    substituteInPlace ./makefiles/common.mk \
      --replace-fail \
        '-ccbin $(CXX)' \
        ""
  ''
  + optionalString (versionAtLeast finalAttrs.version "2.30.7-1") ''
    nixLog "patching shebang in $PWD/src/misc/generate_git_version.py"
    patchShebangs ./src/misc/generate_git_version.py
  '';

  makeFlags = [
    "CXXSTD=-std=c++17"
    "CUDA_HOME=${getBin cuda_nvcc}"
    "CUDA_INC=${getInclude cuda_cudart}/include"
    "CUDA_LIB=${getLib cuda_cudart}/lib"
    "NVCC_GENCODE=${flags.gencodeString}"
    "PREFIX=$(out)"
  ];

  # CCCL headers are under include/cccl/ but consumers expect cuda/atomic etc.
  env.NIX_CFLAGS_COMPILE = toString [
    "-Wno-unused-function"
    "-isystem" "${lib.getOutput "include" cccl}/include/cccl"
  ];

  enableParallelBuilding = true;

  postFixup = ''
    moveToOutput lib/libnccl_static.a "$static"
  ''
  + ''
    remove-references-to -t "${getBin cuda_nvcc}" \
      ''${!outputLib}/lib/libnccl.so.* \
      ''${!outputStatic}/lib/*.a
  '';

  disallowedRequisites = [ (getBin cuda_nvcc) ];

  meta = {
    description = "Multi-GPU and multi-node collective communication primitives for NVIDIA GPUs";
    homepage = "https://developer.nvidia.com/nccl";
    license = lib.licenses.bsd3;
    platforms = [
      "aarch64-linux"
      "x86_64-linux"
    ];
    maintainers = [ ];
  };
})
