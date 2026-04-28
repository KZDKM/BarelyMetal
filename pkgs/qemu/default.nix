{
  lib,
  qemu,
  autovirt,
  cpu ? "amd",

  acpiOemId ? "ALASKA",
  acpiOemTableId ? "A M I   ",
  acpiCreatorId ? "ACPI",
  acpiPmProfile ? 1,
  smbiosManufacturer ? "Advanced Micro Devices, Inc.",
  spoofModels ? true,
  spoofUsbSerials ? false,
  ideModel ? null,
  nvmeModel ? null,
  cdModel ? null,
  cfataModel ? null,
}:

let
  cpuLower = lib.toLower cpu;
  patchFile =
    if cpuLower == "amd" then
      "${./qemu.patch}"
    else
      "${autovirt}/patches/QEMU/Intel-v10.2.0.patch";

  selectedIdeModel =
    if ideModel != null then ideModel else "Samsung SSD 870 EVO 1TB";
  selectedNvmeModel =
    if nvmeModel != null then nvmeModel else "Samsung 990 PRO 2TB";
  selectedCdModel =
    if cdModel != null then cdModel else "HL-DT-ST BD-RE WH16NS60";
  selectedCfataModel =
    if cfataModel != null then cfataModel else "Hitachi HMS360404D5CF00";
in
(qemu.override {
  hostCpuTargets = [ "x86_64-softmmu" ];
  smbdSupport = false;
}).overrideAttrs (old: {
  pname = "barely-metal-qemu";

  patches = (old.patches or []) ++ [ patchFile ];

  postInstall = (old.postInstall or "") + ''
    ln -sf $out/bin/qemu-system-x86_64 $out/bin/qemu-kvm
  '';

  meta = (old.meta or {}) // {
    description = "QEMU with anti-VM-detection patches (BarelyMetal/AutoVirt)";
    mainProgram = "qemu-system-x86_64";
  };
})
