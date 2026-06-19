{ config, lib, pkgs, ... }:

let
  cfg = config.services.omniwm;

  format = pkgs.formats.toml { };

  # Recursively filter null values so optional settings can be omitted.
  filterAttrsRecursive = pred: set:
    lib.listToAttrs (
      lib.concatMap (
        name: let
          v = set.${name};
        in
          if pred v
          then [
            (lib.nameValuePair name (
              if lib.isAttrs v
              then filterAttrsRecursive pred v
              else if lib.isList v
              then
                (map (i:
                  if lib.isAttrs i
                  then filterAttrsRecursive pred i
                  else i) (lib.filter pred v))
              else v
            ))
          ]
          else []
      ) (lib.attrNames set)
    );

  filterNulls = filterAttrsRecursive (v: v != null);

  configFile = format.generate "settings.toml" (filterNulls cfg.settings);
in

{
  meta.maintainers = [ "tellmeY18" ];

  options.services.omniwm = {
    enable = lib.mkEnableOption "OmniWM window manager";

    package = lib.mkPackageOption pkgs "omniwm" {
      default = [ ];
      example = "/Applications/OmniWM.app/Contents/MacOS/OmniWM";
      description = "Path to the OmniWM executable (installed via Homebrew cask).";
    };

    settings = lib.mkOption {
      type = lib.types.submodule {
        freeformType = format.type;

        options = {
          general = {
            hotkeysEnabled = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enable keyboard shortcuts.";
            };
            systemHyperTrigger = lib.mkOption {
              type = lib.types.str;
              default = "none";
              description = "System-level hyper trigger key.";
              example = "capsLock";
            };
            defaultLayoutType = lib.mkOption {
              type = lib.types.enum [ "niri" "dwindle" ];
              default = "niri";
              description = "Default layout type for new workspaces.";
            };
            preventSleepEnabled = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Prevent system sleep while OmniWM is running.";
            };
            updateChecksEnabled = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Check for updates on launch.";
            };
            ipcEnabled = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enable the IPC server (required for omniwmctl).";
            };
            spacesTrackingEnabled = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Track macOS Spaces for native fullscreen and inactive space suppression.";
            };
            animationsEnabled = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enable window and viewport animations.";
            };
          };

          focus = {
            followsMouse = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Focus follows mouse movement.";
            };
            moveMouseToFocusedWindow = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Move mouse cursor to the focused window.";
            };
            followsWindowToMonitor = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Move focus to the monitor of the focused window.";
            };
            crossesMonitorAtEdge = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Focus crosses to the next monitor at screen edge.";
            };
          };

          mouseWarp = {
            monitorOrder = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Preferred monitor order for mouse warping.";
              example = [ "Built-in Retina Display" "DELL U2723QE" ];
            };
            axis = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Mouse warp axis (horizontal or vertical).";
            };
            margin = lib.mkOption {
              type = lib.types.int;
              default = 0;
              description = "Margin before mouse warp triggers.";
            };
          };

          gaps = {
            size = lib.mkOption {
              type = lib.types.number;
              default = 8.0;
              description = "Inner gap size between windows.";
            };
            outer = {
              left = lib.mkOption {
                type = lib.types.number;
                default = 8.0;
                description = "Outer gap on the left edge.";
              };
              right = lib.mkOption {
                type = lib.types.number;
                default = 8.0;
                description = "Outer gap on the right edge.";
              };
              top = lib.mkOption {
                type = lib.types.number;
                default = 8.0;
                description = "Outer gap on the top edge.";
              };
              bottom = lib.mkOption {
                type = lib.types.number;
                default = 8.0;
                description = "Outer gap on the bottom edge.";
              };
            };
          };

          niri = {
            maxVisibleColumns = lib.mkOption {
              type = lib.types.int;
              default = 4;
              description = "Maximum visible columns in Niri layout.";
            };
            infiniteLoop = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Infinite loop scrolling for columns.";
            };
            centerFocusedColumn = lib.mkOption {
              type = lib.types.enum [ "never" "always" "onOverflow" ];
              default = "never";
              description = "When to center the focused column.";
            };
            alwaysCenterSingleColumn = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Always center a single column.";
            };
            singleWindowAspectRatio = lib.mkOption {
              type = lib.types.str;
              default = "disabled";
              description = "Single-window fit mode (disabled, fit, or aspect ratio like 16/9).";
              example = "16/9";
            };
            columnWidthPresets = lib.mkOption {
              type = lib.types.nullOr (lib.types.listOf lib.types.number);
              default = null;
              description = "Column width presets as fractions of available space.";
            };
            defaultColumnWidth = lib.mkOption {
              type = lib.types.nullOr lib.types.number;
              default = null;
              description = "Default column width as a fraction of available space.";
            };
          };

          dwindle = {
            smartSplit = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Smart split orientation (chooses based on aspect ratio).";
            };
            defaultSplitRatio = lib.mkOption {
              type = lib.types.number;
              default = 0.5;
              description = "Default split ratio.";
            };
            splitWidthMultiplier = lib.mkOption {
              type = lib.types.number;
              default = 1.0;
              description = "Split width multiplier.";
            };
            singleWindowAspectRatio = lib.mkOption {
              type = lib.types.str;
              default = "disabled";
              description = "Single-window fit aspect ratio.";
            };
            useGlobalGaps = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Use global gap settings.";
            };
            moveToRootStable = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Preserve window positions when moving to root.";
            };
          };

          borders = {
            enabled = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enable window focus borders.";
            };
            width = lib.mkOption {
              type = lib.types.number;
              default = 4.0;
              description = "Focus border width in points.";
            };
            color = {
              red = lib.mkOption {
                type = lib.types.number;
                default = 0.5;
                description = "Border red color component (0-1).";
              };
              green = lib.mkOption {
                type = lib.types.number;
                default = 0.8;
                description = "Border green color component (0-1).";
              };
              blue = lib.mkOption {
                type = lib.types.number;
                default = 1.0;
                description = "Border blue color component (0-1).";
              };
              alpha = lib.mkOption {
                type = lib.types.number;
                default = 1.0;
                description = "Border alpha/opacity (0-1).";
              };
            };
          };

          workspaceBar = {
            enabled = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enable the built-in workspace bar.";
            };
            showLabels = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Show workspace labels in the bar.";
            };
            showFloatingWindows = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Show floating windows in the bar.";
            };
            windowLevel = lib.mkOption {
              type = lib.types.enum [ "popup" "statusBar" "floating" ];
              default = "popup";
              description = "Window level of the bar.";
            };
            position = lib.mkOption {
              type = lib.types.enum [
                "overlappingMenuBar"
                "underMenuBar"
                "floating"
              ];
              default = "overlappingMenuBar";
              description = "Bar position relative to the menu bar.";
            };
            notchAware = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Avoid the notch on MacBooks.";
            };
            deduplicateAppIcons = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Deduplicate app icons (one icon per app, not per window).";
            };
            hideEmptyWorkspaces = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Hide workspaces with no open windows.";
            };
            reserveLayoutSpace = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Reserve space for the bar in the layout engine.";
            };
            height = lib.mkOption {
              type = lib.types.number;
              default = 32.0;
              description = "Bar height in points.";
            };
            backgroundOpacity = lib.mkOption {
              type = lib.types.number;
              default = 0.85;
              description = "Bar background opacity (0-1).";
            };
            xOffset = lib.mkOption {
              type = lib.types.number;
              default = 0.0;
              description = "Horizontal offset from the default position.";
            };
            yOffset = lib.mkOption {
              type = lib.types.number;
              default = 0.0;
              description = "Vertical offset from the default position.";
            };
            labelFontSize = lib.mkOption {
              type = lib.types.number;
              default = 12.0;
              description = "Font size for workspace labels.";
            };
            accentColor = lib.mkOption {
              type = lib.types.nullOr (lib.types.submodule {
                options = {
                  red = lib.mkOption { type = lib.types.number; default = 0.5; };
                  green = lib.mkOption { type = lib.types.number; default = 0.8; };
                  blue = lib.mkOption { type = lib.types.number; default = 1.0; };
                  alpha = lib.mkOption { type = lib.types.number; default = 1.0; };
                };
              });
              default = null;
              description = "Accent color for the workspace bar (null = use theme default).";
            };
            textColor = lib.mkOption {
              type = lib.types.nullOr (lib.types.submodule {
                options = {
                  red = lib.mkOption { type = lib.types.number; default = 1.0; };
                  green = lib.mkOption { type = lib.types.number; default = 1.0; };
                  blue = lib.mkOption { type = lib.types.number; default = 1.0; };
                  alpha = lib.mkOption { type = lib.types.number; default = 1.0; };
                };
              });
              default = null;
              description = "Text color for the workspace bar (null = use theme default).";
            };
          };

          gestures = {
            scrollEnabled = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enable scroll gestures.";
            };
            scrollSensitivity = lib.mkOption {
              type = lib.types.number;
              default = 1.0;
              description = "Scroll gesture sensitivity multiplier.";
            };
            scrollModifierKey = lib.mkOption {
              type = lib.types.enum [ "option" "shift" "command" "optionShift" ];
              default = "optionShift";
              description = "Modifier key for scroll gestures.";
            };
            mouseResizeModifierKey = lib.mkOption {
              type = lib.types.enum [ "option" "shift" "command" ];
              default = "option";
              description = "Modifier key for mouse resize.";
            };
            fingerCount = lib.mkOption {
              type = lib.types.int;
              default = 3;
              description = "Number of fingers for trackpad gestures.";
            };
            invertDirection = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Invert gesture direction.";
            };
            trackpadScrollStyle = lib.mkOption {
              type = lib.types.enum [ "snap" "smooth" ];
              default = "snap";
              description = "Trackpad scroll style.";
            };
          };

          statusBar = {
            showWorkspaceName = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Show workspace name in the menu bar.";
            };
            showAppNames = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Show app names in the menu bar.";
            };
            useWorkspaceId = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Use workspace ID instead of display name in the menu bar.";
            };
          };

          clipboard = {
            historyEnabled = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enable clipboard history.";
            };
            maxItems = lib.mkOption {
              type = lib.types.int;
              default = 50;
              description = "Maximum clipboard history items.";
            };
            maxItemBytes = lib.mkOption {
              type = lib.types.int;
              default = 1048576;
              description = "Maximum bytes per clipboard item (default 1 MB).";
            };
            maxTotalBytes = lib.mkOption {
              type = lib.types.int;
              default = 20971520;
              description = "Maximum total bytes for the clipboard store (default 20 MB).";
            };
          };

          quakeTerminal = {
            enabled = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enable the Quake terminal.";
            };
            position = lib.mkOption {
              type = lib.types.enum [ "top" "bottom" "left" "right" "center" ];
              default = "center";
              description = "Quake terminal position on screen.";
            };
            widthPercent = lib.mkOption {
              type = lib.types.number;
              default = 0.7;
              description = "Quake terminal width as a fraction of screen width.";
            };
            heightPercent = lib.mkOption {
              type = lib.types.number;
              default = 0.5;
              description = "Quake terminal height as a fraction of screen height.";
            };
            animationDuration = lib.mkOption {
              type = lib.types.number;
              default = 0.2;
              description = "Slide-in/out animation duration in seconds.";
            };
            autoHide = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Auto-hide the Quake terminal when focus is lost.";
            };
            opacity = lib.mkOption {
              type = lib.types.nullOr lib.types.number;
              default = null;
              description = "Terminal background opacity (null = use default).";
            };
            monitorMode = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Monitor selection mode for the Quake terminal.";
            };
          };

          appearance = {
            mode = lib.mkOption {
              type = lib.types.enum [ "dark" "light" "system" ];
              default = "dark";
              description = "Appearance mode.";
            };
          };

          hotkeys = lib.mkOption {
            type = lib.types.listOf (lib.types.submodule {
              options = {
                id = lib.mkOption {
                  type = lib.types.str;
                  description = "Unique command identifier.";
                };
                command = lib.mkOption {
                  type = lib.types.str;
                  description = "Command action string.";
                };
                binding = {
                  modifiers = lib.mkOption {
                    type = lib.types.listOf (lib.types.enum [
                      "option" "shift" "control" "command" "function"
                    ]);
                    default = [ ];
                    description = "Modifier keys for this binding.";
                  };
                  key = lib.mkOption {
                    type = lib.types.str;
                    default = "";
                    description = "Key for this binding.";
                  };
                };
              };
            });
            default = [ ];
            description = "Custom hotkey bindings override defaults.";
          };

          workspaces = lib.mkOption {
            type = lib.types.listOf (lib.types.submodule {
              options = {
                name = lib.mkOption {
                  type = lib.types.str;
                  description = "Workspace ID (used as the raw workspace name).";
                };
                displayName = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "Human-readable display name (supports emoji).";
                };
                layoutType = lib.mkOption {
                  type = lib.types.nullOr (lib.types.enum [
                    "defaultLayout" "niri" "dwindle"
                  ]);
                  default = null;
                  description = "Layout type for this workspace (null = use default).";
                };
                monitorAssignment = lib.mkOption {
                  type = lib.types.nullOr (lib.types.enum [
                    "main" "secondary" "focused"
                  ]);
                  default = null;
                  description = "Monitor assignment for this workspace.";
                };
              };
            });
            default = [ ];
            description = "Workspace configurations.";
            example = [
              { name = "1"; displayName = "1 "; }
              { name = "2"; displayName = "2 "; }
              { name = "3"; displayName = "3 "; }
            ];
          };

          appRules = lib.mkOption {
            type = lib.types.listOf (lib.types.submodule {
              options = {
                bundleId = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "Application bundle identifier.";
                  example = "com.apple.finder";
                };
                appNameSubstring = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "Match app name containing this substring.";
                };
                titleSubstring = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "Match window title containing this substring.";
                };
                titleRegex = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "Match window title against this regex pattern.";
                };
                layout = lib.mkOption {
                  type = lib.types.nullOr (lib.types.enum [ "auto" "tile" "float" ]);
                  default = null;
                  description = "Layout behavior for matching windows.";
                };
                assignToWorkspace = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "Assign matching windows to this workspace.";
                };
                minWidth = lib.mkOption {
                  type = lib.types.nullOr lib.types.number;
                  default = null;
                  description = "Minimum window width in points.";
                };
                minHeight = lib.mkOption {
                  type = lib.types.nullOr lib.types.number;
                  default = null;
                  description = "Minimum window height in points.";
                };
              };
            });
            default = [ ];
            description = "Per-application window rules.";
            example = [
              {
                bundleId = "com.apple.finder";
                layout = "float";
              }
            ];
          };
        };
      };
      default = { };
      example = {
        general = {
          ipcEnabled = true;
          defaultLayoutType = "niri";
        };
        gaps = {
          size = 8.0;
          outer = { left = 8; right = 8; top = 8; bottom = 8; };
        };
      };
      description = ''
        OmniWM configuration, written to
        <filename>~/.config/omniwm/settings.toml</filename>.
        See <link xlink:href="https://github.com/BarutSRB/OmniWM"/> for
        all supported values.
      '';
    };

    enableConfigManagement = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Automatically manage <filename>~/.config/omniwm/settings.toml</filename>
        via an activation script. When disabled, you must place the config yourself.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Write config to ~/.config/omniwm/settings.toml via activation script
    # so omniwm (a GUI app installed via homebrew cask) finds it at its
    # fixed path.  The config is live-reloaded by omniwm on save.
    system.activationScripts.omniwmConfig = lib.mkIf cfg.enableConfigManagement (
      let
        primaryUser = config.system.primaryUser;
      in
      {
        text = ''
          echo "writing omniwm config for user '${primaryUser}'..." >&2

          CONFIG_DIR="/Users/${primaryUser}/.config/omniwm"
          mkdir -p "$CONFIG_DIR"

          # Symlink the Nix-generated TOML to the fixed config path.
          # OmniWM live-reloads this file, so darwin-rebuild replaces it atomically.
          ln -sfn "${configFile}" "$CONFIG_DIR/settings.toml"
        '';
        deps = [ ];
      }
    );

    # Assertions
    assertions = lib.optional cfg.enableConfigManagement [
      {
        assertion = config.system.primaryUser != null;
        message = ''
          services.omniwm requires `system.primaryUser` to be set so the config
          file can be placed in the correct home directory.
        '';
      }
    ];
  };
}
