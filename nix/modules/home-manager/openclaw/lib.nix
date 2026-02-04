{ config, lib, pkgs }:

let
  cfg = config.programs.openclaw;
  homeDir = config.home.homeDirectory;
  autoExcludeTools = lib.optionals config.programs.git.enable [ "git" ];
  effectiveExcludeTools = lib.unique (cfg.excludeTools ++ autoExcludeTools);
  toolOverrides = {
    toolNamesOverride = cfg.toolNames;
    excludeToolNames = effectiveExcludeTools;
  };
  toolOverridesEnabled = cfg.toolNames != null || effectiveExcludeTools != [];
  toolSets = import ../../../tools/extended.nix ({ inherit pkgs; } // toolOverrides);
  defaultPackage =
    if toolOverridesEnabled && cfg.package == pkgs.openclaw
    then (pkgs.openclawPackages.withTools toolOverrides).openclaw
    else cfg.package;
  appPackage = if cfg.appPackage != null then cfg.appPackage else defaultPackage;
  generatedConfigOptions = import ../../../generated/openclaw-config-options.nix { lib = lib; };

  firstPartySources = let
    stepieteRev = "203442241f72839e3681affdc131134882109e54";
    stepieteNarHash = "sha256-f/I0V+uLjo2Xzw88sjvVo5vlDq8itmQo9qOvJQ3e+EI=";
    stepiete = tool:
      "github:openclaw/nix-steipete-tools?dir=tools/${tool}&rev=${stepieteRev}&narHash=${stepieteNarHash}";
  in {
    summarize = stepiete "summarize";
    peekaboo = stepiete "peekaboo";
    oracle = stepiete "oracle";
    poltergeist = stepiete "poltergeist";
    sag = stepiete "sag";
    camsnap = stepiete "camsnap";
    gogcli = stepiete "gogcli";
    goplaces = stepiete "goplaces";
    bird = stepiete "bird";
    sonoscli = stepiete "sonoscli";
    imsg = stepiete "imsg";
  };

  firstPartyPlugins = lib.filter (p: p != null) (lib.mapAttrsToList (name: source:
    let
      pluginCfg = cfg.firstParty.${name};
    in
      if (pluginCfg.enable or false) then {
        inherit source;
        config = pluginCfg.config or {};
      } else null
  ) firstPartySources);

  effectivePlugins = cfg.plugins ++ firstPartyPlugins;

  resolvePath = p:
    if lib.hasPrefix "~/" p then
      "${homeDir}/${lib.removePrefix "~/" p}"
    else
      p;

  toRelative = p:
    if lib.hasPrefix "${homeDir}/" p then
      lib.removePrefix "${homeDir}/" p
    else
      p;

in {
  inherit
    cfg
    homeDir
    toolOverrides
    toolOverridesEnabled
    toolSets
    defaultPackage
    appPackage
    generatedConfigOptions
    firstPartySources
    firstPartyPlugins
    effectivePlugins
    resolvePath
    toRelative;
}
