# NixOS Configuration Architecture Analysis & Recommendations

## Current Architecture Summary

Your configuration follows a well-structured pattern with:
- **~120+ .nix files** across NixOS modules (56), Home Manager modules (55), hosts (3), and users (2)
- **Custom `mkHost` function** in `lib/default.nix` that wires everything together
- **Explicit opt-in imports** - hosts must import modules they need
- **`modules.category.subcategory` namespace** for consistent option naming
- **User self-containment** - users are complete modules (NixOS account + Home Manager)

### Current Structure
```
flake.nix
├── lib/default.nix          # mkHost function + specialArgs injection
├── hosts/
│   ├── toaster/             # Gaming workstation
│   ├── honeypot/            # Pentest machine
│   └── nixos/               # Default config
├── modules/
│   ├── nixos/               # System-level (12 categories)
│   │   ├── system/          # boot, locale, nix, users
│   │   ├── desktop/         # display managers, DEs
│   │   ├── hardware/        # nvidia, amd, audio, bluetooth
│   │   ├── gaming/          # steam, lutris, vr
│   │   ├── networking/      # base, tailscale, firewall
│   │   ├── services/        # ollama, ssh, btrbk
│   │   ├── virtualization/  # docker, libvirt
│   │   ├── vfio/            # GPU passthrough
│   │   ├── security/        # sops
│   │   ├── impermanence/
│   │   ├── vms/
│   │   └── appearance/      # fonts (new)
│   └── home/                # User-level (5 categories)
│       ├── desktop/         # plasma, gnome, hyprland
│       ├── shell/           # zsh, starship, bat, etc.
│       ├── dev/             # git, rust, go, python
│       ├── editors/         # nixvim, vscode
│       └── apps/            # moonlight, steam, stremio
├── users/
│   ├── draxel/              # NixOS user + home/
│   └── bamse/               # Pentest user + home/
└── assets/                  # Wallpapers, profiles
```

---

## Identified Inconsistencies

### 1. Manual Module Registration
Every new module must be manually added to `lib/default.nix` specialArgs:
```nix
modules.nixos = {
  appearance.fonts = "${inputs.self}/modules/nixos/appearance/fonts.nix";
  # Must add every single module here manually
};
```
**Problem**: Easy to forget, causes runtime errors, high maintenance burden.

### 2. Inconsistent Home Manager Abstraction
- **NixOS modules**: Have `options.modules.*` + `lib.mkIf cfg.enable` pattern
- **Home Manager modules**: Directly configure programs (no options layer)

```nix
# NixOS (flexible)
modules.gaming.steam = { enable = true; gamemode = true; };

# Home Manager (hardcoded - can't toggle without removing import)
imports = [ modules.home.shell.zsh ];
```

### 3. Mixed File/Directory Module Conventions
- `modules/nixos/hardware/nvidia.nix` - single file
- `modules/nixos/system/boot/` - directory with default.nix
- No naming convention to distinguish

### 4. Category Sprawl
12 NixOS categories, some with only 1-2 modules:
- `appearance/` (1 module)
- `impermanence/` (1 module)
- Could be consolidated

### 5. No Auto-Discovery
Modules must be explicitly imported AND registered in specialArgs. Double maintenance.

---

## Alternative Approaches Considered

### Option A: Incremental Improvements (Conservative)

Keep current architecture but fix inconsistencies:

1. **Auto-register modules** using a recursive file scanner
2. **Standardize Home Manager modules** with options layer
3. **Consolidate small categories**
4. **Document naming conventions** in ARCHITECTURE.md

### Option B: Adopt Snowfall Lib (Opinionated Framework)

Snowfall enforces structure and auto-discovers modules:

```
flake.nix (uses snowfall-lib)
├── systems/x86_64-linux/
│   ├── toaster/default.nix
│   └── honeypot/default.nix
├── modules/nixos/
│   └── auto-discovered/
├── modules/home/
│   └── auto-discovered/
├── homes/x86_64-linux/
│   ├── draxel@toaster/default.nix
│   └── bamse@honeypot/default.nix
└── packages/
```

**Pros**: Auto-discovery, consistent patterns, active community
**Cons**: Learning curve, rigid structure, migration effort

### Option C: Flake-Parts Integration (Modular)

Use flake-parts for flake-level organization while keeping current module structure:

```nix
# flake.nix
{
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [ ./hosts ./modules ./users ];
    };
}
```

**Pros**: Cleaner flake.nix, per-system handling, modular
**Cons**: Another abstraction layer

### Option D: Constellation Pattern (Recommended for Scale)

Best for 5+ hosts. Modules auto-apply based on options, not imports:

```nix
# All modules always imported, but conditionally activate
modules.roles.workstation.enable = true;  # enables: desktop, gaming, audio
modules.roles.server.enable = true;       # enables: minimal, headless
```

**Pros**: Minimal per-host config, role-based composition
**Cons**: Requires refactoring all modules

---

## Recommended Approach: Hybrid Incremental + Roles

Based on current scale and desire for future scalability, the recommended approach is a **hybrid** that keeps the custom structure but adds the best features from frameworks:

### Architecture Goal

```
flake.nix
├── lib/
│   ├── default.nix          # mkHost (simplified)
│   ├── modules.nix           # Auto-discovery for modules.nixos/home
│   └── roles.nix             # Role definitions
├── hosts/
│   └── toaster/default.nix   # Just: imports + role = "workstation"
├── modules/
│   ├── nixos/
│   │   ├── roles/            # NEW: Role aggregators
│   │   │   ├── workstation.nix   # Enables: desktop, gaming, audio, etc.
│   │   │   ├── server.nix        # Enables: headless, ssh, etc.
│   │   │   └── minimal.nix       # Base for all
│   │   ├── system/           # Core system (always loaded)
│   │   ├── desktop/          # Display + DE
│   │   ├── hardware/         # GPU, audio, storage
│   │   ├── gaming/           # Steam, VR, etc.
│   │   ├── services/         # SSH, btrbk, ollama
│   │   ├── virtualization/   # Docker, libvirt, VFIO
│   │   └── security/         # SOPS, etc.
│   └── home/
│       ├── profiles/         # NEW: User profiles
│       │   ├── developer.nix     # dev tools, editors, git
│       │   └── desktop.nix       # DE config, shell
│       ├── shell/
│       ├── dev/
│       ├── editors/
│       └── apps/
└── users/
    └── draxel/
        └── home/default.nix  # Just: profile = "developer"
```

---

## Implementation Plan

### Step 1: Auto-Discovery System
**Files to create/modify:**
- `lib/modules.nix` - Recursive scanner for modules

```nix
# lib/modules.nix
{ lib, inputs }:
let
  # Recursively build module paths from directory structure
  discoverModules = dir: prefix:
    lib.mapAttrs' (name: type:
      let path = "${dir}/${name}"; in
      if type == "directory" then
        lib.nameValuePair name (discoverModules path "${prefix}${name}/")
      else if lib.hasSuffix ".nix" name && name != "default.nix" then
        lib.nameValuePair (lib.removeSuffix ".nix" name) path
      else
        null
    ) (lib.filterAttrs (n: t: t == "directory" || (t == "regular" && lib.hasSuffix ".nix" n))
       (builtins.readDir dir));
in {
  nixos = discoverModules "${inputs.self}/modules/nixos" "";
  home = discoverModules "${inputs.self}/modules/home" "";
}
```

### Step 2: Role System for NixOS
**Files to create:**
- `modules/nixos/roles/default.nix`
- `modules/nixos/roles/workstation.nix`
- `modules/nixos/roles/server.nix`
- `modules/nixos/roles/minimal.nix`

```nix
# modules/nixos/roles/workstation.nix
{ config, lib, ... }:
let cfg = config.modules.roles.workstation;
in {
  options.modules.roles.workstation.enable = lib.mkEnableOption "workstation role";

  config = lib.mkIf cfg.enable {
    # Enable all workstation-related modules
    modules.desktop.plasma.enable = lib.mkDefault true;
    modules.hardware.audio.enable = lib.mkDefault true;
    modules.hardware.bluetooth.enable = lib.mkDefault true;
    modules.gaming.steam.enable = lib.mkDefault true;
    # ... etc
  };
}
```

### Step 3: Home Manager Options Layer
**Files to modify:**
- `modules/home/shell/zsh/default.nix` (add options)
- `modules/home/dev/git.nix` (add options)
- Other frequently-configured modules

```nix
# Pattern for HM modules with options
{ config, lib, pkgs, ... }:
let cfg = config.modules.home.shell.zsh;
in {
  options.modules.home.shell.zsh = {
    enable = lib.mkEnableOption "Zsh shell configuration";
    plugins = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "git" "docker" "kubectl" ];
    };
  };

  config = lib.mkIf cfg.enable {
    programs.zsh = {
      enable = true;
      # Use cfg.plugins, etc.
    };
  };
}
```

### Step 4: User Profiles
**Files to create:**
- `modules/home/profiles/developer.nix`
- `modules/home/profiles/desktop.nix`

```nix
# modules/home/profiles/developer.nix
{ config, lib, ... }:
let cfg = config.modules.home.profiles.developer;
in {
  options.modules.home.profiles.developer.enable = lib.mkEnableOption "developer profile";

  config = lib.mkIf cfg.enable {
    modules.home.shell.zsh.enable = lib.mkDefault true;
    modules.home.dev.git.enable = lib.mkDefault true;
    modules.home.editors.nixvim.enable = lib.mkDefault true;
    # ... etc
  };
}
```

### Step 5: Simplify Host Configs
**Result:** Host configs become minimal

```nix
# hosts/toaster/default.nix (after refactor)
{ config, modules, ... }:
{
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
    modules.nixos.roles.workstation
  ];

  # Role-based: one line enables everything
  modules.roles.workstation.enable = true;

  # Only override what's different from defaults
  modules.hardware.nvidia = {
    enable = true;
    prime.mode = "sync";
  };

  modules.vfio.dualBoot.enable = true;
}
```

### Step 6: Category Consolidation
**Merge small categories:**
- `appearance/` → `modules/nixos/desktop/appearance/`
- `impermanence/` → `modules/nixos/system/impermanence.nix`

---

## Verification

After implementation:
1. `nix flake check` passes
2. New modules auto-discovered without manual registration
3. `modules.roles.workstation.enable = true` enables expected modules
4. User profiles work: `modules.home.profiles.developer.enable = true`
5. Existing host configs still work (backward compatible)

---

## Migration Strategy

1. **Phase 1** (non-breaking): Add `lib/modules.nix`, roles, profiles alongside existing
2. **Phase 2** (optional): Migrate hosts to use roles
3. **Phase 3** (optional): Migrate users to use profiles
4. **Phase 4** (cleanup): Remove manual specialArgs registration

---

## Key Architectural Principles Preserved

1. **Explicit opt-in** - Roles are opt-in, individual modules still importable
2. **`modules.*` namespace** - Unchanged
3. **User self-containment** - Users remain portable
4. **Metadata injection** - `meta.*` still available everywhere
5. **Separation of concerns** - NixOS vs Home Manager clear
6. **NEW: Auto-discovery** - No more manual module registration
7. **NEW: Role composition** - Workstation enables 10+ modules with one line

---

## Comparison Table

| Approach | Effort | Auto-Discovery | Flexibility | Migration |
|----------|--------|----------------|-------------|-----------|
| Current (no change) | None | Manual | High | N/A |
| Option A (Incremental) | Low | Partial | High | Minimal |
| Option B (Snowfall) | High | Full | Low | Full rewrite |
| Option C (Flake-parts) | Medium | None | Medium | Moderate |
| Option D (Constellation) | High | Full | Medium | Significant |
| **Recommended (Hybrid)** | Medium | Full | High | Incremental |

---

## Sources

- [NixOS & Flakes Book - Modularize Configuration](https://nixos-and-flakes.thiscute.world/nixos-with-flakes/modularize-the-configuration)
- [Organizing System Configs with NixOS - John's Codes](https://johns.codes/blog/organizing-system-configs-with-nixos)
- [How do you structure your NixOS configs? - NixOS Discourse](https://discourse.nixos.org/t/how-do-you-structure-your-nixos-configs/65851)
- [Snowfall Lib Documentation](https://snowfall.org/guides/lib/quickstart/)
- [Misterio77/nix-starter-configs](https://github.com/Misterio77/nix-starter-configs)
