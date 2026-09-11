{ lib, ... }:

let
  pkgsOverlay = import ./top-level.nix;

  # Overlay that adds jetpack scopes, analogous to cudaScopeOverlay.
  # Produces jetpack.v5, jetpack.v6, jetpack.v7 and convenience aliases.
  jetpackScopeOverlay = final: prev:
    let
      versions = import ./jetpack/db/versions.nix;

      mkJetpack =
        versionInfo:
        import ./jetpack/scope {
          inherit (versionInfo)
            jetpackVersion
            l4tVersion
            cudaVersion
            cudaDriverVersion
            bspHash
            ;
          inherit (final) lib;
          pkgs = final;
        };
    in
    {
      jetpack = {
        v5 = mkJetpack versions.v5;
        v6 = mkJetpack versions.v6;
        v7 = mkJetpack versions.v7;
      };

      # Convenience aliases
      jetpackPackages_5 = final.jetpack.v5;
      jetpackPackages_6 = final.jetpack.v6;
      jetpackPackages_7 = final.jetpack.v7;
      jetpackPackages = final.jetpack.v7;
    };

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
      cudaPackages_11_4 = mkCudaPackages {
        cuda = "11.4.4";
        cudnn = "8.6.0";
        cutensor = "1.6.2";
      } "11.4.4";

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
      jetpackScopeOverlay
      pkgsOverlay
    ];
  };
}
