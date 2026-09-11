# Scope constructor for a single JetPack version.
# Takes version parameters and produces a complete jetpack package set.
{
  jetpackVersion,
  l4tVersion,
  cudaVersion,
  cudaDriverVersion,
  bspHash,
  lib,
  pkgs,
}:
let
  inherit (lib.customisation) callPackagesWith;
  inherit (lib.fixedPoints) composeManyExtensions extends;
  inherit (lib.strings) versionAtLeast versionOlder;
  inherit (lib.versions) major majorMinor;

  l4tMajorMinorPatchVersion = l4tVersion;
  cudaMajorMinorPatchVersion = cudaVersion;
  cudaMajorMinorVersion = majorMinor cudaMajorMinorPatchVersion;
  l4tMajorVersion = major l4tMajorMinorPatchVersion;

  l4tAtLeast = versionAtLeast l4tMajorMinorPatchVersion;
  l4tOlder = versionOlder l4tMajorMinorPatchVersion;

  sourceInfo = import ../sourceinfo {
    inherit l4tMajorMinorPatchVersion;
    inherit (pkgs) fetchurl fetchgit;
    inherit lib;
  };

  jetpackFixedPoint =
    finalJetpack:
    {
      inherit
        jetpackVersion
        l4tMajorMinorPatchVersion
        cudaMajorMinorVersion
        cudaMajorMinorPatchVersion
        cudaDriverVersion
        l4tAtLeast
        l4tOlder
        ;

      # Alias used by L4T packages (e.g. l4t-cuda.nix)
      cudaDriverMajorMinorVersion = cudaDriverVersion;

      inherit (sourceInfo) debs gitRepos;

      inherit pkgs;

      callPackages = callPackagesWith (pkgs // finalJetpack);

      # GPU driver for JP5, JP6, and Orin JP7.
      gpuDriver = "nvgpu";

      # For JetPack 5 and 6, the t194 and t234 packages are currently
      # identical, so we just use t234. For JP7 (L4T >= 38), use "som".
      defaultSomDebRepo = if l4tAtLeast "38" then "som" else "t234";

      bspSrc = import ../bsp {
        inherit
          l4tMajorMinorPatchVersion
          bspHash
          lib
          ;
        inherit (pkgs) applyPatches buildPackages fetchurl;
      };

      buildFromDebs = finalJetpack.callPackage ../build-from-debs { };

      normalizeDebs = finalJetpack.callPackage ../build-from-debs/normalize-debs.nix { };

      # Reference the appropriate cudaPackages from pkgs for CUDA integration.
      cudaPackages = pkgs.cudaPackages or { };

      markForCudatoolkitRootHook =
        pkgs.cudaPackages.markForCudatoolkitRootHook or null;

      # Flash tools
      flash-tools = finalJetpack.callPackage ../pkgs/flash-tools { };

      # Board automation utilities
      board-automation = finalJetpack.callPackage ../pkgs/board-automation { };

      # Xavier AGX automation
      python-jetson = pkgs.python3Packages.callPackage ../pkgs/python-jetson { };

      # EEPROM tool
      tegra-eeprom-tool = pkgs.callPackage ../pkgs/tegra-eeprom-tool { };

      # GPT and firmware patching
      patchgpt = finalJetpack.callPackage ../pkgs/patchgpt { };
      patchfv = finalJetpack.callPackage ../pkgs/patchfv { };

      # UEFI firmware — version-specific
      inherit
        (pkgs.callPackages ../pkgs/uefi-firmware/r${l4tMajorVersion} {
          inherit (finalJetpack) l4tMajorMinorPatchVersion patchfv;
        })
        uefi-firmware
        jetsonStandaloneMMOptee
        ;

      # OP-TEE
      genEkb = finalJetpack.callPackage ../pkgs/optee/gen-ekb.nix { };

      # Flash from device
      flashFromDevice = finalJetpack.callPackage ../pkgs/flash-from-device { };

      # OTA utilities
      otaUtils = finalJetpack.callPackage ../pkgs/ota-utils { };

      # Container support
      l4tCsv = finalJetpack.callPackage ../pkgs/containers/l4t-csv.nix { };
      genL4tJson = finalJetpack.callPackage ../pkgs/containers/genL4tJson.nix { };
      containerDeps = finalJetpack.callPackage ../pkgs/containers/deps.nix { };

      # Kernel
      kernel = finalJetpack.callPackage ../pkgs/kernels/r${l4tMajorVersion} { kernelPatches = [ ]; };
      kernelPackages = pkgs.linuxPackagesFor finalJetpack.kernel;

      rtkernel = finalJetpack.callPackage ../pkgs/kernels/r${l4tMajorVersion} {
        kernelPatches = [ ];
        realtime = true;
      };
      rtkernelPackages = pkgs.linuxPackagesFor finalJetpack.rtkernel;

      kernelPackagesOverlay =
        kFinal: _:
        if l4tAtLeast "36" then
          {
            devicetree = kFinal.callPackage ../pkgs/kernels/r${l4tMajorVersion}/devicetree.nix {
              inherit (finalJetpack)
                bspSrc
                gitRepos
                l4tMajorMinorPatchVersion
                ;
            };
            nvidia-oot-modules = kFinal.callPackage ../pkgs/kernels/r${l4tMajorVersion}/oot-modules.nix {
              inherit (finalJetpack)
                bspSrc
                gitRepos
                l4tMajorMinorPatchVersion
                ;
            };
          }
        else
          {
            nvidia-display-driver =
              kFinal.callPackage ../pkgs/kernels/r${l4tMajorVersion}/display-driver.nix
                {
                  inherit (finalJetpack) gitRepos l4tMajorMinorPatchVersion;
                };
          };

      # Benchmarks
      nxJetsonBenchmarks = finalJetpack.callPackage ../pkgs/jetson-benchmarks {
        targetSom = "nx";
      };
      xavierAgxJetsonBenchmarks = finalJetpack.callPackage ../pkgs/jetson-benchmarks {
        targetSom = "xavier-agx";
      };
      orinAgxJetsonBenchmarks = finalJetpack.callPackage ../pkgs/jetson-benchmarks {
        targetSom = "orin-agx";
      };

      # Samples (nested scope)
      samples = lib.makeScope finalJetpack.newScope (
        finalSamples:
        {
          callPackages = callPackagesWith (finalJetpack // finalSamples);
        }
        // lib.packagesFromDirectoryRecursive {
          directory = ../pkgs/samples;
          inherit (finalSamples) callPackage;
        }
      );

      # Tests
      tests = finalJetpack.callPackages ../pkgs/tests { };

      # dlopen override helper
      dlopenOverride = pkgs.callPackage ../pkgs/dlopen-override { };
    }
    # Add L4T packages (version-conditional).
    # NOTE: Pass callPackage explicitly to avoid infinite recursion —
    # the L4T default.nix uses it to auto-discover individual packages.
    // import ../pkgs/l4t {
      inherit (finalJetpack) callPackage;
      inherit l4tAtLeast l4tOlder lib;
    }
    # Add OP-TEE packages
    // lib.packagesFromDirectoryRecursive {
      inherit (finalJetpack) callPackage;
      directory = ../pkgs/optee;
    };

  jetpackPackages = lib.makeScope pkgs.newScope (
    extends (composeManyExtensions [ ]) jetpackFixedPoint
  );
in
jetpackPackages
