{
  pkgs,
  name,
  displayName,
  requiredRuntimePackages,
  runtimePackages,
  julia,
  julia_depot_path,
  activateDir,
  ijuliaRev,
}: let
  inherit (pkgs) writeText;
  inherit (pkgs.lib) optionalString;

  startupFile = writeText "startup.jl" ''
    import Pkg
    Pkg.activate("${activateDir}")
    Pkg.instantiate()
  '';

  allRuntimePackages = requiredRuntimePackages ++ runtimePackages;

  env = julia;

  wrappedEnv =
    pkgs.runCommand "wrapper-${env.name}"
    {nativeBuildInputs = [pkgs.makeWrapper];}
    ''
      mkdir -p $out/bin
      for i in ${env}/bin/*; do
        filename=$(basename $i)
        ln -s ${env}/bin/$filename $out/bin/$filename
        wrapProgram $out/bin/$filename \
          --set PATH "${pkgs.lib.makeSearchPath "bin" allRuntimePackages}" ${optionalString (activateDir != "") ''--add-flags "-L ${startupFile}"''}
      done
    '';
in {
  inherit name displayName;
  language = "julia";
  argv = [
    "${wrappedEnv}/bin/julia"
    "-i"
    "--startup-file=yes"
    "--color=yes"
    "${julia_depot_path}/packages/IJulia/${ijuliaRev}/src/kernel.jl"
    "{connection_file}"
  ];
  codemirrorMode = "julia";
  logo64 = ./logo-64x64.png;
}
