# NixOS Configuration Architecture Design

A software engineering approach to designing maintainable, scalable NixOS configurations.

---

## Design Philosophy

This architecture applies established software engineering principles to NixOS configuration management:

1. **Separation of Concerns**: Each layer has a single, well-defined responsibility
2. **Dependency Inversion**: High-level policy depends on abstractions, not implementations
3. **Composition Over Inheritance**: Build systems by combining independent capabilities
4. **Explicit Over Implicit**: All behavior is visible and traceable
5. **Single Source of Truth**: Each piece of configuration lives in exactly one place

---

## Core Concepts

### Capabilities (Ports)

**Definition**: Abstract interfaces that define WHAT a system needs, not HOW to provide it.

**Purpose**:
- Declare system requirements in implementation-agnostic terms
- Define a contract that adapters must fulfill
- Enable swapping implementations without changing consumer code

**Characteristics**:
- Pure interface: no implementation details
- Typed options with sensible defaults
- Feature flags for optional functionality
- Adapter selection mechanism

**Example Capability**:
```nix
{
  options.capabilities.graphics = {
    enable = lib.mkEnableOption "graphics acceleration";

    features = {
      wayland = lib.mkEnableOption "Wayland compositor support";
      vulkan = lib.mkEnableOption "Vulkan graphics API";
      compute = lib.mkEnableOption "GPU compute (CUDA/OpenCL)";
    };

    adapter = lib.mkOption {
      type = lib.types.enum [ "nvidia" "amd" "intel" "auto" ];
      default = "auto";
      description = "GPU driver implementation to use";
    };
  };
}
```

### Adapters (Implementations)

**Definition**: Concrete implementations that fulfill capability contracts for specific hardware or software.

**Purpose**:
- Implement the HOW for each capability
- Contain all vendor/implementation-specific configuration
- Activate conditionally based on capability settings

**Characteristics**:
- Depends on capability options, not other adapters
- Self-contained: all related config in one place
- Conditional activation via `lib.mkIf`
- No knowledge of which host uses it

**Example Adapter**:
```nix
{ config, lib, pkgs, ... }:
let
  cap = config.capabilities.graphics;
  isSelected = cap.adapter == "nvidia" ||
               (cap.adapter == "auto" && detectNvidia);
in
lib.mkIf (cap.enable && isSelected) {
  hardware.nvidia = {
    modesetting.enable = true;
    open = lib.mkDefault true;
  };

  hardware.graphics.enable = cap.features.wayland || cap.features.vulkan;

  environment.systemPackages = lib.optionals cap.features.compute [
    pkgs.cudaPackages.cudatoolkit
  ];
}
```

### Profiles (Compositions)

**Definition**: Pre-composed sets of capabilities for common use cases.

**Purpose**:
- Reduce boilerplate for typical system configurations
- Document recommended capability combinations
- Provide sensible defaults that can be overridden

**Characteristics**:
- Enable capabilities, never set adapter-level config
- Use `lib.mkDefault` to allow overrides
- Single responsibility: one profile per use case
- Composable: profiles can be combined

**Example Profile**:
```nix
{ config, lib, ... }:
{
  options.profiles.workstation.enable =
    lib.mkEnableOption "desktop workstation profile";

  config = lib.mkIf config.profiles.workstation.enable {
    capabilities = {
      graphics = {
        enable = true;
        features.wayland = lib.mkDefault true;
        features.vulkan = lib.mkDefault true;
      };
      audio.enable = lib.mkDefault true;
      bluetooth.enable = lib.mkDefault true;
    };
  };
}
```

### Hosts (Configuration)

**Definition**: Machine-specific configuration that wires everything together.

**Purpose**:
- Select which profile(s) to use
- Override adapter choices for specific hardware
- Contain hardware-specific settings only

**Characteristics**:
- Minimal: most config comes from profiles
- Hardware-specific: PCI IDs, disk layouts, etc.
- Clear: easy to see what makes this host unique

**Example Host**:
```nix
{ config, ... }:
{
  imports = [ ./disko.nix ./hardware-configuration.nix ];

  # Select profile
  profiles.workstation.enable = true;

  # Override adapter for specific hardware
  capabilities.graphics = {
    adapter = "nvidia";
    features.compute = true;  # Enable CUDA
  };

  # Hardware-specific config only
  hardware.nvidia.prime = {
    mode = "sync";
    amdBusId = "PCI:13:0:0";
    nvidiaBusId = "PCI:1:0:0";
  };
}
```

---

## Directory Structure

```
flake.nix                      # Entry point
│
├── lib/                       # Framework code
│   ├── default.nix            # mkHost and utilities
│   └── discover.nix           # Auto-discovery functions
│
├── shells/                    # Development shells
│   ├── nix.nix                # Nix development (default)
│   └── <project>.nix          # Project-specific shells
│
├── packages/                  # Custom packages
│   └── <package>/default.nix  # Package derivations
│
├── overlays/                  # Nixpkgs overlays
│   └── <name>.nix             # Overlay definitions
│
├── core/                      # DOMAIN LAYER
│   │
│   ├── capabilities/          # Abstract interfaces
│   │   ├── default.nix        # Imports all capabilities
│   │   ├── graphics.nix       # GPU acceleration
│   │   ├── audio.nix          # Audio subsystem
│   │   ├── networking.nix     # Network configuration
│   │   ├── gaming.nix         # Gaming support
│   │   ├── development.nix    # Development tools
│   │   ├── virtualization.nix # VMs and containers
│   │   └── security.nix       # Security features
│   │
│   └── profiles/              # Capability compositions
│       ├── default.nix        # Imports all profiles
│       ├── minimal.nix        # Base system
│       ├── workstation.nix    # Desktop user
│       ├── server.nix         # Headless server
│       └── gaming.nix         # Gaming-focused
│
├── adapters/                  # IMPLEMENTATION LAYER
│   ├── default.nix            # Imports all adapters
│   │
│   ├── hardware/              # Hardware implementations
│   │   ├── nvidia.nix         # NVIDIA GPU
│   │   ├── amd.nix            # AMD GPU/CPU
│   │   ├── intel.nix          # Intel GPU
│   │   └── audio/
│   │       └── pipewire.nix   # PipeWire audio
│   │
│   ├── services/              # Service implementations
│   │   ├── ssh.nix            # SSH server
│   │   ├── tailscale.nix      # Tailscale VPN
│   │   └── docker.nix         # Container runtime
│   │
│   └── applications/          # Application implementations
│       ├── steam.nix          # Steam gaming
│       └── development.nix    # Dev tool suite
│
├── hosts/                     # CONFIGURATION LAYER
│   ├── default.nix            # Host definitions
│   │
│   ├── workstation/           # Example workstation
│   │   ├── default.nix        # Host config
│   │   └── disko.nix          # Disk layout
│   │
│   └── server/                # Example server
│       └── default.nix
│
├── home/                      # HOME MANAGER LAYER
│   │
│   ├── capabilities/          # User-level capabilities
│   │   ├── default.nix
│   │   ├── shell.nix          # Shell configuration
│   │   ├── editor.nix         # Editor configuration
│   │   └── desktop.nix        # Desktop environment
│   │
│   ├── adapters/              # User-level adapters
│   │   ├── default.nix
│   │   ├── zsh.nix            # Zsh implementation
│   │   ├── fish.nix           # Fish implementation
│   │   ├── neovim.nix         # Neovim implementation
│   │   └── vscode.nix         # VS Code implementation
│   │
│   └── profiles/              # User profiles
│       ├── default.nix
│       ├── developer.nix      # Developer setup
│       └── desktop.nix        # Desktop user setup
│
├── users/                     # USER DEFINITIONS
│   └── username/
│       └── default.nix        # Account + HM profile
│
└── tests/                     # VALIDATION LAYER
    ├── unit/                  # Module option tests
    └── integration/           # NixOS VM tests
```

---

## Module Patterns

### Capability Pattern

Every capability module follows this structure:

```nix
# core/capabilities/<name>.nix
{ lib, ... }:
{
  options.capabilities.<name> = {
    # Required: enable toggle
    enable = lib.mkEnableOption "<description>";

    # Optional: feature flags
    features = {
      <feature> = lib.mkEnableOption "<feature description>";
    };

    # Optional: adapter selection
    adapter = lib.mkOption {
      type = lib.types.enum [ "<adapter1>" "<adapter2>" "auto" ];
      default = "auto";
      description = "Implementation to use";
    };

    # Optional: configuration passed to adapter
    settings = lib.mkOption {
      type = lib.types.submodule { ... };
      default = {};
    };
  };

  # Capabilities define NO config - only options
}
```

### Adapter Pattern

Every adapter module follows this structure:

```nix
# adapters/<category>/<name>.nix
{ config, lib, pkgs, ... }:
let
  cap = config.capabilities.<capability>;

  # Determine if this adapter should activate
  shouldActivate = cap.enable && (
    cap.adapter == "<this-adapter>" ||
    (cap.adapter == "auto" && <detection-logic>)
  );
in
{
  # Adapters define ONLY config, no options
  config = lib.mkIf shouldActivate {
    # Implementation-specific configuration

    # Fulfill capability features
    <nixos-options> = lib.mkIf cap.features.<feature> { ... };

    # Use capability settings
    <nixos-options> = cap.settings.<setting>;
  };
}
```

### Profile Pattern

Every profile module follows this structure:

```nix
# core/profiles/<name>.nix
{ config, lib, ... }:
{
  options.profiles.<name>.enable =
    lib.mkEnableOption "<profile description>";

  config = lib.mkIf config.profiles.<name>.enable {
    # Enable capabilities with defaults
    capabilities = {
      <capability> = {
        enable = true;
        features.<feature> = lib.mkDefault true;
        # Never set adapter here - that's host-specific
      };
    };

    # Optionally enable other profiles
    profiles.<other>.enable = lib.mkDefault true;
  };
}
```

### Host Pattern

Every host configuration follows this structure:

```nix
# hosts/<hostname>/default.nix
{ config, ... }:
{
  imports = [
    ./disko.nix              # Disk layout
    ./hardware-configuration.nix  # Generated hardware config
  ];

  # 1. Select profile(s)
  profiles.<profile>.enable = true;

  # 2. Override capability settings for this hardware
  capabilities.<capability> = {
    adapter = "<specific-adapter>";
    features.<feature> = true;
    settings.<setting> = <value>;
  };

  # 3. Hardware-specific overrides (PCI IDs, etc.)
  hardware.<vendor>.<setting> = <value>;

  # 4. Host identity
  networking.hostName = "<hostname>";
}
```

---

## Auto-Discovery System

The framework automatically discovers and imports all modules without manual registration.

### Discovery Function

```nix
# lib/discover.nix
{ lib, inputs }:
let
  # Recursively find all directories containing default.nix
  discoverModules = baseDir:
    let
      entries = builtins.readDir baseDir;

      processEntry = name: type:
        let path = "${baseDir}/${name}"; in
        if type == "directory" && builtins.pathExists "${path}/default.nix" then
          path  # Directory with default.nix → import it
        else if type == "directory" then
          discoverModules path  # Recurse into subdirectory
        else if type == "regular" &&
                lib.hasSuffix ".nix" name &&
                name != "default.nix" then
          path  # Standalone .nix file → import it
        else
          null;

    in
    lib.filter (x: x != null)
      (lib.mapAttrsToList processEntry entries);
in
{
  capabilities = discoverModules "${inputs.self}/core/capabilities";
  profiles = discoverModules "${inputs.self}/core/profiles";
  adapters = discoverModules "${inputs.self}/adapters";
  homeCapabilities = discoverModules "${inputs.self}/home/capabilities";
  homeProfiles = discoverModules "${inputs.self}/home/profiles";
  homeAdapters = discoverModules "${inputs.self}/home/adapters";
}
```

### mkHost Function

```nix
# lib/default.nix
{ lib, inputs, ... }:
let
  discover = import ./discover.nix { inherit lib inputs; };
in
{
  mkHost = {
    hostname,
    system ? "x86_64-linux",
    stateVersion ? "25.05",
    users ? [],
  }:
  inputs.nixpkgs.lib.nixosSystem {
    inherit system;

    specialArgs = {
      inherit inputs;
      meta = {
        inherit hostname stateVersion;
        users = map builtins.baseNameOf users;
      };
    };

    modules = [
      # Always load: capabilities → profiles → adapters
      # Order matters: capabilities define options, adapters use them
      { imports = discover.capabilities; }
      { imports = discover.profiles; }
      { imports = discover.adapters; }

      # External modules
      inputs.disko.nixosModules.disko
      inputs.home-manager.nixosModules.home-manager

      # Base configuration
      {
        networking.hostName = hostname;
        system.stateVersion = stateVersion;
        nixpkgs.config.allowUnfree = true;
      }

      # Host-specific configuration
      "${inputs.self}/hosts/${hostname}"

      # Home Manager setup
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = { inherit inputs; };
        };
      }
    ] ++ users;
  };
}
```

---

## Home Manager Integration

Home Manager follows the same capability → adapter → profile pattern.

### User-Level Capability

```nix
# home/capabilities/shell.nix
{ lib, ... }:
{
  options.capabilities.shell = {
    enable = lib.mkEnableOption "shell configuration";

    adapter = lib.mkOption {
      type = lib.types.enum [ "zsh" "fish" "bash" ];
      default = "zsh";
    };

    features = {
      starship = lib.mkEnableOption "Starship prompt";
      direnv = lib.mkEnableOption "direnv integration";
    };

    aliases = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
    };
  };
}
```

### User-Level Adapter

```nix
# home/adapters/zsh.nix
{ config, lib, pkgs, ... }:
let
  cap = config.capabilities.shell;
in
lib.mkIf (cap.enable && cap.adapter == "zsh") {
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = cap.aliases;
  };

  programs.starship.enable = cap.features.starship;
  programs.direnv.enable = cap.features.direnv;
}
```

### User Definition

```nix
# users/username/default.nix
{ config, pkgs, ... }:
{
  # NixOS-level user account
  users.users.username = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
  };

  # Home Manager configuration
  home-manager.users.username = {
    imports = [ ./home ];

    home = {
      username = "username";
      homeDirectory = "/home/username";
      stateVersion = "25.05";
    };

    # Enable user profile
    profiles.developer.enable = true;

    # Override capabilities
    capabilities.shell.adapter = "zsh";
    capabilities.editor.adapter = "neovim";
  };
}
```

---

## Dependency Flow

```
                    ┌─────────────────────────────────────────┐
                    │               HOST CONFIG               │
                    │  profiles.workstation.enable = true     │
                    │  capabilities.graphics.adapter = "nvidia"│
                    └─────────────────────┬───────────────────┘
                                          │ selects
                                          ▼
                    ┌─────────────────────────────────────────┐
                    │                PROFILES                 │
                    │  Compose capabilities with defaults     │
                    │  capabilities.graphics.enable = true    │
                    └─────────────────────┬───────────────────┘
                                          │ enables
                                          ▼
                    ┌─────────────────────────────────────────┐
                    │              CAPABILITIES               │
                    │  Define abstract interfaces (options)   │
                    │  options.capabilities.graphics = {...}  │
                    └─────────────────────┬───────────────────┘
                                          │ read by
                                          ▼
                    ┌─────────────────────────────────────────┐
                    │                ADAPTERS                 │
                    │  Implement capabilities for hardware    │
                    │  lib.mkIf cap.enable { ... }           │
                    └─────────────────────────────────────────┘
```

---

## Testing Strategy

### Unit Tests

Test that capability options have correct types and defaults:

```nix
# tests/unit/capabilities.nix
{ pkgs, lib, ... }:
let
  eval = lib.evalModules {
    modules = [
      ../core/capabilities/graphics.nix
      { capabilities.graphics.enable = true; }
    ];
  };
in
pkgs.runCommand "test-graphics-capability" {} ''
  # Verify defaults
  [[ "${toString eval.config.capabilities.graphics.adapter}" == "auto" ]] || exit 1
  touch $out
''
```

### Integration Tests

Test that capabilities + adapters work together:

```nix
# tests/integration/workstation.nix
{ pkgs, ... }:
pkgs.nixosTest {
  name = "workstation-profile";

  nodes.machine = { ... }: {
    imports = [
      ../../core/capabilities
      ../../core/profiles
      ../../adapters
    ];

    profiles.workstation.enable = true;
  };

  testScript = ''
    machine.wait_for_unit("graphical.target")
    machine.succeed("test -e /run/current-system/sw/bin/pulseaudio || \
                     test -e /run/current-system/sw/bin/pipewire")
  '';
}
```

---

## Verification Checklist

After implementing this architecture:

1. **Auto-Discovery Works**
   - [ ] New capability files are automatically imported
   - [ ] New adapter files are automatically imported
   - [ ] No manual registration required in lib/default.nix

2. **Capabilities Are Abstract**
   - [ ] Capabilities define only `options`, never `config`
   - [ ] Capabilities don't reference specific packages
   - [ ] Capabilities use `lib.types.enum` for adapter selection

3. **Adapters Are Self-Contained**
   - [ ] Each adapter only reads from capabilities
   - [ ] Adapters don't depend on other adapters
   - [ ] Adapters use `lib.mkIf` for conditional activation

4. **Profiles Compose Cleanly**
   - [ ] Profiles only enable capabilities
   - [ ] Profiles use `lib.mkDefault` for all settings
   - [ ] Profiles can be combined without conflicts

5. **Hosts Are Minimal**
   - [ ] Hosts only select profiles and override adapters
   - [ ] Hardware-specific config (PCI IDs) is in hosts
   - [ ] No capability implementation details in hosts

6. **Build Succeeds**
   - [ ] `nix flake check` passes
   - [ ] All hosts build successfully
   - [ ] Integration tests pass

---

## Common Capabilities

### System Capabilities

| Capability | Purpose | Typical Adapters |
|------------|---------|------------------|
| `graphics` | GPU acceleration | nvidia, amd, intel |
| `audio` | Sound system | pipewire, pulseaudio |
| `networking` | Network management | networkmanager, systemd-networkd |
| `bluetooth` | Bluetooth support | bluez |
| `printing` | Print services | cups |
| `gaming` | Gaming support | steam, lutris |
| `virtualization` | VMs and containers | libvirt, docker, podman |
| `development` | Dev tools | language-specific adapters |
| `security` | Security features | sops, age |

### User Capabilities

| Capability | Purpose | Typical Adapters |
|------------|---------|------------------|
| `shell` | Shell configuration | zsh, fish, bash |
| `editor` | Text editor | neovim, vscode, emacs |
| `desktop` | DE configuration | plasma, gnome, hyprland |
| `terminal` | Terminal emulator | kitty, alacritty, wezterm |
| `browser` | Web browser | firefox, chromium |

---

## Anti-Patterns to Avoid

### 1. Capabilities Setting Implementation Details
```nix
# BAD: Capability knows about NVIDIA
capabilities.graphics.nvidiaPackage = pkgs.nvidiaPackages.stable;

# GOOD: Capability is abstract
capabilities.graphics.adapter = "nvidia";
```

### 2. Adapters Depending on Other Adapters
```nix
# BAD: Steam adapter depends on NVIDIA adapter
lib.mkIf (config.hardware.nvidia.modesetting.enable) { ... }

# GOOD: Steam adapter depends on capability
lib.mkIf (config.capabilities.gaming.enable) { ... }
```

### 3. Profiles Setting Adapter-Specific Config
```nix
# BAD: Profile sets NVIDIA-specific option
profiles.gaming.config.hardware.nvidia.open = true;

# GOOD: Profile only enables capability
profiles.gaming.config.capabilities.graphics.features.vulkan = true;
```

### 4. Hosts Duplicating Profile Logic
```nix
# BAD: Host repeats what profile does
capabilities.graphics.enable = true;
capabilities.audio.enable = true;
capabilities.bluetooth.enable = true;

# GOOD: Host just selects profile
profiles.workstation.enable = true;
```

### 5. Double Activation Required
```nix
# BAD: Must both import AND enable
imports = [ modules.gaming.steam ];
modules.gaming.steam.enable = true;

# GOOD: Just enable (import is automatic)
capabilities.gaming.enable = true;
```

---

## Summary

This architecture provides:

1. **Clear Separation**: Capabilities (what) vs Adapters (how) vs Profiles (when) vs Hosts (where)

2. **Dependency Inversion**: Adapters depend on capability interfaces, not vice versa

3. **Easy Maintenance**: Add new adapters without touching existing code

4. **Swappable Implementations**: Change GPU driver by setting one option

5. **Testable Components**: Each layer can be tested in isolation

6. **Minimal Hosts**: Most configuration comes from profiles

7. **Auto-Discovery**: No manual module registration

8. **Composable Profiles**: Combine profiles without conflicts

The key insight: **treat NixOS modules as a dependency injection framework**. Capabilities are the interfaces, adapters are the implementations, and the module system handles the wiring.
