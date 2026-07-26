# Simplified redistributable package builder for ekapkgs.
# Fetches pre-built binaries from NVIDIA's CDN using manifest data.
{
  addDriverRunpath,
  autoPatchelfHook,
  backendStdenv,
  cudaLib,
  cudaMajorMinorVersion,
  cudaMajorVersion,
  cudaNamePrefix,
  db,
  fetchurl,
  lib,
  manifests,
  markForCudatoolkitRootHook,
  stdenv,
}:
let
  inherit (lib.attrsets)
    attrNames
    foldlAttrs
    getDev
    hasAttr
    isAttrs
    optionalAttrs
    ;
  inherit (lib.customisation) extendMkDerivation;
  inherit (lib.lists)
    concatMap
    elem
    findFirst
    findFirstIndex
    foldl'
    intersectLists
    map
    naturalSort
    subtractLists
    tail
    unique
    ;
  inherit (lib.strings)
    concatMapStringsSep
    optionalString
    toUpper
    stringLength
    substring
    ;
  inherit (lib.trivial) flip mapNullable pipe;
  inherit (cudaLib) getNixSystems mkRedistUrl;

  hostRedistSystem = backendStdenv.hostRedistSystem or (
    cudaLib.getRedistSystem { inherit (stdenv.hostPlatform) system; }
  );

  mkOutputNameVar =
    output:
    "output" + toUpper (substring 0 1 output) + substring 1 (stringLength output - 1) output;

  desiredCudaVariant = "cuda${cudaMajorVersion}";

  getSupportedReleases =
    release:
    if release ? source then
      { inherit (release) source; }
    else if release ? linux-all then
      { inherit (release) linux-all; }
    else
      let
        hasCudaVariants = release ? cuda_variant;
      in
      foldlAttrs (
        acc: name: value:
        acc
        // optionalAttrs (isAttrs value && (hasCudaVariants -> hasAttr desiredCudaVariant value)) {
          ${name} = if hasCudaVariants then value.${desiredCudaVariant} else value;
        }
      ) { } release;

  getPreferredRelease =
    supportedReleases:
    supportedReleases.source or supportedReleases.linux-all or supportedReleases.${hostRedistSystem}
      or null;

  redistSystemIsSupported =
    redistSystems:
    lib.findFirst (
      rs: rs == hostRedistSystem || rs == "linux-all" || rs == "source"
    ) null redistSystems != null;
in
extendMkDerivation {
  constructDrv = backendStdenv.mkDerivation;
  excludeDrvArgNames = [
    "redistName"
    "release"
    "brokenAssertions"
    "platformAssertions"
    "expectedOutputs"
    "outputToPatterns"
    "outputNameVarFallbacks"
  ];
  extendDrvArgs =
    finalAttrs:
    {
      redistName,
      pname,
      release ? manifests.${finalAttrs.passthru.redistName}.${finalAttrs.pname} or null,

      outputs ? [ "out" ],
      propagatedBuildOutputs ? [ ],

      nativeBuildInputs ? [ ],
      propagatedBuildInputs ? [ ],
      buildInputs ? [ ],

      doInstallCheck ? true,
      allowFHSReferences ? false,

      appendRunpaths ? [ ],
      postFixup ? "",

      passthru ? { },
      meta ? { },

      brokenAssertions ? [ ],
      platformAssertions ? [ ],

      expectedOutputs ? [
        "out"
        "doc"
        "samples"
        "python"
        "bin"
        "dev"
        "include"
        "lib"
        "static"
        "stubs"
      ],

      outputToPatterns ? {
        bin = [ "bin" ];
        dev = [
          "**/*.pc"
          "**/*.cmake"
        ];
        include = [ "include" ];
        lib = [
          "lib"
          "lib64"
        ];
        static = [ "**/*.a" ];
        samples = [ "samples" ];
        python = [ "**/*.whl" ];
        stubs = [
          "stubs"
          "lib/stubs"
        ];
      },

      outputNameVarFallbacks ? {
        outputBin = [ "bin" ];
        outputDev = [ "dev" ];
        outputDoc = [ "doc" ];
        outputInclude = [
          "include"
          "dev"
        ];
        outputLib = [ "lib" ];
        outputOut = [ "out" ];
        outputPython = [ "python" ];
        outputSamples = [ "samples" ];
        outputStatic = [ "static" ];
        outputStubs = [
          "stubs"
          "lib"
        ];
      },
      ...
    }:
    {
      __structuredAttrs = true;
      strictDeps = true;

      version = finalAttrs.passthru.release.version or "0-unsupported";

      name = "${cudaNamePrefix}-${finalAttrs.pname}-${finalAttrs.version}";

      outputs =
        if finalAttrs.src == null then
          [ "out" ]
        else
          intersectLists outputs finalAttrs.passthru.expectedOutputs;

      propagatedBuildOutputs =
        intersectLists [
          "bin"
          "include"
          "lib"
        ] finalAttrs.outputs
        ++ propagatedBuildOutputs;

      src = mapNullable (
        { relative_path, sha256, ... }:
        fetchurl {
          url = mkRedistUrl finalAttrs.passthru.redistName relative_path;
          inherit sha256;
        }
      ) (getPreferredRelease finalAttrs.passthru.supportedReleases);

      inherit cudaMajorMinorVersion cudaMajorVersion;

      dontBuild = true;

      nativeBuildInputs = [
        ./build-redist-hook.bash
        autoPatchelfHook
        addDriverRunpath
        markForCudatoolkitRootHook
      ] ++ nativeBuildInputs;

      buildInputs = [
        (lib.getLib stdenv.cc.cc)
      ] ++ buildInputs;

      appendRunpaths = [ "$ORIGIN" ] ++ appendRunpaths;

      installPhase =
        let
          mkMoveToOutputCommand =
            output:
            let
              template = pattern: ''
                moveToOutput "${pattern}" "${"$" + output}"
              '';
              patterns = finalAttrs.passthru.outputToPatterns.${output} or [ ];
            in
            concatMapStringsSep "\n" template patterns;
        in
        ''
          runHook preInstall
        ''
        + ''
          mkdir -p "$out"
          nixLog "moving tree to output out"
          mv * "$out"
        ''
        + ''
          ${concatMapStringsSep "\n" mkMoveToOutputCommand (tail finalAttrs.outputs)}
        ''
        + ''
          runHook postInstall
        '';

      inherit doInstallCheck;
      inherit allowFHSReferences;

      inherit postFixup;

      passthru = passthru // {
        inherit redistName release;

        supportedReleases =
          passthru.supportedReleases
            or (getSupportedReleases (lib.defaultTo { } finalAttrs.passthru.release));

        supportedNixSystems =
          passthru.supportedNixSystems or (pipe finalAttrs.passthru.supportedReleases [
            attrNames
            (concatMap getNixSystems)
            naturalSort
            unique
          ]);

        supportedRedistSystems =
          passthru.supportedRedistSystems or (naturalSort (attrNames finalAttrs.passthru.supportedReleases));

        inherit expectedOutputs;
        inherit outputToPatterns;
        inherit outputNameVarFallbacks;

        brokenAssertions = brokenAssertions;

        platformAssertions =
          let
            isSupportedRedistSystem = redistSystemIsSupported finalAttrs.passthru.supportedRedistSystems;
          in
          [
            {
              message = "hostRedistSystem (${hostRedistSystem}) is supported (${builtins.toJSON finalAttrs.passthru.supportedRedistSystems})";
              assertion = isSupportedRedistSystem;
            }
          ]
          ++ platformAssertions;
      };

      meta = meta // {
        sourceProvenance = meta.sourceProvenance or [ lib.sourceTypes.binaryNativeCode ];
        platforms = finalAttrs.passthru.supportedNixSystems;
        broken = cudaLib.mkMetaBroken finalAttrs;
        badPlatforms = cudaLib.mkMetaBadPlatforms finalAttrs;
        license =
          if meta ? license then
            lib.toList meta.license
          else if finalAttrs.passthru.redistName == "cuda" then
            [ lib.licenses.nvidiaCudaRedist ]
          else
            [ lib.licenses.nvidiaCuda ];
        maintainers = [ ];
      };
    }
    // foldl' (
      acc: output:
      let
        outputNameVar = mkOutputNameVar output;
      in
      acc
      // {
        ${outputNameVar} =
          findFirst (flip elem finalAttrs.outputs) "out"
            finalAttrs.passthru.outputNameVarFallbacks.${outputNameVar};
      }
    ) { } expectedOutputs;

  inheritFunctionArgs = false;
}
