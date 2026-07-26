{ lib }:
{
  dotsToUnderscores = lib.replaceStrings [ "." ] [ "_" ];

  dropDots = lib.replaceStrings [ "." ] [ "" ];

  formatCapabilities =
    {
      cudaCapabilityToInfo,
      cudaCapabilities,
      cudaForwardCompat,
    }:
    let
      dropDots = lib.replaceStrings [ "." ] [ "" ];
      mkRealArchitecture = cudaCapability: "sm_" + dropDots cudaCapability;
      mkVirtualArchitecture = cudaCapability: "compute_" + dropDots cudaCapability;
      mkGencodeFlag =
        archPrefix: cudaCapability:
        let
          cap = dropDots cudaCapability;
        in
        "-gencode=arch=compute_${cap},code=${archPrefix}_${cap}";

      realArches = lib.map mkRealArchitecture cudaCapabilities;
      virtualArches = lib.map mkVirtualArchitecture cudaCapabilities;
      gencode =
        let
          base = lib.map (mkGencodeFlag "sm") cudaCapabilities;
          forward = mkGencodeFlag "compute" (lib.last cudaCapabilities);
        in
        base ++ lib.optionals cudaForwardCompat [ forward ];
    in
    {
      inherit
        cudaCapabilities
        cudaForwardCompat
        gencode
        realArches
        virtualArches
        ;

      archNames = lib.pipe cudaCapabilities [
        (lib.map (cudaCapability: cudaCapabilityToInfo.${cudaCapability}.archName))
        lib.unique
        lib.naturalSort
      ];

      arches = realArches ++ lib.optionals cudaForwardCompat [ (lib.last virtualArches) ];

      cmakeCudaArchitecturesString = lib.concatMapStringsSep ";" dropDots cudaCapabilities;

      gencodeString = lib.concatStringsSep " " gencode;
    };

  mkCmakeCudaArchitecturesString = cudaCapabilities:
    lib.concatMapStringsSep ";" (lib.replaceStrings [ "." ] [ "" ]) cudaCapabilities;

  mkGencodeFlag =
    archPrefix: cudaCapability:
    let
      cap = lib.replaceStrings [ "." ] [ "" ] cudaCapability;
    in
    "-gencode=arch=compute_${cap},code=${archPrefix}_${cap}";

  mkRealArchitecture = cudaCapability: "sm_" + lib.replaceStrings [ "." ] [ "" ] cudaCapability;

  mkVersionedName = name: version: "${name}_${lib.replaceStrings [ "." ] [ "_" ] version}";

  mkVirtualArchitecture = cudaCapability: "compute_" + lib.replaceStrings [ "." ] [ "" ] cudaCapability;
}
