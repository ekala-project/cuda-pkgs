# Fetches and unpacks the NVIDIA Jetson Linux BSP source tarball.
{
  applyPatches,
  buildPackages,
  fetchurl,
  lib,
  l4tMajorMinorPatchVersion,
  bspHash,
  bspPatches ? [ ],
  bspPrePatch ? "",
  bspPostPatch ? "",
}:
let
  inherit (lib.versions) major minor patch;

  releaseDirectory = if l4tMajorMinorPatchVersion == "36.5.2" then "releases" else "release";

  bspUrl = "https://developer.download.nvidia.com/embedded/L4T/r${major l4tMajorMinorPatchVersion}_Release_v${minor l4tMajorMinorPatchVersion}.${patch l4tMajorMinorPatchVersion}/${releaseDirectory}/Jetson_Linux_R${l4tMajorMinorPatchVersion}_aarch64.tbz2";
in
applyPatches {
  src =
    buildPackages.runCommand "l4t-unpacked"
      {
        src = fetchurl {
          url = bspUrl;
          hash = bspHash;
        };
        nativeBuildInputs = [ buildPackages.bzip2 ];
      }
      ''
        bzip2 -d -c $src | tar xf -
        mv Linux_for_Tegra $out
      '';
  patches = bspPatches;
  prePatch = bspPrePatch;
  postPatch = bspPostPatch;
}
