{
  runCommandLocal,
  mcLibs,
  makeWrapper,
  jdk23,
}:
runCommandLocal "mcD" {
  nativeBuildInputs = [makeWrapper];
  meta.mainProgram = "launchMC";
} ''
  mkdir -p $out/bin
  cp -r ${mcLibs}/libraries $out/bin/libraries
  cp -r ${mcLibs}/*.jar $out/bin/
  cp ${mcLibs.src} $out/bin/server.jar
  echo 'eula=true' > $out/bin/eula.txt

  # TODO fucking improve this mess
  makeWrapper ${jdk23}/bin/java $out/bin/launchMC \
    --run "mkdir -p ./mcRuntime" \
    --run "cp -r --update $out/bin/libraries ./mcRuntime/" \
    --run "cp --update $out/bin/*.jar ./mcRuntime/" \
    --run "cp $out/bin/eula.txt ./mcRuntime/eula.txt" \
    --run "cd mcRuntime" \
    --add-flags "-jar @$out/bin/libraries/net/minecraftforge/forge/1.21.5-55.0.9/unix_args.txt $out/bin/server.jar nogui"
''
