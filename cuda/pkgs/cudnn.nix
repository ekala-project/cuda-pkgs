{
  buildRedist,
  cuda_nvrtc,
  lib,
  libcublas,
  patchelf,
  zlib,
}:
buildRedist (
  finalAttrs:
  let
    cudnnAtLeast = lib.versionAtLeast finalAttrs.version;
    cudnnOlder = lib.versionOlder finalAttrs.version;
  in
  {
    redistName = "cudnn";
    pname = "cudnn";

    outputs = [
      "out"
      "dev"
      "include"
      "lib"
      "static"
    ];

    buildInputs = [
      (lib.getLib libcublas)
      zlib
    ];

    postFixup = lib.optionalString (cudnnAtLeast "8" && cudnnOlder "9") ''
      ${lib.getExe patchelf} ''${!outputLib:?}/lib/libcudnn.so --add-needed libcudnn_cnn_infer.so
      ${lib.getExe patchelf} ''${!outputLib:?}/lib/libcudnn_ops_infer.so --add-needed libcublas.so --add-needed libcublasLt.so
    '';

    appendRunpaths = [
      "${lib.getLib cuda_nvrtc}/lib"
    ];

    meta = {
      description = "GPU-accelerated library of primitives for deep neural networks";
      homepage = "https://developer.nvidia.com/cudnn";
      maintainers = [ ];
    };
  }
)
