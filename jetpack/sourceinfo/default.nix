# Loads deb and git source metadata for a given L4T release.
# Returns { debs, gitRepos } where each deb entry includes a fetchurl `src`.
{
  lib,
  fetchurl,
  fetchgit,
  l4tMajorMinorPatchVersion,
}:
let
  inherit (lib.versions) majorMinor;

  debsJSON = lib.importJSON (./. + "/r${majorMinor l4tMajorMinorPatchVersion}-debs.json");
  baseURL = "https://repo.download.nvidia.com/jetson";

  fetchDeb =
    repo: pkg:
    fetchurl {
      url = "${baseURL}/${repo}/${pkg.filename}";
      sha256 = pkg.sha256;
    };

  debs = lib.mapAttrs (
    repo: pkgs: lib.mapAttrs (pkgname: pkg: pkg // { src = fetchDeb repo pkg; }) pkgs
  ) debsJSON;

  gitJSON = lib.importJSON (./. + "/r${l4tMajorMinorPatchVersion}-gitrepos.json");
  gitRepos = lib.mapAttrs (
    relpath: info:
    fetchgit {
      inherit (info) url rev hash;
    }
  ) gitJSON;
in
{
  inherit debs gitRepos;
}
