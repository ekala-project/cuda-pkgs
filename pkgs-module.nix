{ lib, ... }:

let
  pkgsOverlay = import ./top-level.nix;

  # Overlay that adds cudaPackages scope to the top-level package set.
  # Each cudaPackages_X_Y is a full scope of CUDA packages for that toolkit version.
  cudaScopeOverlay = final: prev:
    let
      mkCudaPackages = selectedManifests: cudaVersion:
        import ./cuda/scope {
          cudaMajorMinorPatchVersion = cudaVersion;
          inherit (final) lib;
          pkgs = final;
          inherit selectedManifests;
        };
    in
    {
      cudaPackages_12_8 = mkCudaPackages {
        cuda = "12.8.1";
        cudnn = "8.9.7";
        cutensor = "2.3.1";
        tensorrt = "10.16.1";
      } "12.8.1";

      cudaPackages_13_3 = mkCudaPackages {
        cuda = "13.3.0";
        cudnn = "9.22.0";
        cutensor = "2.3.1";
        tensorrt = "10.16.1";
      } "13.3.0";

      # Default cudaPackages points to latest
      cudaPackages = final.cudaPackages_13_3;
    };
in
{
  overlays = {
    pkgs = [
      cudaScopeOverlay
      pkgsOverlay
    ];
  };
}
