{
  stdenv,
  mcVersion ? "1.21.5",
  forgeVersion ? "55.0.9",
  installerHash ? "",
  libHash ? "",
  fetchurl,
  jdk23,
}:
stdenv.mkDerivation (final: {
  pname = "mcforge";
  version = "${mcVersion}-${forgeVersion}";
  src = fetchurl {
    url = "https://maven.minecraftforge.net/net/minecraftforge/forge/${mcVersion}-${forgeVersion}/forge-${mcVersion}-${forgeVersion}-installer.jar";
    hash = installerHash;
  };

  dontUnpack = true;
  dontPatch = true;

  nativeBuildInputs = [jdk23];

  buildPhase = ''
    java -jar $src --installServer
  '';

  installPhase = ''
    mkdir $out
    cp -r libraries $out/libraries
    cp forge-${mcVersion}-${forgeVersion}-shim.jar $out
  '';

  outputHashMode = "recursive";
  outputHashAlgo = "sha256";
  outputHash = libHash;

  passthru = {
    shim-name = "forge-${mcVersion}-${forgeVersion}-shim.jar";
  };
})
