# Hardware Configuration for Toaster
#
# Target Hardware:
#   CPU: AMD Ryzen 7 7800X3D (8 cores, 16 threads, single CCD)
#   GPU: NVIDIA RTX 5070 Ti (Blackwell) - for VM passthrough
#   iGPU: AMD Radeon 780M - for host display
#   Motherboard: ASUS ROG Strix B850-I (mini-ITX, AM5)
#   RAM: 64GB DDR5
#   Storage: 2x 2TB NVMe M.2 (Btrfs RAID1 + LUKS2)
#
# === HARDWARE DISCOVERY COMMANDS ===
#
# After first boot, run these to update placeholder values:
#
# GPU PCI IDs (for VFIO binding):
#   lspci -nn | grep -i nvidia
#   Output example: 01:00.0 VGA [0300]: NVIDIA [10de:2782]
#   Use the [10de:XXXX] values in modules.vfio.gpuPciIds
#
# GPU PCI Addresses (for libvirt XML):
#   lspci -D | grep -i nvidia
#   Output example: 0000:01:00.0, 0000:01:00.1
#   Use in modules.vfio.gpuPciAddresses
#
# Network Interface:
#   ip link
#   Look for physical ethernet (usually enp* or eth*)
#   Use in modules.networking.bridge.interface
#
# IOMMU Groups (verify GPU isolation):
#   for d in /sys/kernel/iommu_groups/*/devices/*; do
#     n=$(basename $(dirname $(dirname $d)))
#     echo "IOMMU Group $n: $(lspci -nns $(basename $d))"
#   done | sort -V
#
# NVMe Devices:
#   lsblk
#   Typically /dev/nvme0n1 and /dev/nvme1n1

{ config, lib, pkgs, inputs, ... }:

{
  # Import nixos-hardware modules if desired
  # imports = [
  #   inputs.nixos-hardware.nixosModules.common-cpu-amd
  #   inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
  #   inputs.nixos-hardware.nixosModules.common-pc-ssd
  # ];

  # Hardware-specific settings are configured in default.nix
  # This file documents the target hardware and discovery process
}
