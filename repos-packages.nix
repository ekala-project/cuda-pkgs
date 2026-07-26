{ ... }:
let
  pins = import ./pins.nix;
  lib = import pins.lib;
  pkgs = import pins.core { modules = [ (import ./pkgs-module.nix) ]; };

  # Expose all cudaPackages for CI validation
  cudaPackages = pkgs.cudaPackages or { };
  cudaPackages_12_8 = pkgs.cudaPackages_12_8 or { };
  cudaPackages_13_3 = pkgs.cudaPackages_13_3 or { };
in
{
  inherit cudaPackages cudaPackages_12_8 cudaPackages_13_3;
}
