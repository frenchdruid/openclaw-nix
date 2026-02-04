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

  bundledPluginSources = let
    stepieteRev = "20743922a320633f32575ac9f4f034aa05f64440";
    stepieteNarHash = "sha256-rWV482F/Haa1LH59YLqWhMP9QCmuL+3ia6lxkjqvdH8=";
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

  bundledPlugins = lib.filter (p: p != null) (lib.mapAttrsToList (name: source:
    let
      pluginCfg = cfg.bundledPlugins.${name};
    in
      if (pluginCfg.enable or false) then {
        inherit source;
        config = pluginCfg.config or {};
      } else null
  ) bundledPluginSources);

  effectivePlugins = cfg.customPlugins ++ bundledPlugins;

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
    bundledPluginSources
    bundledPlugins
    effectivePlugins
    resolvePath
    toRelative;
}
