# Simplified CUDA backend stdenv for ekapkgs.
# Selects a GCC version compatible with NVCC for the given CUDA version.
{
  config,
  cudaLib,
  cudaMajorMinorVersion,
  db,
  lib,
  pkgs,
  stdenv,
  stdenvAdapters,
}:
let
  inherit (db) allSortedCudaCapabilities cudaCapabilityToInfo nvccCompatibilities;
  inherit (lib)
    assertMsg
    filter
    findFirst
    flip
    range
    reverseList
    toIntBase10
    versionAtLeast
    versionOlder
    ;
  inherit (lib.versions) major;

  cudaCapabilityIsSupported =
    cudaMajorMinorVersion: info:
    versionAtLeast cudaMajorMinorVersion info.minCudaMajorMinorVersion
    && (info.maxCudaMajorMinorVersion == null || versionAtLeast info.maxCudaMajorMinorVersion cudaMajorMinorVersion);

  cudaCapabilityIsDefault =
    cudaMajorMinorVersion: info:
    cudaCapabilityIsSupported cudaMajorMinorVersion info
    && !info.isJetson
    && !info.isArchitectureSpecific
    && !info.isFamilySpecific
    && (
      info.dontDefaultAfterCudaMajorMinorVersion == null
      || versionAtLeast info.dontDefaultAfterCudaMajorMinorVersion cudaMajorMinorVersion
    );

  passthruExtra = {
    hostNixSystem = stdenv.hostPlatform.system;

    hostRedistSystem = cudaLib.getRedistSystem {
      inherit (stdenv.hostPlatform) system;
    };

    cudaForwardCompat = config.cudaForwardCompat or true;

    supportedCudaCapabilities = filter (
      cudaCapability:
      cudaCapabilityIsSupported cudaMajorMinorVersion cudaCapabilityToInfo.${cudaCapability}
    ) allSortedCudaCapabilities;

    defaultCudaCapabilities = filter (
      cudaCapability:
      cudaCapabilityIsDefault cudaMajorMinorVersion cudaCapabilityToInfo.${cudaCapability}
    ) passthruExtra.supportedCudaCapabilities;

    cudaCapabilities =
      if config.cudaCapabilities or [ ] != [ ] then
        config.cudaCapabilities
      else
        passthruExtra.defaultCudaCapabilities;
  };

  backendStdenv =
    let
      hostCCName =
        if stdenv.cc.isGNU then
          "gcc"
        else if stdenv.cc.isClang then
          "clang"
        else
          throw "cudaPackages.backendStdenv: unsupported host compiler: ${stdenv.cc.name}";

      versions = nvccCompatibilities.${cudaMajorMinorVersion}.${hostCCName};

      stdenvIsSupportedVersion =
        versionAtLeast (major stdenv.cc.version) versions.minMajorVersion
        && versionAtLeast versions.maxMajorVersion (major stdenv.cc.version);

      maybeGetVersionedCC =
        if hostCCName == "gcc" then
          version: pkgs."gcc${version}Stdenv" or null
        else
          version: pkgs."llvmPackages_${version}".stdenv or null;

      maybeHostStdenv =
        lib.pipe (range (toIntBase10 versions.minMajorVersion) (toIntBase10 versions.maxMajorVersion))
          [
            (map toString)
            reverseList
            (map maybeGetVersionedCC)
            (findFirst (x: x != null) null)
          ];
    in
    if stdenvIsSupportedVersion || passthruExtra.hostRedistSystem == "unsupported" then
      stdenv
    else
      assert assertMsg (maybeHostStdenv != null)
        "backendStdenv: no supported host compiler found (tried ${hostCCName} ${versions.minMajorVersion} to ${versions.maxMajorVersion})";
      stdenvAdapters.useLibsFrom stdenv maybeHostStdenv;
in
backendStdenv.override (prevArgs: {
  extraAttrs = prevArgs.extraAttrs or { } // passthruExtra;
})
