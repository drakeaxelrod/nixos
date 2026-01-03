# GPG - GNU Privacy Guard
# Encryption, signing, and authentication
{ config, pkgs, lib, ... }:

{
  programs.gpg = {
    enable = true;

    # Use XDG-compliant directory (set via NixOS environment.variables)
    # GNUPGHOME = ~/.local/share/gnupg

    settings = {
      # Use AES256, SHA512 for symmetric encryption
      personal-cipher-preferences = "AES256 AES192 AES";
      personal-digest-preferences = "SHA512 SHA384 SHA256";
      personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";

      # Default preferences for new keys
      default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";

      # Use SHA512 for signing
      cert-digest-algo = "SHA512";
      s2k-digest-algo = "SHA512";
      s2k-cipher-algo = "AES256";

      # Display options
      keyid-format = "0xlong";
      with-fingerprint = true;

      # Trust model
      trust-model = "tofu+pgp";

      # No comments or version in output
      no-comments = true;
      no-emit-version = true;

      # Disable recipient key ID in messages
      throw-keyids = true;

      # Use agent for passphrase caching
      use-agent = true;
    };
  };

  # GPG Agent for caching passphrases and SSH key management
  services.gpg-agent = {
    enable = true;

    # Passphrase cache timeout (in seconds)
    defaultCacheTtl = 1800;       # 30 minutes
    maxCacheTtl = 7200;           # 2 hours

    # Enable SSH agent emulation (use GPG keys for SSH)
    enableSshSupport = false;     # Set true if using GPG for SSH auth

    # Pinentry program for passphrase prompts
    pinentry.package = pkgs.pinentry-qt;

    # Extra configuration
    extraConfig = ''
      # Allow loopback pinentry for CLI usage
      allow-loopback-pinentry
    '';
  };
}
