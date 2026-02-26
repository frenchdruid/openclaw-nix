{
  lib,
  pkgs,
  stdenv,
  nodejs_22,
  openclawGateway,
}:

let
  stubModule = import ./lib/stub-module.nix;

  moduleEval = lib.evalModules {
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
              systemd.enable = false;
              instances.default = { };
              config = {
                gateway = {
                  bind = "tailnet";
                  auth = {
                    mode = "token";
                    token = "test-token";
                  };
                  reload = {
                    mode = "hot";
                    debounceMs = 500;
                  };
                };
                discovery.mdns.mode = "minimal";
              };
            };
          };
        }
      )
    ];
    specialArgs = { inherit pkgs; };
  };

  configPathKey = ".openclaw/openclaw.json";
  configJson = moduleEval.config.home.file."${configPathKey}".text;
  configFile = pkgs.writeText "openclaw-config.json" configJson;

in
stdenv.mkDerivation {
  pname = "openclaw-config-validity";
  version = lib.getVersion openclawGateway;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [ nodejs_22 ];

  env = {
    OPENCLAW_CONFIG_PATH = configFile;
    OPENCLAW_SRC = "${openclawGateway}/lib/openclaw";
  };

  doCheck = true;
  checkPhase = "${nodejs_22}/bin/node ${../scripts/check-config-validity.mjs}";
  installPhase = "${../scripts/empty-install.sh}";
}
