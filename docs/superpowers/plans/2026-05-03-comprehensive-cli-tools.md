# Comprehensive CLI Tools Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `modules/nixos/system/packages.nix` the single, comprehensive source of system-wide CLI utilities (text/data, archives, media, network, system, disk, productivity, security, git) and strip duplicated package lists from claude-code.nix and the draxel home module.

**Architecture:** Single-file edit to `modules/nixos/system/packages.nix` — add ~50 packages organized by category. Two follow-up cleanups remove duplicate lists. Validation via `nixos-rebuild dry-build` after each edit; one full `switch` at the end activates and smoke-tests.

**Tech Stack:** NixOS 25.11 / nixpkgs (current flake), Home Manager. Build via the `nx` script (`scripts/nx.sh`) which wraps `nixos-rebuild`.

---

## File Structure

| Action | Path | Responsibility |
| --- | --- | --- |
| Modify | `modules/nixos/system/packages.nix` | Comprehensive system-wide CLI tool list (single source of truth) |
| Modify | `modules/home/editors/claude-code.nix` | Remove `home.packages = with pkgs; [...]` block at lines 6–22 (now provided system-wide) |
| Modify | `users/draxel/home/default.nix` | Remove obsolete commented-out duplicate at lines 136–150 |

No new files. No new modules registered in `lib/default.nix`.

---

## Build / verify commands used in this plan

- **Eval check (fast, no downloads):** `nix flake check --no-build path:/home/draxel/.config/nixos` — fails fast on bad attribute names.
- **Dry-build (validates derivations):** `nx dry-build` (wraps `nixos-rebuild dry-build --flake .#<host>`)
- **Build only (no activation):** `nx build` (wraps `nixos-rebuild build --flake .#<host>`)
- **Activate:** `nx switch` (wraps `sudo nixos-rebuild switch --flake .#<host>`)

If `nx` is not on PATH for the executor, fall back to the underlying `nixos-rebuild` invocations directly.

---

## Task 1: Replace `system/packages.nix` with the comprehensive list

**Files:**
- Modify: `modules/nixos/system/packages.nix` (full body replacement)

- [ ] **Step 1: Read current file to confirm starting state**

Run: `cat /home/draxel/.config/nixos/modules/nixos/system/packages.nix`

Expected: 32-line file with 16 packages in `environment.systemPackages`, exactly matching:

```nix
# System-wide essential packages
# These are available before home-manager activates
{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    # Essential CLI tools needed by system scripts
    jq      # JSON processor (required by nx script)
    git     # Version control
    curl    # HTTP client
    wget    # File downloader

    # Text editor
    neovim  # Modern vim

    # File operations
    lsd     # Modern ls
    ripgrep # Fast grep
    fd      # Fast find
    bat     # Cat with syntax highlighting

    # System utilities
    htop    # Process monitor
    tree    # Directory listing
    file    # File type detection

    # Network utilities
    dig     # DNS lookup
    nmap    # Network scanner
  ];
}
```

If it differs, STOP and re-read the spec before continuing.

- [ ] **Step 2: Replace the file with the comprehensive content below**

Use the Write tool to overwrite `/home/draxel/.config/nixos/modules/nixos/system/packages.nix` with EXACTLY:

```nix
# System-wide essential packages
# These are available before home-manager activates and to all users
# (draxel, bamse, root) regardless of which home modules they import.
#
# This is the single source of truth for stateless CLI utilities.
# Tools that have a dedicated home module under modules/home/shell/<tool>.nix
# (bat, btop, delta, direnv, dog, fastfetch, fd, fzf, gping, grc, jless, jq,
# lsd, procs, ripgrep, starship, xh, zoxide, gpg) generally do NOT need to
# be repeated here — those modules call programs.X.enable which installs
# the package per user. Exceptions: jq/ripgrep/fd/bat/lsd/htop are
# intentionally kept in both places so they are available pre-home-manager
# and to non-draxel users.
{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    # ========================================================================
    # Core (also overlap with per-user home modules — kept intentionally)
    # ========================================================================
    jq          # JSON processor (required by nx script)
    git         # Version control
    curl        # HTTP client
    wget        # File downloader
    neovim      # Modern vim
    lsd         # Modern ls
    ripgrep     # Fast grep
    fd          # Fast find
    bat         # Cat with syntax highlighting
    htop        # Process monitor
    tree        # Directory listing
    file        # File type detection
    dig         # DNS lookup (also provided by `bind` below)
    nmap        # Network scanner

    # ========================================================================
    # Text & data processing
    # ========================================================================
    less                # Pager
    diffutils           # diff, cmp, sdiff
    patch               # Apply diffs
    hexyl               # Pretty hex viewer
    choose              # Cut/awk alternative (intuitive field selection)
    sd                  # Sed alternative (intuitive find/replace)
    gron                # Make JSON greppable
    miller              # mlr — CSV/TSV/JSON data processing
    jo                  # Build JSON from shell args
    gnused              # Explicit GNU sed
    gawk                # Explicit GNU awk

    # ========================================================================
    # Archives & compression
    # ========================================================================
    unzip
    zip
    p7zip               # 7z
    unar                # Universal archive extractor (rar, ace, etc.)
    cabextract          # MS .cab files
    xz
    zstd
    gnutar              # Explicit GNU tar

    # ========================================================================
    # Media / documents
    # ========================================================================
    poppler_utils       # pdftotext, pdfinfo, pdfimages
    imagemagick         # convert, identify, mogrify
    ffmpeg              # Video / audio
    exiftool            # Image / file metadata
    mediainfo           # Media file metadata

    # ========================================================================
    # Network
    # ========================================================================
    traceroute
    mtr                 # traceroute + ping combined
    whois
    netcat-openbsd      # nc
    socat               # Bidirectional socket relay
    tcpdump             # Packet capture
    iperf3              # Network throughput test
    bind                # drill, nslookup (dig already in core)
    inetutils           # telnet, ftp, hostname
    aria2               # Multi-source / parallel downloader
    mosh                # Robust SSH replacement (NOTE: needs UDP 60000-61000 in firewall)
    websocat            # netcat for websockets
    ipcalc              # IP subnet math
    bandwhich           # Per-process bandwidth TUI
    iftop               # Interface bandwidth TUI
    nload               # Interface load TUI
    speedtest-cli       # ISP speed test
    arp-scan            # Local network discovery
    wireshark-cli       # tshark — CLI packet analyzer (no GUI)

    # ========================================================================
    # System inspection
    # ========================================================================
    lsof                # List open files
    strace              # System call trace
    ltrace              # Library call trace
    pciutils            # lspci
    usbutils            # lsusb
    psmisc              # killall, pstree, fuser
    iotop               # Disk I/O TUI
    sysstat             # iostat, mpstat, sar
    dmidecode           # Hardware / BIOS info
    inxi                # Full system info report
    acpi                # Battery / thermal info

    # ========================================================================
    # Disk / filesystem
    # ========================================================================
    ncdu                # Disk usage TUI
    duf                 # df alternative
    dust                # du alternative (rust)
    smartmontools       # smartctl
    rsync
    parted
    gptfdisk            # gdisk
    dosfstools          # mkfs.vfat, fsck.vfat
    exfatprogs          # exFAT tools
    e2fsprogs           # ext2/3/4 tools
    sshfs               # Mount remote FS via SSH
    rclone              # Sync to/from cloud storage

    # ========================================================================
    # Misc productivity
    # ========================================================================
    entr                # Run command on file change
    pv                  # Pipe progress
    tmux                # Terminal multiplexer
    moreutils           # sponge, vidir, parallel, ts, ifne, etc.
    tealdeer            # tldr — community man-page summaries
    glow                # Markdown renderer for terminal
    gum                 # charm.sh interactive prompts for shell scripts
    bc                  # Arbitrary-precision calculator
    units               # Unit conversion
    mc                  # Midnight commander (TUI file manager)
    trash-cli           # Safer rm
    yt-dlp              # Video downloader

    # ========================================================================
    # Security / crypto
    # ========================================================================
    openssl
    age                 # Modern simple encryption
    # NOTE: gnupg is provided per-user via modules/home/shell/gpg.nix

    # ========================================================================
    # Git extras
    # ========================================================================
    gh                  # GitHub CLI
    git-lfs             # Git large file storage
    gitleaks            # Secret scanning
  ];
}
```

- [ ] **Step 3: Determine the current host name**

Run: `hostname`

Record the output (e.g., `toaster`, `laptop`, `nixos`, `honeypot`). It must match a directory under `hosts/`. Verify:

Run: `ls /home/draxel/.config/nixos/hosts/$(hostname)`

Expected: directory listing succeeds (no "No such file or directory"). If it fails, the executor must be told the correct host name before continuing — do NOT guess.

- [ ] **Step 4: Validate the new file evaluates by running a dry-build**

Run: `cd /home/draxel/.config/nixos && nx dry-build`

Expected outcome: command completes with exit code 0. nixos-rebuild prints derivation paths it WOULD build; no "error: undefined variable" or "attribute ... missing" errors.

If it fails on a missing attribute (e.g., `wireshark-cli` doesn't exist under that exact name in current nixpkgs), the executor must:
1. Read the error message to identify the offending package.
2. Search nixpkgs for the correct attribute name:
   `nix search nixpkgs '<keyword>' --no-write-lock-file`
   or check `https://search.nixos.org/packages`.
3. Update the attribute name in `modules/nixos/system/packages.nix` (or remove the package if no replacement exists, adding a comment `# removed: not in nixpkgs as of YYYY-MM-DD`).
4. Re-run `nx dry-build` until it passes.

Common substitutions to try if a name fails:
- `poppler_utils` ↔ `poppler-utils` (Nix attribute names use underscores; this one is canonically `poppler_utils`)
- `wireshark-cli` ↔ `wireshark-cli` (if missing, drop it — the GUI `wireshark` package is too heavy to substitute)
- `tealdeer` ↔ `tldr`
- `speedtest-cli` ↔ `speedtest-cli` (if missing, try `speedtest-rs`)
- `apacheHttpd` is intentionally NOT in the list — do not add it back

- [ ] **Step 5: Commit**

```bash
cd /home/draxel/.config/nixos
git add modules/nixos/system/packages.nix
git commit -m "feat(nixos/system): comprehensive CLI tools in system packages

Expand system/packages.nix from 16 essential utilities to ~70 covering
text/data processing, archives, media, network, system inspection, disk,
productivity, security, and git extras. This becomes the single source
of truth for stateless system-wide CLI tools.

Skips packages already covered by home/shell/<tool>.nix modules
(programs.X.enable handles those per-user). Intentional overlap kept
for jq/ripgrep/fd/bat/lsd/htop so they are available pre-home-manager
and to non-draxel users (e.g. bamse)."
```

---

## Task 2: Strip duplicate package list from `claude-code.nix`

**Files:**
- Modify: `modules/home/editors/claude-code.nix:6-22`

- [ ] **Step 1: Re-read the file to confirm lines 5–23 match expected content**

Run: `sed -n '5,23p' /home/draxel/.config/nixos/modules/home/editors/claude-code.nix`

Expected output:

```
{
  # CLI tools commonly used by Claude — always on PATH
  home.packages = with pkgs; [
    poppler-utils      # pdftotext, pdfinfo
    jq                 # JSON processing
    # yq removed: conflicts with yq-go already installed elsewhere
    ripgrep            # rg (faster grep)
    fd                 # find replacement
    bat                # cat with syntax highlighting
    imagemagick        # image operations
    ffmpeg             # video/audio
    curl               # HTTP
    wget               # downloads
    unzip
    zip
    tree
    htop
    fzf
  ];

```

- [ ] **Step 2: Replace lines 6–22 (the comment + entire `home.packages` block) with a single replacement comment**

Use the Edit tool. `old_string`:

```
  # CLI tools commonly used by Claude — always on PATH
  home.packages = with pkgs; [
    poppler-utils      # pdftotext, pdfinfo
    jq                 # JSON processing
    # yq removed: conflicts with yq-go already installed elsewhere
    ripgrep            # rg (faster grep)
    fd                 # find replacement
    bat                # cat with syntax highlighting
    imagemagick        # image operations
    ffmpeg             # video/audio
    curl               # HTTP
    wget               # downloads
    unzip
    zip
    tree
    htop
    fzf
  ];
```

`new_string`:

```
  # CLI tools used by Claude (poppler-utils, jq, ripgrep, fd, bat,
  # imagemagick, ffmpeg, curl, wget, unzip/zip, tree, htop, fzf) are
  # provided system-wide by modules/nixos/system/packages.nix.
```

- [ ] **Step 3: Verify the file still parses by re-running dry-build**

Run: `cd /home/draxel/.config/nixos && nx dry-build`

Expected: exit 0, no errors.

- [ ] **Step 4: Commit**

```bash
cd /home/draxel/.config/nixos
git add modules/home/editors/claude-code.nix
git commit -m "refactor(home/editors/claude-code): drop duplicated CLI packages

These tools are now provided system-wide via modules/nixos/system/packages.nix.
Replace the home.packages list with a comment pointing there."
```

---

## Task 3: Strip obsolete commented-out block from draxel's home module

**Files:**
- Modify: `users/draxel/home/default.nix:136-150`

- [ ] **Step 1: Re-read the relevant block to confirm content**

Run: `sed -n '132,153p' /home/draxel/.config/nixos/users/draxel/home/default.nix`

Expected output (commented-out package list):

```
    bun # js compiler
    pkg-config # Tool that allows packages to find out information about other packages (wrapper script)
    dbus

    # poppler_utils      # pdftotext, pdfinfo
    # jq                 # JSON processing
    # yq                 # YAML processing
    # ripgrep            # rg (faster grep)
    # fd                 # find replacement
    # bat                # cat with syntax highlighting
    # imagemagick        # image operations
    # ffmpeg             # video/audio
    # curl               # HTTP
    # wget               # downloads
    # unzip
    # zip
    # tree
    # htop
    # fzf

  ];
```

- [ ] **Step 2: Remove the commented-out block (lines 136–150 inclusive of the blank-line separator above)**

Use the Edit tool. `old_string`:

```
    dbus

    # poppler_utils      # pdftotext, pdfinfo
    # jq                 # JSON processing
    # yq                 # YAML processing
    # ripgrep            # rg (faster grep)
    # fd                 # find replacement
    # bat                # cat with syntax highlighting
    # imagemagick        # image operations
    # ffmpeg             # video/audio
    # curl               # HTTP
    # wget               # downloads
    # unzip
    # zip
    # tree
    # htop
    # fzf

  ];
```

`new_string`:

```
    dbus
  ];
```

- [ ] **Step 3: Verify parses**

Run: `cd /home/draxel/.config/nixos && nx dry-build`

Expected: exit 0, no errors.

- [ ] **Step 4: Commit**

```bash
cd /home/draxel/.config/nixos
git add users/draxel/home/default.nix
git commit -m "chore(users/draxel): remove obsolete commented-out package list

These tools are now provided system-wide via modules/nixos/system/packages.nix."
```

---

## Task 4: Activate and smoke-test

**Files:** none modified — pure verification.

- [ ] **Step 1: Activate the new system**

Run: `cd /home/draxel/.config/nixos && nx switch`

Expected: prompts for sudo, builds (downloads new packages), activates with no errors. May take several minutes on first run due to new package downloads.

If activation fails:
- Read the error carefully. `nixos-rebuild` typically tells you which module / option is at fault.
- If the failure is about a per-user PATH conflict (e.g., a tool exists in both `home.packages` of some module AND `environment.systemPackages` AND home-manager complains), STOP and report — do NOT silently delete the home-side entry. The expected behavior is that home-manager wins for that user but no conflict error is raised.

- [ ] **Step 2: Verify a representative sampling of newly-added tools is on PATH**

Run:

```bash
for tool in pdftotext convert ffmpeg unzip zip mtr nc tcpdump iperf3 mosh tshark lsof lspci lsusb killall iotop dmidecode inxi ncdu duf dust smartctl rsync sshfs rclone entr pv tmux tldr glow gum bc units mc trash yt-dlp openssl age gh git-lfs gitleaks aria2c websocat ipcalc bandwhich iftop nload speedtest-cli arp-scan exiftool mediainfo hexyl sd gron mlr jo; do
  if command -v "$tool" >/dev/null 2>&1; then
    printf '  OK   %s -> %s\n' "$tool" "$(command -v "$tool")"
  else
    printf '  MISS %s\n' "$tool"
  fi
done
```

Expected: every line begins with `  OK  `. Any `  MISS ` indicates the binary's package is named differently than expected — investigate by running `nix search nixpkgs '<binary-name>'` and update `modules/nixos/system/packages.nix` accordingly, then re-run from Task 1 Step 4 (dry-build).

Notes on naming quirks (these are the actual binary names from the Nix package):
- `tealdeer` package provides the `tldr` binary
- `aria2` package provides the `aria2c` binary
- `wireshark-cli` package provides the `tshark` binary
- `git-lfs` provides `git-lfs` (not just `git lfs`)
- `trash-cli` provides `trash` (and friends like `trash-empty`, `trash-list`)

- [ ] **Step 3: If ALL tools resolve, the implementation is complete. No commit needed (no file changes in this task).**

If any tools were `MISS` and you fixed the package list, the additional fix is committed under Task 1's commit message style as an amendment commit (`fix(nixos/system): correct package attribute name for X`).

---

## Self-Review Notes

- **Spec coverage:** Every category in the spec (text/data, archives, media, network, system, disk, productivity, security, git extras) is covered by Task 1's package list. Both cleanups (claude-code.nix, draxel home commented block) are covered by Tasks 2 and 3. Activation + smoke test = Task 4.
- **No placeholders:** every step has the exact command, exact file path, exact `old_string`/`new_string` content.
- **Type / name consistency:** package attribute names used in Task 1's file body are the names verified against in Task 4's smoke loop (mapped to their binary names with quirks documented).
- **Risks acknowledged inline:** `wireshark-cli`, `mosh` UDP firewall, `poppler_utils` underscore.
