{
  lib,
  stdenv,
  buildPackages,
  autovirt,
  edk2-src,
  edk2,
  cpu ? "amd",

  nasm,
  acpica-tools,
  python3,
  bc,
  util-linux,
}:

let
  cpuLower = lib.toLower cpu;
  patchFile =
    if cpuLower == "amd" then
      "${./edk2.patch}"
    else
      "${autovirt}/patches/EDK2/Intel-edk2-stable202602.patch";

  pythonEnv = buildPackages.python3.withPackages (ps: [ ps.distlib ]);
  targetArch = "X64";
in
stdenv.mkDerivation {
  pname = "barely-metal-ovmf";
  version = "202602-barely-metal";

  src = edk2.src;

  depsBuildBuild = [ buildPackages.stdenv.cc ];

  nativeBuildInputs = [
    bc
    pythonEnv
    util-linux
    nasm
    acpica-tools
  ];

  hardeningDisable = [
    "format"
    "stackprotector"
    "pic"
    "fortify"
  ];

  env.GCC5_X64_PREFIX = stdenv.cc.targetPrefix;

  prePatch = ''
    rm -rf BaseTools
    ln -sv ${buildPackages.edk2}/BaseTools BaseTools
  '';

  postPatch = ''
    patch -p1 < ${patchFile}
  '';

  configurePhase = ''
    runHook preConfigure
    export WORKSPACE="$PWD"
    . ${buildPackages.edk2}/edksetup.sh BaseTools
    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    build \
      -p OvmfPkg/OvmfPkgX64.dsc \
      -a ${targetArch} \
      -t GCC5 \
      -b RELEASE \
      -n $NIX_BUILD_CORES \
      -s \
      -D SECURE_BOOT_ENABLE=TRUE \
      -D SMM_REQUIRE=TRUE \
      -D TPM1_ENABLE=TRUE \
      -D TPM2_ENABLE=TRUE \
      -D FD_SIZE_4MB \
      -D NETWORK_IP6_ENABLE=TRUE

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/FV
    cp -v Build/OvmfX64/RELEASE_GCC5/FV/OVMF_CODE.fd $out/FV/
    cp -v Build/OvmfX64/RELEASE_GCC5/FV/OVMF_VARS.fd $out/FV/
    cp -v Build/OvmfX64/RELEASE_GCC5/FV/OVMF.fd $out/FV/

    runHook postInstall
  '';

  enableParallelBuilding = true;
  doCheck = false;
  requiredSystemFeatures = [ "big-parallel" ];

  passthru = {
    firmware = "${placeholder "out"}/FV/OVMF_CODE.fd";
    variables = "${placeholder "out"}/FV/OVMF_VARS.fd";
  };

  meta = {
    description = "OVMF/EDK2 firmware with anti-VM-detection patches (BarelyMetal/AutoVirt)";
    homepage = "https://github.com/Scrut1ny/AutoVirt";
    license = lib.licenses.bsd2;
    platforms = [ "x86_64-linux" ];
  };
}
