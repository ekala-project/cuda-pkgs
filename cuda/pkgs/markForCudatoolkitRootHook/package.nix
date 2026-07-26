{
  lib,
  makeSetupHook,
}:
makeSetupHook {
  name = "mark-for-cudatoolkit-root-hook";
  meta = {
    license = lib.licenses.mit;
    maintainers = [ ];
  };
} ./hook.sh
