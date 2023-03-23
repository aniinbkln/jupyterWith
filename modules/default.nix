{
  self,
  config,
  lib,
  mkJupyterlab,
  system,
  ...
}: let
  types = lib.types;
in {
  options = {
    # jupyterlabEnvArgs ? {},
    # kernels ? k: [], # k: [ (k.python {}) k.bash ],
    # # extensions ? e: [], # e: [ e.jupy-ext ]

    jupyterlab = {
      runtimePackages = lib.mkOption {
        type = types.listOf types.package;
        description = "A list of runtime packages available to all binaries";
        default = [];
      };

      notebookConfig = lib.mkOption {
        type = types.attrs;
        description = "jupyter notebook config which will be written to jupyter_notebook_config.py";
        default = {};
        apply = c: lib.recursiveUpdate (lib.importJSON ./conf/jupyter_notebook_config.json) c;
      };

      jupyterlabEnvArgs = lib.mkOption {
        type = types.submodule {
          options =
            {
              extraPackages = lib.mkOption {
                type = types.functionTo (types.listOf types.package);
                default = ps: [];
                example = ps: [ps.jupytext];
                description = lib.mdDoc "A list of packages for extending the jupyterlab environment";
              };
            }
            // (lib.recursiveUpdate (import ./types/poetry.nix {
                inherit lib self;
                config =
                  config.jupyterlab.jupyterlabEnvArgs
                  // {
                    nixpkgs = config.nixpkgs.appendOverlays [
                      self.inputs.poetry2nix.overlay
                    ];
                  };
              })
              {
                projectDir.default = self.outPath;
                poetryEnv.default = null;
              });
        };
        default = {};
        description = "Arguments for the jupyterlab poetry's environment";
      };
    };

    # flakes ? [], # flakes where to detect custom kernels/extensions

    build = lib.mkOption {
      type = types.package;
      internal = true;
    };

    nixpkgs = import ./types/nixpkgs.nix {inherit lib self system;};
  };

  imports = [
    ./../kernels/available/bash/module.nix
    ./../kernels/available/c/module.nix
    ./../kernels/available/elm/module.nix
    ./../kernels/available/go/module.nix
    ./../kernels/available/haskell/module.nix
    ./../kernels/available/javascript/module.nix
    ./../kernels/available/julia/module.nix
    ./../kernels/available/nix/module.nix
    ./../kernels/available/ocaml/module.nix
    ./../kernels/available/postgres/module.nix
    ./../kernels/available/python/module.nix
    ./../kernels/available/r/module.nix
    ./../kernels/available/rust/module.nix
    ./../kernels/available/scala/module.nix
    ./../kernels/available/typescript/module.nix
    ./../kernels/available/zsh/module.nix
  ];
  # TODO: add kernels
  #++ map (name: ./. + "/../kernels/available/${name}/module.nix") (builtins.attrNames (builtins.readDir ./../kernels/available));

  config = {
    build = mkJupyterlab {
      jupyterlabEnvArgs = {
        pkgs = config.nixpkgs;
        inherit
          (config.jupyterlab.jupyterlabEnvArgs)
          poetryEnv
          extraPackages
          ;
      };

      inherit
        (config.jupyterlab)
        notebookConfig
        runtimePackages
        ;

      kernels = availableKernels:
        lib.flatten
        (
          builtins.map
          (
            kernelTypeName:
              builtins.map
              (
                kernelName:
                  availableKernels.${kernelTypeName}
                  config.kernel.${kernelTypeName}.${kernelName}.kernelArgs
              )
              (builtins.attrNames config.kernel.${kernelTypeName})
          )
          (builtins.attrNames config.kernel)
        );
      #flakes = config.flakes;
    };
    _module.args.pkgs = config.nixpkgs;
  };
}
