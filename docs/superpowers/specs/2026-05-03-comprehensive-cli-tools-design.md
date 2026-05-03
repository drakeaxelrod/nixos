# Comprehensive CLI Tools Module — Design

**Date:** 2026-05-03
**Status:** Approved (pending implementation plan)

## Goal

Extend `modules/nixos/system/packages.nix` to be the single, comprehensive source of truth for stateless system-wide CLI utilities. Eliminate the ad-hoc package list duplicated in `modules/home/editors/claude-code.nix`, and add a broad set of standard text/data, archive, media, network, system-inspection, disk, and productivity tools that any user (draxel, bamse, root, scripts) might reasonably need.

## Non-goals

- Do **not** create a new module file. Extend the existing `system/packages.nix`.
- Do **not** include packages that already have dedicated home-manager modules under `modules/home/shell/*` — those modules call `programs.X.enable` (which installs the package) plus configuration, and adding them at the system level would be duplicative for the user, though harmless. Leave the small overlap that already exists (jq, ripgrep, fd, bat, lsd, htop) intact since those benefit non-draxel users and pre-home-manager scripts.
- Do **not** install GUI applications or heavy dev toolchains. Stateless CLI utilities only.
- Do **not** change anything about per-user home modules.

## Architecture

Single file: `modules/nixos/system/packages.nix`. Organized with section comments. Loaded unconditionally via `modules/nixos/system/default.nix` (already imported in `lib/default.nix` via `${inputs.self}/modules/nixos/system`).

## Skipped — already covered by `modules/home/shell/<tool>.nix`

These have dedicated home modules and should NOT be re-added at the system level (except where overlap is already deliberate):

`bat`, `btop`, `delta`, `direnv`, `dog`, `fastfetch`, `fd`, `fzf`, `gping`, `grc`, `jless`, `jq` (also installs `yq-go`), `lsd`, `procs`, `ripgrep`, `starship`, `xh`, `zoxide`, `gpg`/gnupg.

Existing intentional overlap kept: `jq`, `ripgrep`, `fd`, `bat`, `lsd`, `htop` — because they're used by `nx` script and benefit the bamse user even when draxel-specific home modules aren't loaded.

## Final package list

```nix
environment.systemPackages = with pkgs; [
  # === Already present (kept as-is) ===
  jq git curl wget neovim lsd ripgrep fd bat htop tree file dig nmap

  # === Text & data processing ===
  less                # pager
  diffutils           # diff, cmp
  patch               # apply diffs
  hexyl               # pretty hex viewer
  choose              # cut/awk alternative
  sd                  # sed alternative (intuitive find/replace)
  gron                # make JSON greppable
  miller              # mlr — CSV/TSV/JSON data processing
  jo                  # build JSON from shell args
  gnused gawk         # explicit GNU sed/awk

  # === Archives & compression ===
  unzip zip
  p7zip               # 7z
  unar                # universal archive extractor (rar, ace, etc.)
  cabextract          # MS .cab files
  xz zstd
  gnutar              # explicit GNU tar

  # === Media / documents ===
  poppler_utils       # pdftotext, pdfinfo, pdfimages
  imagemagick         # convert, identify, mogrify
  ffmpeg              # video/audio
  exiftool            # image/file metadata
  mediainfo           # media file metadata

  # === Network ===
  traceroute mtr
  whois
  netcat-openbsd      # nc
  socat
  tcpdump
  iperf3
  bind                # provides drill, nslookup (dig already in core)
  inetutils           # telnet, ftp, hostname
  aria2               # multi-source/parallel downloader
  mosh                # robust SSH replacement (note: needs UDP firewall ports)
  websocat            # netcat for websockets
  ipcalc              # IP subnet math
  bandwhich           # per-process bandwidth TUI
  iftop               # interface bandwidth TUI
  nload               # interface load TUI
  speedtest-cli       # ISP speed test
  arp-scan            # local network discovery
  wireshark-cli       # tshark, no GUI

  # === System inspection ===
  lsof
  strace ltrace
  pciutils            # lspci
  usbutils            # lsusb
  psmisc              # killall, pstree, fuser
  iotop
  sysstat             # iostat, mpstat, sar
  dmidecode           # hardware/BIOS info
  inxi                # full system info report
  acpi                # battery / thermal info

  # === Disk / filesystem ===
  ncdu                # disk usage TUI
  duf                 # df alternative
  dust                # du alternative (rust)
  smartmontools       # smartctl
  rsync
  parted gptfdisk
  dosfstools exfatprogs e2fsprogs
  sshfs               # mount remote filesystems via SSH
  rclone              # sync to/from cloud storage

  # === Misc productivity ===
  entr                # run command on file change
  pv                  # pipe progress
  tmux                # terminal multiplexer
  moreutils           # sponge, vidir, parallel, ts, ifne
  tealdeer            # tldr — community man-page summaries
  glow                # markdown renderer for terminal
  gum                 # charm.sh interactive prompts
  bc                  # arbitrary-precision calculator
  units               # unit conversion
  mc                  # midnight commander (TUI file manager)
  trash-cli           # safer rm
  yt-dlp              # video downloader (incl. youtube)

  # === Security / crypto ===
  openssl
  age                 # modern simple encryption
  # Note: gnupg is provided per-user via modules/home/shell/gpg.nix

  # === Git extras ===
  gh                  # GitHub CLI
  git-lfs             # git large file storage
  gitleaks            # secret scanning
];
```

## Cleanups in scope

1. **Strip `home.packages` block from `modules/home/editors/claude-code.nix:6-22`** — replace with a one-line comment pointing to `modules/nixos/system/packages.nix`. The `claude-code` user no longer maintains its own duplicate list.

2. **Strip the user's commented-out duplicate list from `users/draxel/home/default.nix:136-150`** — those commented lines are now obsolete given the system module.

## Risks / things to verify

- Some packages may have changed names in current nixpkgs (e.g., `poppler_utils` vs `poppler-utils`, `wireshark-cli` vs `wireshark-cli`, `tealdeer` vs `tldr`). Implementation must verify each name resolves before flake build. Run `nix-instantiate --eval -E '(import <nixpkgs> {}).<name>.pname'` or check on `search.nixos.org` per-package.
- `wireshark-cli` may pull substantial dependencies; if so, consider just `tshark` if a slimmer attribute exists.
- `mosh` opens UDP ports 60000-61000 — verify firewall config or document the requirement. Don't auto-open ports as part of this module.
- Adding ~50 packages will increase initial system closure size. Acceptable trade for a comprehensive baseline.

## Success criteria

- `nixos-rebuild build` succeeds.
- All listed tools resolvable on PATH for both `draxel` and `bamse` users.
- `claude-code.nix` no longer carries a redundant package list.
- Single edit point for "what stateless CLI tools does my system have" — `modules/nixos/system/packages.nix`.

## Out of scope (future work, not this change)

- Splitting `system/packages.nix` into a directory (`system/packages/{network,media,...}.nix`) if/when it grows past ~150 lines.
- Reconciling per-user home/shell modules vs system packages (e.g., should `bat` only be installed once?). Current overlap is harmless; revisit only if it causes friction.
- A separate "pentest" CLI module for the bamse user (nmap-extras, masscan, gobuster, etc.) — that belongs under `users/bamse/home/pentest.nix` or a new `modules/nixos/security/pentest-tools.nix`.
