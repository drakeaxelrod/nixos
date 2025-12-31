# Libvirt domain XML generation library
#
# Provides a single function `generateDomainXML` that takes a VM config
# and generates libvirt domain XML.
#
{ lib }:

rec {
  # ===========================================================================
  # Helper Functions
  # ===========================================================================

  # Generate XML tag with optional attributes and content
  mkTag = tag: attrs: content:
    let
      attrStr = lib.concatStringsSep " " (
        lib.mapAttrsToList (k: v: ''${k}="${toString v}"'') (lib.filterAttrs (_: v: v != null) attrs)
      );
      attrSpace = if attrStr != "" then " " else "";
    in
    if content == ""
    then "<${tag}${attrSpace}${attrStr}/>"
    else "<${tag}${attrSpace}${attrStr}>${content}</${tag}>";

  # Parse PCI address from "0000:01:00.0" to components
  parsePciAddress = addr:
    let
      parts = lib.splitString ":" addr;
      domain = builtins.head parts;
      bus = builtins.elemAt parts 1;
      slotFunc = lib.splitString "." (builtins.elemAt parts 2);
      slot = builtins.head slotFunc;
      function = builtins.elemAt slotFunc 1;
    in {
      domain = "0x${domain}";
      bus = "0x${bus}";
      slot = "0x${slot}";
      function = "0x${function}";
    };

  # ===========================================================================
  # XML Generators
  # ===========================================================================

  # Generate memory XML
  genMemory = cfg:
    if cfg.memory.hugepages.enable
    then ''
      <memory unit="${cfg.memory.unit}">${toString cfg.memory.amount}</memory>
      <currentMemory unit="${cfg.memory.unit}">${toString cfg.memory.amount}</currentMemory>
      <memoryBacking>
        <hugepages>
          <page size="${toString cfg.memory.hugepages.size}" unit="GiB"/>
        </hugepages>
      </memoryBacking>
    ''
    else ''
      <memory unit="${cfg.memory.unit}">${toString cfg.memory.amount}</memory>
      <currentMemory unit="${cfg.memory.unit}">${toString cfg.memory.amount}</currentMemory>
    '';

  # Generate vCPU XML
  genVcpu = cfg:
    mkTag "vcpu" { placement = cfg.vcpu.placement; } (toString cfg.vcpu.count);

  # Generate CPU XML
  genCpu = cfg:
    let
      topologyXml = if cfg.cpu.topology != null
        then mkTag "topology" {
          sockets = cfg.cpu.topology.sockets;
          dies = cfg.cpu.topology.dies;
          cores = cfg.cpu.topology.cores;
          threads = cfg.cpu.topology.threads;
        } ""
        else "";

      featuresXml = lib.concatMapStringsSep "\n    " (feature:
        mkTag "feature" { policy = feature.policy; name = feature.name; } ""
      ) cfg.cpu.feature;

      cpuContent = if (topologyXml != "" || featuresXml != "")
        then ''
          ${topologyXml}
          ${featuresXml}''
        else "";
    in
    if cpuContent != ""
      then "<cpu mode=\"${cfg.cpu.mode}\">\n    ${cpuContent}\n  </cpu>"
      else mkTag "cpu" { mode = cfg.cpu.mode; } "";

  # Generate CPU tuning XML
  genCputune = cfg:
    if cfg.cputune == null then ""
    else
      let
        vcpupinXml = lib.concatMapStringsSep "\n    " (pin:
          mkTag "vcpupin" { vcpu = pin.vcpu; cpuset = pin.cpuset; } ""
        ) cfg.cputune.vcpupin;

        emulatorpinXml = if cfg.cputune.emulatorpin != null
          then mkTag "emulatorpin" { cpuset = cfg.cputune.emulatorpin.cpuset; } ""
          else "";
      in
      ''
        <cputune>
          ${vcpupinXml}
          ${emulatorpinXml}
        </cputune>
      '';

  # Generate OS XML
  genOs = cfg:
    let
      loaderXml = if cfg.os.loader != null
        then mkTag "loader" {
          readonly = if cfg.os.loader.readonly then "yes" else "no";
          type = cfg.os.loader.type;
          secure = if cfg.os.loader.secure then "yes" else "no";
        } cfg.os.loader.path
        else "";

      nvramXml = if cfg.os.nvram != null
        then mkTag "nvram" { template = cfg.os.nvram.template; } cfg.os.nvram.path
        else "";
    in
    ''
      <os>
        <type arch="${cfg.os.arch}" machine="${cfg.os.machine}">${cfg.os.type}</type>
        ${loaderXml}
        ${nvramXml}
        <boot dev="hd"/>
      </os>
    '';

  # Generate features XML
  genFeatures = cfg:
    let
      hypervXml = if cfg.features.hyperv != null
        then lib.concatStringsSep "\n      " (
          lib.mapAttrsToList (name: feat:
            let
              attrs = { state = feat.state; } //
                      (if feat.retries != null then { retries = feat.retries; } else {}) //
                      (if feat.value != null then { value = feat.value; } else {});
            in
            mkTag name attrs ""
          ) cfg.features.hyperv
        )
        else "";

      kvmXml = if cfg.features.kvm != null
        then lib.concatStringsSep "\n      " (
          lib.mapAttrsToList (name: feat:
            mkTag name { state = feat.state; } ""
          ) cfg.features.kvm
        )
        else "";

      vmportXml = if cfg.features.vmport != null
        then mkTag "vmport" { state = cfg.features.vmport.state; } ""
        else "";

      ioapicXml = if cfg.features.ioapic != null
        then mkTag "ioapic" { driver = cfg.features.ioapic.driver; } ""
        else "";
    in
    ''
      <features>
        ${lib.optionalString cfg.features.acpi "<acpi/>"}
        ${lib.optionalString cfg.features.apic "<apic/>"}
        ${lib.optionalString cfg.features.pae "<pae/>"}
        ${lib.optionalString (cfg.features.hyperv != null) ''
          <hyperv mode="custom">
            ${hypervXml}
          </hyperv>
        ''}
        ${lib.optionalString (cfg.features.kvm != null) ''
          <kvm>
            ${kvmXml}
          </kvm>
        ''}
        ${vmportXml}
        ${ioapicXml}
      </features>
    '';

  # Generate clock XML
  genClock = cfg:
    let
      timersXml = lib.concatStringsSep "\n      " (
        lib.mapAttrsToList (name: timer:
          let
            attrs = {} //
                    (if timer.present != null then { present = if timer.present then "yes" else "no"; } else {}) //
                    (if timer.tickpolicy != null then { tickpolicy = timer.tickpolicy; } else {});
          in
          mkTag name attrs ""
        ) cfg.clock.timers
      );
    in
    ''
      <clock offset="${cfg.clock.offset}">
        ${timersXml}
      </clock>
    '';

  # Generate disk XML
  genDisk = disk:
    let
      driverAttrs = { name = disk.driver.name; } //
                    (if disk.driver.type != null then { type = disk.driver.type; } else {}) //
                    (if disk.driver.cache != null then { cache = disk.driver.cache; } else {}) //
                    (if disk.driver.io != null then { io = disk.driver.io; } else {}) //
                    (if disk.driver.discard != null then { discard = disk.driver.discard; } else {});

      sourceXml = if disk.source.file != null
        then mkTag "source" { file = disk.source.file; } ""
        else if disk.source.dev != null
        then mkTag "source" { dev = disk.source.dev; } ""
        else "";

      bootXml = if disk.boot != null
        then mkTag "boot" { order = disk.boot.order; } ""
        else "";
    in
    ''
      <disk type="${disk.type}" device="${disk.device}">
        ${mkTag "driver" driverAttrs ""}
        ${sourceXml}
        ${mkTag "target" { dev = disk.target.dev; bus = disk.target.bus; } ""}
        ${lib.optionalString disk.readonly "<readonly/>"}
        ${bootXml}
      </disk>
    '';

  # Generate hostdev XML (PCI passthrough)
  genHostdev = hostdev:
    let
      addressXml = if hostdev.source.address != null
        then mkTag "address" {
          domain = hostdev.source.address.domain;
          bus = hostdev.source.address.bus;
          slot = hostdev.source.address.slot;
          function = hostdev.source.address.function;
        } ""
        else "";
    in
    ''
      <hostdev mode="${hostdev.mode}" type="${hostdev.type}" managed="${if hostdev.managed then "yes" else "no"}">
        <source>
          ${addressXml}
        </source>
      </hostdev>
    '';

  # Generate shmem XML
  genShmem = shmem:
    ''
      <shmem name="${shmem.name}">
        <model type="${shmem.model.type}"/>
        <size unit="${shmem.size.unit}">${toString shmem.size.amount}</size>
      </shmem>
    '';

  # Generate interface XML
  genInterface = iface:
    let
      sourceAttrs = {} //
                    (if iface.source.network != null then { network = iface.source.network; } else {}) //
                    (if iface.source.bridge != null then { bridge = iface.source.bridge; } else {}) //
                    (if iface.source.dev != null then { dev = iface.source.dev; } else {}) //
                    (if iface.source.mode != null then { mode = iface.source.mode; } else {});
    in
    ''
      <interface type="${iface.type}">
        ${mkTag "source" sourceAttrs ""}
        <model type="${iface.model.type}"/>
      </interface>
    '';

  # Generate graphics XML
  genGraphics = graphics:
    let
      listenXml = if graphics.listen != null
        then mkTag "listen" { type = graphics.listen.type; address = graphics.listen.address; } ""
        else "";

      imageXml = if graphics.image != null
        then mkTag "image" { compression = graphics.image.compression; } ""
        else "";
    in
    ''
      <graphics type="${graphics.type}">
        ${listenXml}
        ${imageXml}
      </graphics>
    '';

  # Generate TPM XML
  genTpm = tpm:
    ''
      <tpm model="${tpm.model}">
        <backend type="${tpm.backend.type}" version="${tpm.backend.version}"/>
      </tpm>
    '';

  # Generate devices XML
  genDevices = cfg:
    let
      disksXml = lib.concatMapStringsSep "\n    " genDisk cfg.devices.disks;
      hostdevsXml = lib.concatMapStringsSep "\n    " genHostdev cfg.devices.hostdevs;
      shmemXml = lib.concatMapStringsSep "\n    " genShmem cfg.devices.shmem;
      interfacesXml = lib.concatMapStringsSep "\n    " genInterface cfg.devices.interfaces;
      graphicsXml = lib.concatMapStringsSep "\n    " genGraphics cfg.devices.graphics;
      tpmXml = if cfg.devices.tpm != null then genTpm cfg.devices.tpm else "";
    in
    ''
      <devices>
        <emulator>/run/libvirt/nix-emulators/qemu-system-x86_64</emulator>
        ${disksXml}
        ${hostdevsXml}
        ${shmemXml}
        ${interfacesXml}
        ${graphicsXml}
        ${tpmXml}
        <console type="pty">
          <target type="serial" port="0"/>
        </console>
        <channel type="unix">
          <target type="virtio" name="org.qemu.guest_agent.0"/>
        </channel>
      </devices>
    '';

  # ===========================================================================
  # Main XML Generator
  # ===========================================================================

  generateDomainXML = cfg:
    ''
      <domain type="kvm">
        <name>${cfg.name}</name>
        ${lib.optionalString (cfg.title != "") "<title>${cfg.title}</title>"}
        ${lib.optionalString (cfg.description != "") "<description>${cfg.description}</description>"}
        <metadata>
          <libosinfo:libosinfo xmlns:libosinfo="http://libosinfo.org/xmlns/libvirt/domain/1.0">
            <libosinfo:os id="http://microsoft.com/win/11"/>
          </libosinfo:libosinfo>
        </metadata>
        ${genMemory cfg}
        ${genVcpu cfg}
        ${genCpu cfg}
        ${genCputune cfg}
        ${genOs cfg}
        ${genFeatures cfg}
        ${genClock cfg}
        <on_poweroff>destroy</on_poweroff>
        <on_reboot>restart</on_reboot>
        <on_crash>destroy</on_crash>
        <pm>
          <suspend-to-mem enabled="no"/>
          <suspend-to-disk enabled="no"/>
        </pm>
        ${genDevices cfg}
      </domain>
    '';
}
