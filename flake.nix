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
    packages = forAllSystems (pkgs: {
      minecraft = generators.nixosGenerate {
        inherit (pkgs) system;
        modules = [
          ./configurations/minecraft.nix
        ];
        format = "vm";
      };

      minecraftForge = let
        mcVersion = "1.21.5";
        forgeVersion = "55.0.9";
        mcInstaller = pkgs.fetchurl {
          url = "https://maven.minecraftforge.net/net/minecraftforge/forge/${mcVersion}-${forgeVersion}/forge-${mcVersion}-${forgeVersion}-installer.jar";
          hash = "sha256-I1Qf9xdiQLjLZzZkPpjVh3a940JsRHCJKl5ehVXv01Q=";
        };
        mcLibs = pkgs.stdenv.mkDerivation {
          pname = "mcforge";
          version = "${mcVersion}-${forgeVersion}";
          src = mcInstaller;
          dontUnpack = true;
          dontPatch = true;

          nativeBuildInputs = [pkgs.jdk23];

          buildPhase = ''
            java -jar $src --installServer
          '';
          installPhase = ''
            mkdir $out
            cp -r libraries $out/libraries
            cp *.jar $out
            # runHook postInstall
          '';

          postInstall = ''
            rm $out/*.log
            rm $out/run.sh
          '';

          outputHashMode = "recursive";
          outputHashAlgo = "sha256";
          outputHash = "sha256-0nTBjm3jm6WLwPch0fnDtqdU25u5Ypm2aofWfWe82io=";
        };
      in
        pkgs.runCommandLocal "mcD" {
          nativeBuildInputs = [pkgs.makeWrapper];
          meta.mainProgram = "launchMC";
        } ''
          mkdir -p $out/bin
          cp -r ${mcLibs}/libraries $out/bin/libraries
          cp -r ${mcLibs}/*.jar $out/bin/
          cp ${mcInstaller} $out/bin/server.jar
          echo 'eula=true' > $out/bin/eula.txt

          makeWrapper ${pkgs.jdk23}/bin/java $out/bin/launchMC \
            --run "mkdir -p ./mcRuntime" \
						--run "cp -r --update $out/bin/libraries ./mcRuntime/" \
						--run "cp --update $out/bin/*.jar ./mcRuntime/" \
						--run "cp $out/bin/eula.txt ./mcRuntime/eula.txt" \
						--run "cd mcRuntime" \
            --add-flags "-jar @$out/bin/libraries/net/minecraftforge/forge/1.21.5-55.0.9/unix_args.txt $out/bin/server.jar nogui"
        '';
    });
  };
}
