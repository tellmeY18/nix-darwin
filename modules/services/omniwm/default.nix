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
              description = "System-level hyper trigger key (capsLock, f13-f20, or a modifier).";
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
              description = "Check for updates on launch (polls GitHub once per day).";
            };
            ipcEnabled = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enable the IPC server (required for omniwmctl).";
            };
            spacesTrackingEnabled = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Track macOS Spaces for native fullscreen detection and inactive-space suppression.";
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
              description = "Focus follows mouse movement (debounced).";
            };
            moveMouseToFocusedWindow = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Move the cursor to the focused window on focus change.";
            };
            followsWindowToMonitor = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Move focus to the monitor of the focused window.";
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
              type = lib.types.nullOr (lib.types.enum [ "horizontal" "vertical" ]);
              default = null;
              description = "Mouse warp axis.";
            };
            margin = lib.mkOption {
              type = lib.types.int;
              default = 0;
              description = "Margin in points before mouse warp triggers at screen edge.";
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
            maxWindowsPerColumn = lib.mkOption {
              type = lib.types.nullOr lib.types.int;
              default = null;
              description = "Maximum windows per column (null = unlimited).";
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
              description = "Single-window fit mode: disabled, fill, or an aspect ratio like 16/9 or 4:3.";
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
              description = "Smart split orientation (chooses based on rectangle aspect ratio).";
            };
            defaultSplitRatio = lib.mkOption {
              type = lib.types.number;
              default = 0.5;
              description = "Default split ratio (0-1).";
            };
            splitWidthMultiplier = lib.mkOption {
              type = lib.types.number;
              default = 1.0;
              description = "Split width multiplier for visual balance.";
            };
            singleWindowAspectRatio = lib.mkOption {
              type = lib.types.str;
              default = "fill";
              description = "Single-window fit: fill, disabled, or an aspect ratio.";
            };
            useGlobalGaps = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Use global gap settings (or per-monitor gaps).";
            };
            moveToRootStable = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Preserve window positions when moving to root split.";
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
              description = "Show workspace labels (display names) in the bar.";
            };
            showFloatingWindows = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Show floating window indicators in the bar.";
            };
            windowLevel = lib.mkOption {
              type = lib.types.enum [ "popup" "statusBar" "floating" ];
              default = "popup";
              description = "Window level of the bar.";
            };
            position = lib.mkOption {
              type = lib.types.enum [ "overlappingMenuBar" "underMenuBar" "floating" ];
              default = "overlappingMenuBar";
              description = "Bar position relative to the macOS menu bar.";
            };
            notchAware = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Avoid the notch on MacBooks.";
            };
            deduplicateAppIcons = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Show one icon per app (not one per window).";
            };
            hideEmptyWorkspaces = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Hide workspaces with no open windows.";
            };
            reserveLayoutSpace = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Reserve bar space in the layout engine so windows don't go under it.";
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
              description = "Horizontal offset from the default bar position.";
            };
            yOffset = lib.mkOption {
              type = lib.types.number;
              default = 0.0;
              description = "Vertical offset from the default bar position.";
            };
            labelFontSize = lib.mkOption {
              type = lib.types.number;
              default = 12.0;
              description = "Font size for workspace bar labels.";
            };
          };

          gestures = {
            scrollEnabled = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enable scroll-to-navigate-columns gesture.";
            };
            scrollSensitivity = lib.mkOption {
              type = lib.types.number;
              default = 1.0;
              description = "Scroll gesture sensitivity multiplier.";
            };
            scrollModifierKey = lib.mkOption {
              type = lib.types.enum [ "optionShift" "option" "shift" "command" "control" ];
              default = "optionShift";
              description = "Modifier key held for column scrolling.";
            };
            mouseResizeModifierKey = lib.mkOption {
              type = lib.types.enum [ "option" "shift" "command" ];
              default = "option";
              description = "Modifier key for mouse window resize.";
            };
            fingerCount = lib.mkOption {
              type = lib.types.int;
              default = 3;
              description = "Fingers for trackpad swipe gestures.";
            };
            invertDirection = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Invert the direction of scroll/gesture navigation.";
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
              description = "Show workspace name in OmniWM's menu bar icon.";
            };
            showAppNames = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Show app names in the menu bar.";
            };
            useWorkspaceId = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Use numeric workspace ID instead of the display name.";
            };
          };

          clipboard = {
            historyEnabled = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enable clipboard history (accessible from command palette).";
            };
            maxItems = lib.mkOption {
              type = lib.types.int;
              default = 50;
              description = "Maximum items in clipboard history.";
            };
            maxItemBytes = lib.mkOption {
              type = lib.types.int;
              default = 1048576;
              description = "Maximum bytes per clipboard item.";
            };
            maxTotalBytes = lib.mkOption {
              type = lib.types.int;
              default = 20971520;
              description = "Maximum total bytes for clipboard history storage.";
            };
          };

          quakeTerminal = {
            enabled = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enable the Quake-style drop-down terminal (uses Ghostty).";
            };
            position = lib.mkOption {
              type = lib.types.enum [ "top" "bottom" "left" "right" "center" ];
              default = "center";
              description = "Screen position for the Quake terminal.";
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
              description = "Auto-hide the terminal when it loses focus.";
            };
            opacity = lib.mkOption {
              type = lib.types.nullOr lib.types.number;
              default = null;
              description = "Terminal background opacity (null = default).";
            };
            monitorMode = lib.mkOption {
              type = lib.types.nullOr (lib.types.enum [ "focusedWindow" "focusedMonitor" "mouse" ]);
              default = null;
              description = "Which monitor to show the terminal on.";
            };
          };

          appearance = {
            mode = lib.mkOption {
              type = lib.types.enum [ "dark" "light" ];
              default = "dark";
              description = "UI appearance mode.";
            };
          };

          # ── List options ────────────────────────────────────────────────
          # These use freeform list-of-attrs so the user writes them directly
          # in the TOML shape OmniWM expects.

          hotkeys = lib.mkOption {
            type = lib.types.listOf (lib.types.attrsOf lib.types.raw);
            default = [ ];
            description = ''
              Hotkey binding overrides. Each entry has:
              - `id`: command identifier (string)
              - `binding`: key combo string like "Command+1" or "Unassigned"
              See the OmniWM IPC-CLI docs for the full command list.
            '';
            example = lib.literalExpression ''
              [
                { id = "switchWorkspace.0"; binding = "Command+1"; }
                { id = "focus.left";         binding = "Command+H"; }
                { id = "focus.down";         binding = "Command+J"; }
                { id = "focus.up";           binding = "Command+K"; }
                { id = "focus.right";        binding = "Command+L"; }
              ]
            '';
          };

          workspaces = lib.mkOption {
            type = lib.types.listOf (lib.types.attrsOf lib.types.raw);
            default = [ ];
            description = ''
              Workspace configurations. Each entry has:
              - `name`: workspace ID (string, usually "1"-"9" or a named ID)
              - `layoutType`: "niri" or "dwindle"
              - `monitorAssignment`: { type = "main" | "secondary" | ... }
              - `id`: optional UUID (omitted to let OmniWM generate one)
            '';
            example = lib.literalExpression ''
              [
                { name = "1"; layoutType = "niri"; monitorAssignment = { type = "main"; }; }
                { name = "2"; layoutType = "niri"; monitorAssignment = { type = "main"; }; }
              ]
            '';
          };

          appRules = lib.mkOption {
            type = lib.types.listOf (lib.types.attrsOf lib.types.raw);
            default = [ ];
            description = ''
              Per-application window rules. Each entry can have:
              - `bundleId`: app bundle identifier
              - `layout`: "auto", "tile", or "float"
              - `assignToWorkspace`: workspace name
              - `minWidth` / `minHeight`: minimum window dimensions
              - `id`: optional UUID
            '';
            example = lib.literalExpression ''
              [
                { bundleId = "com.apple.finder"; layout = "float"; }
                { bundleId = "com.google.Chrome"; minWidth = 500.0; minHeight = 375.0; }
              ]
            '';
          };

          monitorBarOverrides = lib.mkOption {
            type = lib.types.listOf (lib.types.attrsOf lib.types.raw);
            default = [ ];
            description = "Per-monitor workspace bar overrides.";
          };

          monitorNiriOverrides = lib.mkOption {
            type = lib.types.listOf (lib.types.attrsOf lib.types.raw);
            default = [ ];
            description = "Per-monitor Niri layout overrides.";
          };

          monitorDwindleOverrides = lib.mkOption {
            type = lib.types.listOf (lib.types.attrsOf lib.types.raw);
            default = [ ];
            description = "Per-monitor Dwindle layout overrides.";
          };

          monitorOrientationOverrides = lib.mkOption {
            type = lib.types.listOf (lib.types.attrsOf lib.types.raw);
            default = [ ];
            description = "Per-monitor orientation overrides.";
          };

          monitorGapOverrides = lib.mkOption {
            type = lib.types.listOf (lib.types.attrsOf lib.types.raw);
            default = [ ];
            description = "Per-monitor gap overrides.";
          };
        };
      };
      default = { };
      example = lib.literalExpression ''
        {
          general = {
            ipcEnabled = true;
            defaultLayoutType = "niri";
          };
          gaps.size = 8.0;
          gaps.outer = { left = 3; right = 3; top = 3; bottom = 3; };
          workspaceBar.enabled = false;
        }
      '';
      description = ''
        OmniWM configuration, rendered to
        <filename>~/.config/omniwm/settings.toml</filename>.
        See <link xlink:href="https://github.com/BarutSRB/OmniWM"/> for
        all supported settings and the IPC-CLI reference.
      '';
    };

    enableConfigManagement = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Automatically manage <filename>~/.config/omniwm/settings.toml</filename>
        via an activation script. Disable if you prefer to manage the file
        through home-manager or manually.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    system.activationScripts.omniwmConfig = lib.mkIf cfg.enableConfigManagement (
      let
        primaryUser = config.system.primaryUser;
      in
      {
        text = ''
          echo "writing omniwm config for user '${primaryUser}'..." >&2

          CONFIG_DIR="/Users/${primaryUser}/.config/omniwm"
          mkdir -p "$CONFIG_DIR"

          # Symlink the Nix-generated TOML. OmniWM live-reloads this file,
          # so darwin-rebuild replaces it atomically. The store path is
          # read-only, which is fine — omniwm only reads it.
          ln -sfn "${configFile}" "$CONFIG_DIR/settings.toml"
        '';
      }
    );

    assertions = lib.optional cfg.enableConfigManagement {
      assertion = config.system.primaryUser != null;
      message = ''
        services.omniwm requires `system.primaryUser` to be set so the config
        file can be placed in the correct home directory.
        Set it with: system.primaryUser = "your-username";
      '';
    };
  };
}
