# Recent Configuration Changes

## Module Reorganization (December 31, 2025)

### Summary

Restructured the entire `modules/` directory to separate **system-level** (NixOS) and **user-level** (home-manager) modules with automatic coordination between them.

### What Changed

#### 1. Modules Directory Restructure

**Before:**
```
modules/
├── core/
├── desktop/
├── hardware/
├── networking/
└── ...
```

**After:**
```
modules/
├── nixos/          # System-level modules
│   ├── core/
│   ├── desktop/
│   ├── hardware/
│   └── ...
└── home/           # Shared user-level modules
    └── desktop/
        ├── gnome/
        ├── plasma/
        ├── fonts.nix
        ├── gtk.nix
        └── qt.nix
```

#### 2. Shared Home-Manager Desktop Module

Created `modules/home/desktop/` with:
- ✅ Shared GNOME configuration (dconf, apps, Bibata cursors)
- ✅ Shared Plasma configuration (plasma-manager, KDE apps)
- ✅ Common fonts, GTK, and Qt configurations
- ✅ Automatic validation that system desktop matches user desktop
- ✅ Helpful warnings if misconfigured

#### 3. User Configuration Simplification

**Before (draxel):**
```nix
# users/draxel/home/desktop/
├── default.nix  (custom selector)
├── gnome/default.nix  (draxel-specific)
├── plasma/default.nix  (draxel-specific)
├── fonts.nix
├── gtk.nix
└── qt.nix
```

**After (draxel):**
```nix
# Uses shared modules/home/desktop/
imports = [ ../../../modules/home/desktop ];

modules.home.desktop = {
  enable = true;
  environment = "gnome";
  ensureSystemDesktop = true;  # Validates system config
};

# Optional user overrides in users/draxel/home/desktop/
# (fonts, gtk, qt kept for potential customization)
```

#### 4. Automatic System Coordination

The new `modules.home.desktop` module includes coordination logic:

```nix
# If user enables Plasma but system Plasma is not enabled:
warning: Home-manager Plasma configuration is enabled for this user, but
system-level Plasma (modules.desktop.plasma.enable) is not enabled.

Add to your host configuration:
  modules.desktop.plasma.enable = true;
```

### Migration Steps Taken

1. ✅ Created `modules/nixos/` and `modules/home/` directories
2. ✅ Moved all system modules to `modules/nixos/`
3. ✅ Created shared desktop modules in `modules/home/desktop/`
4. ✅ Updated `lib/default.nix` to import from new paths
5. ✅ Updated draxel's config to use shared modules
6. ✅ Removed duplicate GNOME/Plasma configs from draxel's directory
7. ✅ Added plasma-manager to flake inputs
8. ✅ Created comprehensive documentation

### Benefits

1. **No Duplication**: Desktop configs defined once, used by all users
2. **Automatic Validation**: Prevents user/system desktop mismatches
3. **Multi-User Ready**: Easy to add new users with consistent configs
4. **Override Friendly**: Users can still customize without duplicating
5. **Type-Safe**: Uses NixOS module system properly
6. **Maintainable**: Update shared config once, all users benefit

### How to Use

#### For New Users

```nix
# users/newuser/home/default.nix
imports = [
  ../../../modules/home/desktop  # Shared desktop module
];

modules.home.desktop = {
  enable = true;
  environment = "plasma";  # or "gnome"
  ensureSystemDesktop = true;
};
```

#### For User-Specific Overrides

```nix
# users/draxel/home/desktop/default.nix
{ config, pkgs, ... }:

{
  # Override wallpaper
  dconf.settings."org/gnome/desktop/background".picture-uri =
    "file:///home/draxel/custom.png";

  # Add user-specific apps
  home.packages = with pkgs; [ inkscape ];
}
```

Then enable:
```nix
# users/draxel/home/default.nix
imports = [
  ./desktop  # Enable user overrides
];
```

### Files Updated

- `modules/` → reorganized into `modules/nixos/` and `modules/home/`
- `lib/default.nix` → updated module paths
- `users/draxel/home/default.nix` → imports shared desktop module
- `users/draxel/home/desktop/` → removed gnome/plasma subdirs
- `flake.nix` → added plasma-manager input

### Documentation Added

- `modules/README.md` → Complete modules architecture
- `modules/home/desktop/ARCHITECTURE.md` → Desktop coordination details
- `users/draxel/home/desktop/README.md` → User override guide
- `CHANGES.md` → This file

### Breaking Changes

⚠️ **None** - Existing configurations continue to work. The changes are backwards-compatible because:
- Module imports updated to new paths
- User configs updated to use shared modules
- Old desktop configs removed but functionality preserved in shared modules

### Next Steps

To apply to other users (e.g., bamse):

1. Update user's home config to import shared module:
   ```nix
   # users/bamse/home/default.nix
   imports = [ ../../../modules/home/desktop ];

   modules.home.desktop.environment = "plasma";
   ```

2. Remove duplicate desktop configs from user's directory

3. Optionally keep user-specific overrides in `users/bamse/home/desktop/`

## Other Recent Changes

### VFIO Configuration (toaster)

- ✅ Added NVIDIA RTX 5070 Ti configuration
- ✅ Configured NVIDIA PRIME (AMD 780M iGPU + NVIDIA dGPU)
- ✅ Enabled Windows 11 VM with GPU passthrough
- ✅ Set correct PCI IDs and addresses

### Desktop Enhancements

- ✅ Added Bibata Modern Classic cursor theme
- ✅ Added plasma-manager for full KDE Plasma configuration
- ✅ Created One Dark Pro theme for both GNOME Terminal and Konsole

### Meta Variables

- ✅ Enhanced `mkHost` to provide `meta` object to all modules
- ✅ Auto-derive hostname, stateVersion, and user list
- ✅ Updated all hosts to use meta for DRY configuration

### Module Improvements

- ✅ Made impermanence default to false
- ✅ Fixed hardware module imports (AMD, NVIDIA)
- ✅ Removed deprecated OVMF configuration
- ✅ Added insecure package permissions for qtwebengine

## See Also

- [modules/README.md](modules/README.md) - Complete modules documentation
- [modules/home/desktop/ARCHITECTURE.md](modules/home/desktop/ARCHITECTURE.md) - Desktop architecture
- [README.md](README.md) - Main repository documentation
