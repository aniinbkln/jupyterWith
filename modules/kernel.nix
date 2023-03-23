{
  name,
  kernelName,
  self,
  system,
  lib,
  config,
  requiredRuntimePackages ? [],
}: let
  inherit (lib) types;
in {
  options = {
    enable = lib.mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = lib.mdDoc ''
        Enable ${kernelName} kernel.
      '';
    };

    name = lib.mkOption {
      type = types.str;
      default = "${kernelName}-${name}";
      example = "${kernelName}-example";
      description = lib.mdDoc ''
        Name of the ${kernelName} kernel.
      '';
    };

    displayName = lib.mkOption {
      type = types.str;
      default = "${config.name} kernel";
      example = "${kernelName} example kernel";
      description = lib.mdDoc ''
        Display name of the ${kernelName} kernel.
      '';
    };

    requiredRuntimePackages = lib.mkOption {
      type = types.listOf types.package;
      default = requiredRuntimePackages;
      example = lib.literalExpression "[pkgs.example]";
      description = lib.mdDoc ''
        A list of required runtime packages for this ${kernelName} kernel.
      '';
    };

    runtimePackages = lib.mkOption {
      type = types.listOf types.package;
      default = [];
      description = lib.mdDoc ''
        A list of user desired runtime packages for this ${kernelName} kernel.
      '';
    };

    notebookConfig = lib.mkOption {
      type = types.attrs;
      description = "jupyter notebook config which will be written to jupyter_notebook_config.py";
      default = {};
      apply = c: lib.recursiveUpdate (lib.importJSON ./conf/jupyter_notebook_config.json) c;
    };

    nixpkgs = import ./types/nixpkgs.nix {
      inherit lib self system;
      overlays = import ./types/overlays.nix {inherit lib self config kernelName;};
    };

    kernelArgs = lib.mkOption {
      type = types.lazyAttrsOf types.raw;
      readOnly = true;
      internal = true;
    };
  };

  kernelArgs = {
    inherit
      (config)
      name
      displayName
      requiredRuntimePackages
      runtimePackages
      ;
    pkgs = config.nixpkgs;
  };
}
