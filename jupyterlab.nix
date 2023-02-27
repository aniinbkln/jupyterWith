{
  pkgs,
  poetryEnv,
  ...
}: let
  jupyterlabEnvBase = poetryEnv;

  jupyterlab-checker =
    pkgs.writeText "jupyterlab-checker"
    ''
      from jupyterlab.commands import build_check, ensure_app;
      import sys

      ensure_app_return = ensure_app('.jupyter/lab/share/jupyter/lab')
      build_check_return = build_check()
      if ensure_app_return is None and not build_check_return:
        sys.exit(0)
      # print(f'{ensure_app_return = }')
      # print(f'{build_check_return = }')
      sys.exit(1)
    '';
  jupyterlab-cond-build =
    pkgs.writeShellScript "jupyterlab-cond-build"
    ''
      ${jupyterlabEnvBase}/bin/python ${jupyterlab-checker}
      checker=$?
      if [ "$checker" -ne 0 ]
      then
        >&2 echo "[$(date +'%Y-%m-%d %H:%M:%S') jupyenv] needs to build JupyterLab."
        # we need to build the jupyter lab environment before it can be used
        ${jupyterlabEnvBase}/bin/jupyter lab build
      else
        >&2 echo "[$(date +'%Y-%m-%d %H:%M:%S') jupyenv] does not need build JupyterLab."
        >&2 echo "[$(date +'%Y-%m-%d %H:%M:%S') jupyenv] Starting..."
      fi
    '';
in
  pkgs.runCommand "chmod-${jupyterlabEnvBase.name}"
  {nativeBuildInputs = [pkgs.makeWrapper];}
  ''
    mkdir -p $out/bin
    for i in ${jupyterlabEnvBase}/bin/*; do
      filename=$(basename $i)

      if [[ "$filename" == jupyter* ]]; then
        cat <<EOF > $out/bin/$filename
    #!${pkgs.runtimeShell} -e
    trap "chmod +w --recursive \$PWD/.jupyter" EXIT
    ${jupyterlab-cond-build}
    ${jupyterlabEnvBase}/bin/$filename "\$@"
    EOF
        chmod +x $out/bin/$filename
      else
        makeWrapper \
          ${jupyterlabEnvBase}/bin/$filename \
          $out/bin/$filename
    fi
    done
  ''
