{
  flake.nixosModules.hostSandbox =
    {
      lib,
      modulesPath,
      ...
    }:
    {
      imports = [
        (modulesPath + "/profiles/qemu-guest.nix")
      ];

      boot.initrd.availableKernelModules = [
        "virtio_pci"
        "virtio_blk"
        "xhci_pci"
        "usb_storage"
        "sd_mod"
      ];

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    };
}
