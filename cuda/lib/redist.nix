{ lib, db }:
{
  getNixSystems =
    redistSystem:
    if redistSystem == "linux-x86_64" then
      [ "x86_64-linux" ]
    else if redistSystem == "linux-sbsa" || redistSystem == "linux-aarch64" then
      [ "aarch64-linux" ]
    else if redistSystem == "linux-all" || redistSystem == "source" then
      [
        "aarch64-linux"
        "x86_64-linux"
      ]
    else
      [ ];

  getRedistSystem =
    { system, ... }:
    if system == "x86_64-linux" then
      "linux-x86_64"
    else if system == "aarch64-linux" then
      "linux-sbsa"
    else
      "unsupported";

  mkRedistUrl =
    redistName: relativePath:
    lib.concatStringsSep "/" (
      [ db.redistUrlPrefix ]
      ++ (
        if redistName != "tensorrt" then
          [
            redistName
            "redist"
          ]
        else
          [ "machine-learning" ]
      )
      ++ [ relativePath ]
    );

  selectManifests = allManifests:
    lib.mapAttrs (
      name: version:
      let
        manifest = allManifests.${name}.${version};
      in
      manifest
      // {
        release_label = manifest.release_label or version;
      }
    );
}
