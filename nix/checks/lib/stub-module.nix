{ lib, ... }:
{
  options = {
    assertions = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
    };

    home.homeDirectory = lib.mkOption {
      type = lib.types.str;
      default = "/tmp";
    };

    home.packages = lib.mkOption {
      type = lib.types.listOf lib.types.anything;
      default = [ ];
    };

    home.file = lib.mkOption {
      type = lib.types.attrs;
      default = { };
    };

    home.activation = lib.mkOption {
      type = lib.types.attrs;
      default = { };
    };

    launchd.agents = lib.mkOption {
      type = lib.types.attrs;
      default = { };
    };

    systemd.user.services = lib.mkOption {
      type = lib.types.attrs;
      default = { };
    };

    programs.git.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    lib = lib.mkOption {
      type = lib.types.attrs;
      default = { };
    };
  };
}
