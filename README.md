# NixOS Configuration

Modular NixOS configuration with support for multiple hosts (workstations, pentesting machines, etc).

## Features

- **Modular architecture** - Composable host and user configurations
- **Multiple hosts** - nixos (default), toaster (gaming/VFIO), honeypot (pentesting)
- **SOPS secrets** - Hierarchical secrets per host/user with password manager backup
- **VFIO GPU passthrough** - Dual-boot support (host GPU / VM passthrough)
- **Declarative VMs** - NixOS-native libvirt VM definitions
- **Impermanence** - Optional ephemeral root filesystem
- **Btrfs** snapshots with btrbk

## Hosts

- **nixos** - Default minimal configuration
- **toaster** - Gaming/VFIO workstation (AMD 7800X3D, NVIDIA RTX 5070 Ti, AMD 780M iGPU)
- **honeypot** - Penetration testing machine with 100+ security tools

---

## Installation

### Prerequisites

- Boot from [NixOS minimal ISO](https://nixos.org/download)
- Network connection
- Age keys stored in password manager (see [SOPS Setup](#sops-secrets-setup))

### Quick Install

```bash
# On target machine - connect to network
nmcli device wifi connect "SSID" password "PASSWORD"

# Clone repository
nix-shell -p git
git clone https://github.com/DrakeAxelrod/nixos.git /tmp/nixos

# Partition disk with disko
nix run --extra-experimental-features "nix-command flakes" \
  github:nix-community/disko -- \
  --mode disko /tmp/nixos/hosts/nixos/disko.nix

# Install NixOS
nixos-install --extra-experimental-features "nix-command flakes" \
  --flake github:DrakeAxelrod/nixos#nixos \
  --no-root-passwd

reboot
```

Login with password `changeme` and change it immediately with `passwd`.

---

## SOPS Secrets Setup

### Password Manager Storage

Store these in Bitwarden/Proton Pass for each machine:

- **Host keys**: `<hostname>-age-key` (public), `<hostname>-ssh-host-key` (private backup)
- **User keys**: `<username>-age-private-key`, `<username>-age-public-key`
- **Git access**: `github-deploy-key` or `github-personal-token`

### First-Time Setup

#### 1. Generate Host Age Key

```bash
# After installation, get host's age key
nix-shell -p ssh-to-age --run \
  'cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age'

# Store in password manager as "<hostname>-age-key"
```

#### 2. Generate User Age Key

```bash
# Generate new age key (or retrieve from password manager if migrating)
nix-shell -p age --run 'age-keygen -o ~/.age-key.txt'

# Shows: Public key: age1xxx...
# Store BOTH public and private in password manager
```

#### 3. Update .sops.yaml

Clone config and add your keys to [.sops.yaml](.sops.yaml):

```bash
git clone git@github.com:drakeaxelrod/nixos.git ~/.config/nixos
cd ~/.config/nixos
```

Add age keys:

```yaml
keys:
  - &draxel age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  - &nixos age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

creation_rules:
  - path_regex: hosts/nixos/secrets\.yaml$
    key_groups:
      - age: [*draxel, *nixos]
  - path_regex: users/draxel/secrets\.yaml$
    key_groups:
      - age: [*draxel]
```

#### 4. Create Secrets Files

```bash
# Copy example secrets
cd hosts/nixos
cp secrets.yaml.example secrets.yaml
# Edit with real values
nano secrets.yaml

# Encrypt
nix-shell -p sops --run 'sops -e -i secrets.yaml'

# Repeat for user secrets
cd ../../users/draxel
cp secrets.yaml.example secrets.yaml
nano secrets.yaml
nix-shell -p sops --run 'sops -e -i secrets.yaml'
```

#### 5. Enable SOPS in Host Config

```nix
# In hosts/<hostname>/default.nix
modules.security.sops.enable = true;
```

### Accessing Secrets

Secrets are available at `/run/secrets/<secret-name>`:

```nix
# In NixOS configuration
services.someService.passwordFile = config.sops.secrets.database_password.path;
```

### Migrating to New Hardware

**Same hostname:**

```bash
# Update .sops.yaml with new host's age key
# Re-encrypt with new key
cd hosts/<hostname>
nix-shell -p sops --run 'sops updatekeys secrets.yaml'
```

**New hostname:** Follow first-time setup, retrieve user age key from password manager.

### Troubleshooting

- **"Failed to decrypt"**: Check age key location, verify in `.sops.yaml`, check permissions (600)
- **"No such file"**: Enable `modules.security.sops.enable`, verify secrets.yaml exists
- **Edit secrets**: `nix-shell -p sops --run 'sops secrets.yaml'`

---

## Advanced Topics

### GPU Passthrough (toaster host)

See [docs/vfio-setup.md](docs/vfio-setup.md) for complete VFIO/GPU passthrough configuration.

### Impermanence

Enable ephemeral root filesystem:

```bash
# After first boot, create blank root snapshot
sudo mount -o subvol=/ /dev/mapper/cryptroot1 /mnt
sudo btrfs subvolume snapshot -r /mnt/@rootfs /mnt/@rootfs-blank
sudo umount /mnt

# Enable in host config
# In hosts/<hostname>/default.nix:
modules.impermanence.enable = true;

# Rebuild
nx switch
```

---

## Development Commands

```bash
cd ~/.config/nixos
nix develop  # Enter dev shell

# Unified nx tool (default host: nixos):
nx                 # Show help
nx switch          # Rebuild and switch (default host)
nx switch toaster  # Rebuild and switch (specific host)
nx boot            # Rebuild for next boot
nx test            # Test without boot entry
nx dry             # Dry run
nx build           # Build without activating
nx update          # Update flake inputs
nx diff            # Show system diff
nx gc              # Garbage collect
nx fmt             # Format nix files
nx check           # Check flake

# Other commands:
sops-edit          # Edit secrets
discover-hardware  # Show GPU/network info
```

### Rebuild without Dev Shell

```bash
# From GitHub (after pushing changes)
sudo nixos-rebuild switch --extra-experimental-features "nix-command flakes" \
  --flake github:DrakeAxelrod/nixos#nixos

# From local clone
sudo nixos-rebuild switch --extra-experimental-features "nix-command flakes" \
  --flake ~/.config/nixos#nixos
```

---

## Directory Structure

```
.
├── flake.nix                    # Flake entry point
├── .sops.yaml                   # SOPS age key configuration
├── docs/                        # Specialized documentation
│   └── vfio-setup.md            # GPU passthrough guide
├── lib/                         # Helper functions
│   ├── default.nix              # mkHost
│   └── libvirt.nix              # VM XML generation
├── hosts/                       # Host configurations
│   ├── nixos/
│   │   ├── default.nix
│   │   ├── disko.nix
│   │   └── secrets.yaml.example
│   ├── toaster/
│   └── honeypot/
├── users/                       # User configurations
│   ├── draxel/
│   │   ├── default.nix          # NixOS user
│   │   ├── secrets.yaml.example
│   │   └── home/                # Home Manager
│   │       ├── dev/             # git, lazygit, dev tools
│   │       ├── editors/         # neovim, vscode, claude-code
│   │       ├── apps/            # moonlight, stremio, steam
│   │       ├── shell/           # zsh, starship
│   │       ├── desktop/         # GNOME, GTK themes
│   │       └── core/            # packages, XDG
│   └── bamse/
│       └── home/pentest.nix     # 100+ security tools
├── modules/                     # Reusable modules
│   ├── core/                    # boot, nix, locale
│   ├── hardware/                # amd, nvidia, audio, bluetooth
│   ├── desktop/                 # gnome, wayland, steam
│   ├── networking/              # base, bridge, tailscale
│   ├── services/                # ssh, printing, btrbk
│   ├── security/                # sops, base
│   ├── virtualization/          # docker, libvirt
│   ├── vfio/                    # GPU passthrough, dual-boot
│   ├── vms/                     # Declarative VMs
│   └── impermanence/            # Ephemeral root
└── scripts/
    └── nx.sh                    # Build/switch/update commands
```
