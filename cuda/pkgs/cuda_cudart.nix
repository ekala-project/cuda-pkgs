{
  addDriverRunpath,
  buildRedist,
  cccl,
  cudaAtLeast,
  lib,
}:
buildRedist {
  redistName = "cuda";
  pname = "cuda_cudart";

  outputs = [
    "out"
  ];

  propagatedBuildInputs = [
    (lib.getOutput "include" cccl)
  ];

  allowFHSReferences = false;

  postPatch = ''
    local path=""
    while IFS= read -r -d $'\0' path; do
      nixLog "patching $path"
      sed -i \
        -e "s|^cudaroot\s*=.*\$||" \
        -e "s|^Libs\s*:\(.*\)\$|Libs: \1 -Wl,-rpath,${addDriverRunpath.driverLink}/lib|" \
        "$path"
    done < <(find -iname 'cudart-*.pc' -print0)
    unset -v path
  ''
  + ''
    local path=""
    while IFS= read -r -d $'\0' path; do
      nixLog "patching $path"
      sed -i \
        -e "s|^cudaroot\s*=.*\$||" \
        -e "s|^libdir\s*=.*/lib\$|libdir=''${!outputStubs:?}/lib/stubs|" \
        -e "s|^Libs\s*:\(.*\)\$|Libs: \1 -Wl,-rpath,${addDriverRunpath.driverLink}/lib|" \
        "$path"
    done < <(find -iname 'cuda-*.pc' -print0)
    unset -v path
  '';

  postInstall = ''
    pushd "''${!outputStubs:?}/lib/stubs" >/dev/null
    if [[ -f libcuda.so && ! -f libcuda.so.1 ]]; then
      nixLog "creating versioned symlink for libcuda.so stub"
      ln -srv libcuda.so libcuda.so.1
    fi
    popd >/dev/null
  '';

  meta.description = "CUDA Runtime";
}
