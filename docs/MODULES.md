# Modules Architecture

This directory contains both **NixOS modules** (system-level) and **home-manager modules** (user-level) in a coordinated structure.

## Directory Structure

```
modules/
├── nixos/              # System-level NixOS modules
│   ├── core/           # Boot, nix settings, locale
│   ├── hardware/       # AMD, NVIDIA, audio, bluetooth
│   ├── desktop/        # GNOME, Plasma system configuration
│   ├── networking/     # Network, bridge, Tailscale
│   ├── services/       # SSH, printing, btrbk
│   ├── security/       # SOPS, base security
│   ├── virtualization/ # Docker, libvirt
│   ├── vfio/           # GPU passthrough, dual-boot
│   ├── vms/            # Declarative VMs
│   └── impermanence/   # Ephemeral root
│
└── home/               # User-level home-manager modules (shared)
    └── desktop/        # Desktop environment user configuration
        ├── gnome/      # GNOME user settings (dconf, apps)
        └── plasma/     # Plasma user settings (plasma-manager)
```

## How It Works

### NixOS Modules (`modules/nixos/`)

**Purpose**: System-level configuration that affects all users

**Usage**: Automatically imported in `lib/default.nix` mkHost function

**Example**: Enable GNOME desktop system-wide
```nix
# In hosts/toaster/default.nix
modules.desktop.gnome.enable = true;
```

This enables:
- GDM display manager
- GNOME packages and services
- Wayland session configuration
- System-wide GNOME settings

### Home-Manager Modules (`modules/home/`)

**Purpose**: Shared user-level configuration that can be used by any user

**Usage**: Imported in user's home configuration

**Example**: Enable GNOME for a specific user
```nix
# In users/draxel/home/default.nix
{ config, pkgs, inputs, modules, ... }:

{
  imports = [
    "${modules}/desktop"  # Shorthand for shared home modules
  ];

  modules.home.desktop = {
    gnome.enable = true;  # Enable GNOME user configuration
    # plasma.enable = true;  # Or enable Plasma instead
    ensureSystemDesktop = true;  # Warns if system GNOME is not enabled
  };
}
```

**Note**: The `modules` variable is automatically provided via `extraSpecialArgs` and points to `modules/home/`, eliminating the need for relative paths like `../../../modules/home/`.

This configures:
- User-specific dconf settings (wallpaper, theme, shortcuts)
- User applications (gnome-tweaks, extension-manager)
- Cursor theme and terminal configuration
- Personal keybindings and preferences

## Coordination Between System and User

The `modules.home.desktop` module includes coordination logic that:

1. **Checks system configuration**: Uses `osConfig` to verify the matching system module is enabled
2. **Shows warnings**: If user enables GNOME but system GNOME is not enabled, shows a helpful warning
3. **Prevents conflicts**: Ensures user doesn't configure a desktop that isn't installed system-wide

### Example Warning

If you enable Plasma in home-manager but forgot to enable it system-wide:

```
warning: Home-manager Plasma configuration is enabled for this user, but
system-level Plasma (modules.desktop.plasma.enable) is not enabled.

Add to your host configuration:
  modules.desktop.plasma.enable = true;
```

## User-Specific Overrides

Users can override shared modules with their own configurations:

### Structure

```
users/draxel/home/
├── default.nix         # Imports shared modules
└── desktop/
    ├── default.nix     # User-specific desktop overrides (optional)
    ├── fonts.nix       # User-specific fonts
    ├── gtk.nix         # User-specific GTK theme
    └── qt.nix          # User-specific Qt theme
```

### How to Override

1. **Use shared modules by default**:
```nix
# users/draxel/home/default.nix
imports = [
  ../../../modules/home/desktop  # Shared GNOME/Plasma config
];

modules.home.desktop.environment = "gnome";
```

2. **Add user-specific overrides** (optional):
```nix
# users/draxel/home/default.nix
imports = [
  ../../../modules/home/desktop
  ./desktop  # User-specific overrides
];

# Shared config
modules.home.desktop.environment = "gnome";

# In users/draxel/home/desktop/default.nix:
# Override wallpaper
dconf.settings."org/gnome/desktop/background".picture-uri =
  "file:///home/draxel/Pictures/my-wallpaper.png";
```

## Multi-User Example

### User 1 (draxel) - GNOME with custom settings

```nix
# users/draxel/home/default.nix
imports = [ ../../../modules/home/desktop ];

modules.home.desktop = {
  enable = true;
  environment = "gnome";
};

# Custom wallpaper in user-specific desktop/default.nix
```

### User 2 (bamse) - Plasma with defaults

```nix
# users/bamse/home/default.nix
imports = [ ../../../modules/home/desktop ];

modules.home.desktop = {
  enable = true;
  environment = "plasma";
};

# Uses shared Plasma config, no overrides needed
```

### System Configuration

```nix
# hosts/honeypot/default.nix
modules.desktop.plasma.enable = true;  # Both users can use Plasma

# OR for different desktops:
modules.desktop.gnome.enable = true;   # draxel uses GNOME
modules.desktop.plasma.enable = true;  # bamse uses Plasma
```

## Benefits

1. **DRY (Don't Repeat Yourself)**: Desktop configurations defined once, reused by all users
2. **Consistency**: All users get the same base configuration
3. **Flexibility**: Users can override specific settings without duplicating entire configs
4. **Safety**: Automatic warnings prevent misconfigurations
5. **Scalability**: Easy to add new users with consistent setups
6. **Maintainability**: Update shared config once, all users benefit

## Migration from Old Structure

### Old Structure (before)
```
modules/
├── core/
├── desktop/
├── hardware/
└── ...

users/draxel/home/desktop/
├── default.nix  (custom selector)
├── gnome/default.nix
└── plasma/default.nix
```

### New Structure (after)
```
modules/
├── nixos/      (system modules)
│   ├── core/
│   ├── desktop/
│   └── ...
└── home/       (shared user modules)
    └── desktop/
        ├── default.nix (shared selector with coordination)
        ├── gnome/
        └── plasma/

users/draxel/home/
├── default.nix (imports shared modules)
└── desktop/    (optional user overrides)
```

### Migration Steps

1. System modules moved to `modules/nixos/`
2. Shared user modules created in `modules/home/`
3. User configs now import shared modules
4. User-specific `desktop/` becomes optional overrides
5. Added coordination logic to prevent misconfigurations

## Adding New Shared Modules

To add a new shared home-manager module:

1. Create module in `modules/home/`:
```bash
mkdir -p modules/home/shell
```

2. Create the module:
```nix
# modules/home/shell/default.nix
{ config, lib, pkgs, ... }:
{
  options.modules.home.shell = {
    enable = lib.mkEnableOption "shared shell configuration";
  };

  config = lib.mkIf config.modules.home.shell.enable {
    programs.zsh.enable = true;
    # ... shared shell config
  };
}
```

3. Import in user configs:
```nix
# users/draxel/home/default.nix
imports = [
  ../../../modules/home/shell
];

modules.home.shell.enable = true;
```

## Desktop Configuration: System vs User

Desktop environment configuration is split between system-level (NixOS) and user-level (home-manager).

### System-Level Desktop (NixOS)

Located in: `modules/nixos/desktop/`

Manages:
- Display manager (GDM, SDDM)
- Desktop environment installation (GNOME, Plasma packages)
- System services (gnome-keyring, kwalletd)
- Wayland/X11 session configuration

Example - Enable GNOME system-wide:
```nix
# hosts/toaster/default.nix
imports = [ modules.nixos.desktop.gnome ];

modules.desktop.gnome.enable = true;
```

### User-Level Desktop (Home-Manager)

Located in: `modules/home/desktop/`

Manages:
- User-specific settings (dconf for GNOME, plasma-manager for KDE)
- User applications and packages
- Keyboard shortcuts and keybindings
- Wallpapers and themes

Example - Configure GNOME for user:
```nix
# users/draxel/home/default.nix
imports = [ modules.home.desktop.gnome ];

# User-specific GNOME settings are in modules/home/desktop/gnome/
```

### User-Specific Desktop Overrides

Users can override shared desktop modules with personal customizations:

```nix
# users/draxel/home/desktop/default.nix (optional)
{ config, pkgs, ... }:

{
  # Override GNOME wallpaper
  dconf.settings."org/gnome/desktop/background".picture-uri =
    "file:///home/draxel/Pictures/custom.png";

  # Add user-specific desktop apps
  home.packages = with pkgs; [ inkscape blender ];
}
```

Then import it:
```nix
# users/draxel/home/default.nix
imports = [
  modules.home.desktop.gnome
  ./desktop  # Enable user-specific overrides
];
```

**Important**: User overrides **merge** with shared config - they don't replace it.

## See Also

- [ARCHITECTURE.md](ARCHITECTURE.md) - Complete architecture overview
- [VFIO.md](VFIO.md) - GPU passthrough guide
- [CHANGELOG.md](CHANGELOG.md) - Recent changes
