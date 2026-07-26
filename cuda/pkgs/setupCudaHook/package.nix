{
  lib,
  makeSetupHook,
  backendStdenv,
}:
makeSetupHook {
  name = "setup-cuda-hook";

  substitutions.setupCudaHook = placeholder "out";

  substitutions.ccFullPath = "${backendStdenv.cc}/bin/${backendStdenv.cc.targetPrefix}c++";

  meta = {
    license = lib.licenses.mit;
    maintainers = [ ];
  };
} ./setup-cuda-hook.sh
