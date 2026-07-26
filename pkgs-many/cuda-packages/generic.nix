# Two-stage function for mkManyVariants.
# Stage 1: variant args (CUDA version, manifest selections)
# Stage 2: package args from callPackage
{
  cudaVersion,
  selectedManifests,
  packageAtLeast,
  packageOlder,
  ...
}:

{
  lib,
  newScope,
  ...
}@pkgs:

import ../../cuda/scope {
  cudaMajorMinorPatchVersion = cudaVersion;
  inherit lib;
  pkgs = pkgs;
  inherit selectedManifests;
}
