{ ... }: {
  flake.nixosModules.qemu = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [ virt-manager ];
    
    virtualisation = {
      libvirtd.enable = true;
      spiceUSBRedirection.enable = true;
    };
    
    services = {
      spice-autorandr.enable = true;
      spice-vdagentd.enable = true;
    };
    
    networking.firewall.trustedInterfaces = [ "virbr0" ];
    programs.dconf.enable = true;
  };
}
