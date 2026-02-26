{
  lib,
  pkgs,
  stdenv,
}:

let
  stubModule = import ./lib/stub-module.nix;

  eval = lib.evalModules {
    modules = [
      stubModule
      ../modules/home-manager/openclaw.nix
      (
        { lib, ... }:
        {
          config = {
            home.homeDirectory = "/tmp";
            programs.git.enable = false;
            lib.file.mkOutOfStoreSymlink = path: path;
            programs.openclaw = {
              enable = true;
              launchd.enable = false;
              systemd.enable = true;
            };
          };
        }
      )
    ];
    specialArgs = { inherit pkgs; };
  };

  hasUnit = builtins.hasAttr "openclaw-gateway" eval.config.systemd.user.services;
  check = if hasUnit then "ok" else throw "Default OpenClaw instance missing systemd.unitName.";
  checkKey = builtins.deepSeq check "ok";

in
stdenv.mkDerivation {
  pname = "openclaw-default-instance";
  version = "1";
  dontUnpack = true;
  env = {
    OPENCLAW_DEFAULT_INSTANCE = checkKey;
  };
  installPhase = "${../scripts/empty-install.sh}";
}
