# libvirt/QEMU/KVM virtualization
{ config, lib, pkgs, ... }:

{
  options.modules.virtualization.libvirt = {
    enable = lib.mkEnableOption "libvirt virtualization";

    tpm = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable TPM emulation (required for Windows 11)";
    };

    spiceUSB = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable SPICE USB redirection";
    };

    ovmfSecureBoot = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Secure Boot support in OVMF";
    };
  };

  config = lib.mkIf config.modules.virtualization.libvirt.enable {
    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = config.modules.virtualization.libvirt.tpm;
        ovmf = {
          enable = true;
          packages = [
            (pkgs.OVMF.override {
              secureBoot = config.modules.virtualization.libvirt.ovmfSecureBoot;
              tpmSupport = config.modules.virtualization.libvirt.tpm;
            }).fd
          ];
        };
      };
    };

    programs.virt-manager.enable = true;
    virtualisation.spiceUSBRedirection.enable = config.modules.virtualization.libvirt.spiceUSB;

    # Ensure vhost modules are loaded for network performance
    boot.kernelModules = [ "vhost" "vhost_net" ];
  };
}
