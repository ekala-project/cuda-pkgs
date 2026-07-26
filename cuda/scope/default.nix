# Scope constructor for a single cudaPackages version.
# Takes a manifest selection and produces a complete package set.
{
  cudaMajorMinorPatchVersion,
  lib,
  pkgs,
  selectedManifests,
}:
let
  inherit (lib.customisation) callPackagesWith;
  inherit (lib.fixedPoints) composeManyExtensions extends;
  inherit (lib.strings) versionAtLeast versionOlder;
  inherit (lib.versions) major majorMinor;

  cudaMajorMinorVersion = majorMinor cudaMajorMinorPatchVersion;
  cudaMajorVersion = major cudaMajorMinorPatchVersion;

  db = import ../db { inherit lib; };
  cudaLib = import ../lib { inherit lib db; };
  allManifests = import ../manifests { inherit lib; };
  manifests = cudaLib.selectManifests allManifests selectedManifests;

  backendStdenv = import ../backend-stdenv {
    inherit
      cudaLib
      cudaMajorMinorVersion
      db
      lib
      pkgs
      ;
    inherit (pkgs) config stdenv stdenvAdapters;
  };

  cudaPackagesFixedPoint =
    finalCudaPackages:
    {
      inherit
        cudaMajorMinorPatchVersion
        cudaMajorMinorVersion
        cudaMajorVersion
        manifests
        cudaLib
        db
        ;

      inherit pkgs;

      callPackages = callPackagesWith (pkgs // finalCudaPackages);

      cudaNamePrefix = "cuda${cudaMajorMinorVersion}";

      cudaOlder = versionOlder cudaMajorMinorVersion;
      cudaAtLeast = versionAtLeast cudaMajorMinorVersion;

      inherit backendStdenv;

      buildRedist = import ../build-redist {
        inherit
          cudaLib
          cudaMajorMinorVersion
          cudaMajorVersion
          db
          lib
          manifests
          ;
        inherit (pkgs)
          addDriverRunpath
          autoPatchelfHook
          fetchurl
          stdenv
          ;
        inherit (finalCudaPackages)
          backendStdenv
          cudaNamePrefix
          markForCudatoolkitRootHook
          ;
      };

      flags =
        cudaLib.formatCapabilities {
          inherit (db) cudaCapabilityToInfo;
          inherit (finalCudaPackages.backendStdenv) cudaCapabilities cudaForwardCompat;
        }
        // {
          inherit (cudaLib) dropDots;
        };
    }
    // lib.packagesFromDirectoryRecursive {
      inherit (finalCudaPackages) callPackage;
      directory = ../pkgs;
    };

  cudaPackages = lib.makeScope pkgs.newScope (
    extends (composeManyExtensions [ ]) cudaPackagesFixedPoint
  );
in
cudaPackages
