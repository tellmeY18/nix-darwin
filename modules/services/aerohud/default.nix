{ config, lib, pkgs, ... }:

let
  cfg = config.services.aerohud;
in
{
  options.services.aerohud = with lib.types; {
    enable = lib.mkEnableOption "AeroHUD grid overview for AeroSpace";

    package = lib.mkPackageOption pkgs "aerohud" {
      default = [ "aerohud" ];
    };

    layout = lib.mkOption {
      type = listOf str;
      default = [ "1" "2" "3" "q" "w" "e" "a" "s" "d" ];
      description = "Workspace names in grid order (left-to-right, top-to-bottom).";
      example = [ "1" "2" "3" "4" "q" "w" "e" "r" ];
    };

    cols = lib.mkOption {
      type = ints.positive;
      default = 3;
      description = "Number of columns in the grid.";
    };

    keybinding = lib.mkOption {
      type = str;
      default = "alt-space";
      description = "AeroSpace keybinding to toggle the HUD.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    services.aerospace.settings = lib.mkIf config.services.aerospace.enable {
      mode.main.binding.${cfg.keybinding} =
        "exec-and-forget ${cfg.package}/bin/aerohud ${toString cfg.cols} ${lib.concatStringsSep " " cfg.layout}";
    };
  };
}
