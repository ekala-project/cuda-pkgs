{
  description = "Ekala CUDA packages flake";

  inputs = {
    corepkgs.url = "github:ekala-project/corepkgs";
    nix-lib.follows = "corepkgs/nix-lib";
    systems.follows = "corepkgs/systems";
  };

  outputs =
    {
      corepkgs,
      nix-lib,
      self,
      systems,
      ...
    }:
    let
      forAllSystems = nix-lib.lib.genAttrs (import systems);
    in
    {
      # default.nix already applies ./pkgs-module.nix; passing it again via
      # `modules` would register every overlay twice.
      legacyPackages = forAllSystems (system: import ./. { inherit system; });

      formatter = corepkgs.formatter;
      nixConfig = {
        extra-substituters = [ "https://ekala-corepkgs.cachix.org" ];
        extra-trusted-public-keys = [
          "ekala-corepkgs.cachix.org-1:DcZV+vegWoEzacbSdXFXU4S7728C0eS9RfGpKeyHd6w="
        ];
      };
    };
}
