# NixOS Configuration Architecture

This document describes the complete architecture of this NixOS configuration.

## Directory Structure

```
.
├── docs/                  # Documentation
│   ├── ARCHITECTURE.md    # This file - complete architecture overview
│   ├── MODULES.md         # Modules system documentation
│   ├── VFIO.md           # VFIO/GPU passthrough guide
│   └── CHANGELOG.md       # Recent changes and migrations
│
├── flake.nix             # Flake definition and outputs
├── flake.lock            # Locked flake inputs
│
├── lib/                  # Shared library code
│   ├── default.nix       # mkHost function and module paths
│   └── libvirt.nix       # Libvirt helper functions
│
├── hosts/                # Per-host configurations
│   ├── toaster/          # Gaming/VFIO machine
│   ├── honeypot/         # Pentesting machine
│   └── nixos/            # Default/minimal config
│
├── users/                # Per-user configurations
│   ├── draxel/           # Primary user
│   ├── bamse/            # Secondary user
│   └── shared/           # Shared user configs
│
├── modules/              # NixOS and home-manager modules
│   ├── nixos/            # System-level modules
│   │   ├── system/       # Boot, nix, locale, users
│   │   ├── desktop/      # GNOME, Plasma, GDM, SDDM
│   │   ├── hardware/     # AMD, NVIDIA, audio, bluetooth
│   │   ├── networking/   # Base, bridge, tailscale, firewall
│   │   ├── services/     # SSH, printing, btrbk, packages
│   │   ├── security/     # Base security, SOPS
│   │   ├── virtualization/ # Docker, libvirt
│   │   ├── vfio/         # GPU passthrough (passthrough, dualBoot, lookingGlass, scream)
│   │   ├── vms/          # Declarative VMs
│   │   └── impermanence/ # Ephemeral root
│   │
│   └── home/             # User-level shared modules
│       ├── desktop/      # Desktop environment configs
│       │   ├── gnome/    # GNOME user settings
│       │   ├── plasma/   # Plasma user settings
│       │   └── common/   # Shared fonts, GTK, Qt
│       ├── shell/        # Shell configs (zsh, starship, fzf, etc.)
│       ├── dev/          # Development tools (git, lazygit)
│       ├── editors/      # Editors (neovim, vscode, claude-code)
│       └── apps/         # Applications (steam, moonlight, stremio)
│
└── scripts/              # Helper scripts
    └── nx.sh             # NixOS operations wrapper
```

## Core Concepts

### 1. Import-Based Pattern

This configuration uses an **import-based pattern** where hosts explicitly import only the modules they need:

```nix
# hosts/toaster/default.nix
imports = [
  modules.nixos.desktop.gnome
  modules.nixos.hardware.amd
  modules.nixos.hardware.nvidia
  # ... only what this host needs
];
```

Benefits:
- Clear dependencies
- No auto-loading overhead
- Easy to see what each host uses
- Prevents accidental module inclusion

### 2. System vs User Separation

Configuration is split between **system-level** (NixOS) and **user-level** (home-manager):

**System-level** (`modules/nixos/`):
- Affects all users on the system
- Requires sudo/root to apply
- Examples: display managers, desktop packages, hardware drivers

**User-level** (`modules/home/`):
- Per-user customization
- Can be applied without sudo
- Examples: dconf settings, user packages, personal keybindings

### 3. Meta Variables

The `mkHost` function in [lib/default.nix](../lib/default.nix) provides `meta` variables to all modules:

```nix
meta = {
  hostname = "toaster";
  stateVersion = "25.11";
  users = [ "draxel" ];
};
```

Modules can access these:
```nix
# Auto-derived hostname - no need to set manually
networking.hostName = meta.hostname;

# Auto-derived users list
modules.virtualization.docker.users = [ users.draxel ];
```

### 4. Module Paths

Modules are accessed through the `modules` variable provided to all configs:

```nix
# In host configs (NixOS modules)
imports = [
  modules.nixos.desktop.gnome
  modules.nixos.hardware.amd
];

# In user configs (home-manager modules)
imports = [
  modules.home.desktop.gnome
  modules.home.shell.zsh
];
```

## Configuration Flow

```
flake.nix
   ↓
lib/default.nix (mkHost function)
   ↓
┌──────────────────────────────────┐
│ Host Config (hosts/toaster/)     │
│                                  │
│ - Imports system modules         │
│ - Enables features               │
│ - Sets host-specific options     │
└──────────────────────────────────┘
   ↓
┌──────────────────────────────────┐
│ User Config (users/draxel/home/) │
│                                  │
│ - Imports user modules           │
│ - Sets user preferences          │
│ - Configures personal apps       │
└──────────────────────────────────┘
```

## Key Features

### VFIO GPU Passthrough

Modular GPU passthrough system with automatic boot configuration:

- **passthrough.nix**: Core VFIO setup (automatically handles IOMMU, kernel modules)
- **dualBoot**: Limine specializations for host vs VFIO modes
- **lookingGlass**: Low-latency VM display
- **scream**: Network audio passthrough

See [VFIO.md](VFIO.md) for details.

### Boot Configuration

Flexible boot system supporting multiple bootloaders:

```nix
modules.system.boot = {
  loader = "limine";  # or "systemd", "grub"
  maxGenerations = 10;
  timeout = 3;
};
```

### Declarative VMs

VMs defined in [modules/nixos/vms/](../modules/nixos/vms/):

```nix
virtualisation.vms.windows11 = {
  enable = true;
  cpu.cores = 8;
  memory = 16384;
  vfio.enable = true;  # Auto-derives PCI IDs from modules.vfio
};
```

## Module Options Pattern

Modules follow this pattern for configurability:

```nix
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.category.feature;
in
{
  options.modules.category.feature = {
    enable = lib.mkEnableOption "feature description";

    option1 = lib.mkOption {
      type = lib.types.str;
      default = "default-value";
      description = "What this option does";
    };
  };

  config = lib.mkIf cfg.enable {
    # Implementation when enabled
  };
}
```

This allows import-based pattern while keeping modules configurable:

```nix
# Import the module
imports = [ modules.nixos.hardware.nvidia ];

# Configure it
modules.hardware.nvidia = {
  enable = true;
  prime.enable = true;
  prime.offload = false;
};
```

## Common Workflows

### Adding a New Host

1. Create host directory: `mkdir -p hosts/newhost`
2. Create `default.nix` and `disko.nix`
3. Add to flake outputs in [flake.nix](../flake.nix)
4. Import needed modules explicitly
5. Set host-specific options

### Adding a New User

1. Create user directory: `mkdir -p users/newuser`
2. Create user module in `users/newuser/default.nix`
3. Create home config in `users/newuser/home/default.nix`
4. Add to flake outputs
5. Import shared home modules

### Creating a New Module

#### System Module

```bash
# Create module file
touch modules/nixos/category/feature.nix

# Add to lib/default.nix module paths
modules.nixos.category.feature = "${inputs.self}/modules/nixos/category/feature.nix";

# Import in host config
imports = [ modules.nixos.category.feature ];
```

#### User Module

```bash
# Create module file
mkdir -p modules/home/category
touch modules/home/category/feature.nix

# Add to lib/default.nix module paths
modules.home.category.feature = "${inputs.self}/modules/home/category/feature.nix";

# Import in user config
imports = [ modules.home.category.feature ];
```

## See Also

- [MODULES.md](MODULES.md) - Detailed modules documentation
- [VFIO.md](VFIO.md) - VFIO/GPU passthrough guide
- [CHANGELOG.md](CHANGELOG.md) - Recent changes and migrations
- [README.md](../README.md) - Quick start and overview
