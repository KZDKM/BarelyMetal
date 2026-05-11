{
  self,
  autovirt,
  qemu-src,
  edk2-src,
}:

{
  imports = [
    (import ./vm.nix {
      inherit
        self
        autovirt
        qemu-src
        edk2-src
        ;
    })
    (import ./looking-glass.nix)
  ];
}
