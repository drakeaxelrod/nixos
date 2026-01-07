# TPM2 LUKS Auto-Decrypt at Boot

This guide explains how to enroll TPM2 keys for automatic LUKS decryption at boot on NixOS with disko.

## Prerequisites

- TPM2 chip (most modern motherboards have this)
- LUKS-encrypted root partition (configured via disko)
- systemd-boot with systemd initrd

## Check TPM2 Availability

```bash
# Check if TPM2 is available
ls /dev/tpm*

# Get TPM2 info
sudo systemd-cryptenroll --tpm2-device=list
```

## Disko Configuration

Add `crypttabExtraOpts` to your LUKS devices in disko.nix:

```nix
# In hosts/toaster/disko.nix
luks = {
  size = "100%";
  content = {
    type = "luks";
    name = "cryptroot0";
    settings = {
      allowDiscards = true;
      crypttabExtraOpts = [ "tpm2-device=auto" ];  # <-- Add this
    };
  };
};
```

For your dual NVMe RAID 1 setup, add it to **both** LUKS devices:

```nix
# disk1 (nvme0n1)
luks = {
  content = {
    type = "luks";
    name = "cryptroot0";
    settings = {
      allowDiscards = true;
      crypttabExtraOpts = [ "tpm2-device=auto" ];
    };
  };
};

# disk2 (nvme1n1)
luks = {
  content = {
    type = "luks";
    name = "cryptroot1";
    settings = {
      allowDiscards = true;
      crypttabExtraOpts = [ "tpm2-device=auto" ];
    };
    content = { /* btrfs RAID 1 */ };
  };
};
```

## NixOS Configuration

Enable systemd in initrd (required for TPM2 unlock):

```nix
# In your host configuration (e.g., hosts/toaster/default.nix)
boot.initrd.systemd.enable = true;
```

**Note:** With disko, the LUKS device configuration is generated automatically. The `crypttabExtraOpts` in disko.nix handles the TPM2 settings.

## Enroll TPM2 Keys

After rebuilding NixOS, enroll TPM2 keys for **both** LUKS devices:

```bash
# Enroll TPM2 key for first NVMe
sudo systemd-cryptenroll /dev/nvme0n1p2 --tpm2-device=auto --tpm2-pcrs=0+7

# Enroll TPM2 key for second NVMe
sudo systemd-cryptenroll /dev/nvme1n1p2 --tpm2-device=auto --tpm2-pcrs=0+7

# You'll be prompted for your existing LUKS passphrase for each
```

### PCR Selection

Choose PCRs based on your security needs:

| PCR | Measures | Notes |
|-----|----------|-------|
| 0 | Firmware (BIOS/UEFI) | Changes on firmware update |
| 1 | Firmware configuration | Changes on BIOS settings |
| 4 | Boot loader | Changes when bootloader updates |
| 7 | Secure Boot state | Recommended for Secure Boot |
| 11 | BitLocker-style | Unified kernel image |

**Recommended combinations:**
- `--tpm2-pcrs=0+7` - Balanced security (firmware + Secure Boot)
- `--tpm2-pcrs=7` - Just Secure Boot (survives firmware updates)
- `--tpm2-pcrs=0+1+7` - Strict (breaks on any firmware change)

## Verify Enrollment

```bash
# List enrolled keys
sudo systemd-cryptenroll /dev/nvme0n1p2

# Should show:
# SLOT TYPE
# 0    password
# 1    tpm2
```

## Test

Reboot your system. It should:
1. Automatically unlock the LUKS partition using TPM2
2. Boot without asking for a password

If TPM unlock fails (e.g., hardware change), it falls back to password prompt.

## Recovery / Re-enrollment

### Remove TPM2 Key

```bash
# Remove TPM2 enrollment (slot 1)
sudo systemd-cryptenroll /dev/nvme0n1p2 --wipe-slot=tpm2
```

### Re-enroll After Changes

If you update firmware, change Secure Boot keys, or TPM unlock stops working:

```bash
# Remove old TPM key and enroll new one
sudo systemd-cryptenroll /dev/nvme0n1p2 --wipe-slot=tpm2
sudo systemd-cryptenroll /dev/nvme0n1p2 --tpm2-device=auto --tpm2-pcrs=0+7
```

## Security Considerations

### PIN Protection (Optional)

Add a PIN requirement alongside TPM2:

```bash
sudo systemd-cryptenroll /dev/nvme0n1p2 --tpm2-device=auto --tpm2-pcrs=0+7 --tpm2-with-pin=yes
```

This requires both TPM2 AND a PIN to unlock.

### What TPM2 Protects Against

- **Cold boot attacks** - Disk is encrypted at rest
- **Disk theft** - Cannot decrypt on different hardware
- **Boot tampering** - PCR binding detects bootloader changes

### What TPM2 Does NOT Protect Against

- **Evil maid attacks** - Physical access to running system
- **Root access** - If attacker has root, they have the keys
- **Memory attacks** - Keys are in RAM when system is running

## Troubleshooting

### TPM2 Not Found

```bash
# Check if TPM is enabled in BIOS
dmesg | grep -i tpm

# Ensure tpm2 module is loaded
lsmod | grep tpm
```

### Enrollment Fails

```bash
# Check TPM2 status
sudo tpm2_getcap properties-fixed 2>/dev/null || sudo apt install tpm2-tools

# Clear TPM (WARNING: removes all keys)
# Do this in BIOS, not command line
```

### Boot Hangs on Decrypt

1. Wait for timeout (falls back to password)
2. Boot with password
3. Check PCR values changed: `sudo tpm2_pcrread`
4. Re-enroll TPM key

## See Also

- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture
- [VFIO.md](VFIO.md) - GPU passthrough (may affect PCR values)
- `man systemd-cryptenroll` - Full enrollment options
