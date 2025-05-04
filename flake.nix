{
  description = "A minimal Flake template";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    generators,
  }: let
    systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    forAllSystems = f:
      nixpkgs.lib.genAttrs systems (
        system:
          f (import nixpkgs {
            inherit system;
          })
      );
  in {
    packages = forAllSystems (pkgs: rec {
      minecraftVM = generators.nixosGenerate {
        inherit (pkgs) system;
        modules = [
          ./configurations/minecraft.nix
        ];
        format = "vm";
      };

      mcLibs = pkgs.callPackage ./pkgs/mcLibs.nix {
        mcVersion = "1.21.5";
        forgeVersion = "55.0.9";
        installerHash = "sha256-I1Qf9xdiQLjLZzZkPpjVh3a940JsRHCJKl5ehVXv01Q=";
        libHash = "sha256-0nTBjm3jm6WLwPch0fnDtqdU25u5Ypm2aofWfWe82io=";
      };

      mcTextRunner = pkgs.callPackage ./pkgs/hackyRunner.nix {inherit mcLibs;};
    });
  };
}
