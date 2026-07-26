{ lib }:
let
  capabilities = import ./capabilities.nix { inherit lib; };
  nvccCompat = import ./nvcc-compat.nix;
  redistData = import ./redist.nix;
in
capabilities // nvccCompat // redistData // {
  allSortedCudaCapabilities = lib.sort lib.versionOlder (lib.attrNames capabilities.cudaCapabilityToInfo);
}
