{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.librewolf;

  mkOverridesFile = prefs: ''
    // Generated by Home Manager.

    ${concatStrings (mapAttrsToList (name: value: ''
      defaultPref("${name}", ${builtins.toJSON value});
    '') prefs)}
  '';

  modulePath = [ "programs" "librewolf" ];

  mkFirefoxModule = import ./firefox/mkFirefoxModule.nix;

in {
  meta.maintainers = [ maintainers.chayleaf maintainers.onny ];

  imports = [
    (mkFirefoxModule {
      inherit modulePath;
      name = "LibreWolf";
      description = "LibreWolf is a privacy enhanced Firefox fork.";
      wrappedPackageName = "librewolf";
      unwrappedPackageName = "librewolf-unwrapped";

      platforms.linux = {
        vendorPath = ".librewolf";
        configPath = ".librewolf";
      };
      platforms.darwin = {
        vendorPath = "Library/Application Support/LibreWolf";
        configPath = "Library/Application Support/LibreWolf";
      };

      enableBookmarks = false;
    })
  ];

  options.programs.librewolf = {
    settings = mkOption {
      type = with types; attrsOf (either bool (either int str));
      default = { };
      example = literalExpression ''
        {
          "webgl.disabled" = false;
          "privacy.resistFingerprinting" = false;
        }
      '';
      description = ''
        Attribute set of global LibreWolf settings and overrides. Refer to
        <https://librewolf.net/docs/settings/>
        for details on supported values.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.librewolf" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    home.file.".librewolf/librewolf.overrides.cfg" =
      lib.mkIf (cfg.settings != { }) { text = mkOverridesFile cfg.settings; };
  };
}
