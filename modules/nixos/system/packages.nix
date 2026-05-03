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
    poppler-utils       # pdftotext, pdfinfo, pdfimages
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
