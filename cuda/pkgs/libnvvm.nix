{
  buildRedist,
  lib,
  patchelf,
  stdenv,
}:
buildRedist {
  redistName = "cuda";
  pname = "libnvvm";

  # Non-standard layout: files under nvvm/{lib64,include,bin}/
  outputs = [
    "out"
  ];

  # cicc is a large (~93MB) statically-linked binary. autoPatchelf and
  # patchelf --shrink-rpath can corrupt it. We skip all automatic ELF
  # patching and manually set just the interpreter.
  dontPatchELF = true;
  dontAutoPatchelf = true;

  postFixup = ''
    local interp="${stdenv.cc.libc}/lib/ld-linux-x86-64.so.2"
    if [[ -f "$out/nvvm/bin/cicc" && -f "$interp" ]]; then
      nixLog "setting interpreter on cicc"
      ${lib.getExe patchelf} --set-interpreter "$interp" "$out/nvvm/bin/cicc"
    fi
  '';

  meta = {
    description = "NVIDIA Virtual Machine Library";
    homepage = "https://developer.nvidia.com/cuda-toolkit";
  };
}
