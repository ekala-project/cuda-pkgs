{ lib }:
{
  mkMetaBroken =
    finalAttrs:
    let
      brokenAssertions = finalAttrs.passthru.brokenAssertions or [ ];
      failedAssertions = lib.filter (a: !a.assertion) brokenAssertions;
      hasFailures = failedAssertions != [ ];
    in
    hasFailures;

  mkMetaBadPlatforms =
    finalAttrs:
    let
      platformAssertions = finalAttrs.passthru.platformAssertions or [ ];
      failedAssertions = lib.filter (a: !a.assertion) platformAssertions;
      hasFailures = failedAssertions != [ ];
      finalStdenv = finalAttrs.finalPackage.stdenv;
    in
    lib.optionals hasFailures (
      lib.unique [
        finalStdenv.buildPlatform.system
        finalStdenv.hostPlatform.system
        finalStdenv.targetPlatform.system
      ]
    );
}
