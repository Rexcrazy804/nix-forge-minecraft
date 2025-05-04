{
  pkgs,
  modulesPath,
  config,
  ...
}: {
  imports = [(modulesPath + "/profiles/qemu-guest.nix")];

  networking.hostName = "minecraft";
  system.stateVersion = "25.05";
  virtualisation = {
    graphics = false;
    diskSize = 10 * 1024;
    memorySize = 2 * 1024;
  };

  # primary user (yes sumee its you and your wife)
  users = {
    users.sumee = {
      enable = true;
      initialPassword = "nahida";
      createHome = true;
      isNormalUser = true;
      uid = 1000;
      group = "wheel";
    };
  };

  security.sudo.wheelNeedsPassword = false;
  nix = {
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    gc = {
      persistent = true;
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # starting point for minecraft forge specific configuration
  # largely a derivation of https://gist.github.com/cyber-murmel/4aeae3b5dafc72f12827b3284a9da481
  users = {
    groups.minecraft = {};
    extraUsers.minecraft = {
      isSystemUser = true;
      group = "minecraft";
      home = "/var/minecraft";
      createHome = true;
      packages = let
        mcVersion = "1.21.5";
        forgeVersion = "55.0.9";
        forgeSrc = pkgs.fetchurl {
          pname = "forge";
          version = "${mcVersion}-${forgeVersion}";
          url = "https://maven.minecraftforge.net/net/minecraftforge/forge/${mcVersion}-${forgeVersion}/forge-${mcVersion}-${forgeVersion}-installer.jar";
          hash = "sha256-I1Qf9xdiQLjLZzZkPpjVh3a940JsRHCJKl5ehVXv01Q=";
        };

        installMc = pkgs.writers.writeNuBin "installMc" ''
          if ("forge" | path exists) { return 0; }
          mkdir forge
          cd forge
          ${pkgs.jdk23}/bin/java -jar ${forgeSrc} --installServer
          cp ${forgeSrc} ./forge.jar
          echo 'eula=true' o> eula.txt
          open ./run.sh | str replace -r "/usr/bin/env sh" "${pkgs.bash}/bin/bash" | save -f ./run.sh
        '';
      in [installMc];
    };
  };

  systemd.services.minecraft = {
    enable = true;
    description = "Forge Minecraft Server";
    path = [pkgs.jdk23];
    serviceConfig = {
      ExecStart = "${config.users.extraUsers.minecraft.home}/forge/run.sh";
      WorkingDirectory = "${config.users.extraUsers.minecraft.home}/forge";
      Restart = "always";
      RestartSec = 60;
    };
    after = ["network.target"];
    # uncomment the line below after installing mc with the installMc script
    # wantedBy = ["multi-user.target"];
  };

  # opens ports for connecting to the minecraft server
  networking.firewall.allowedTCPPorts = [25565 25575];
  networking.firewall.allowedUDPPorts = [25565 25575];
}
