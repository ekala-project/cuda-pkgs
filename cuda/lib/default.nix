{ lib, db }:
let
  strings = import ./strings.nix { inherit lib; };
  redist = import ./redist.nix { inherit lib db; };
  meta = import ./meta.nix { inherit lib; };
in
strings // redist // meta
