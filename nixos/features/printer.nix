{ pkgs, ... }: {
  flake.nixosModules.printer = {
    services.printing = {
      enable = true;
      drivers = [ pkgs.canon-capt ];
      listenAddresses = [ "localhost:631" ];
      allowFrom = [ "localhost" ];
      defaultShared = false;
      extraConf = ''
        ServerAlias *
      '';
    };

    hardware.printers = {
      ensurePrinters = [
        {
          name = "Canon_LBP2900";
          deviceUri = "usb://Canon/LBP2900?serial=0000D29A1NRj";
          model = "canon/CanonLBP-2900-3000.ppd";
          ppdOptions = {
            PageSize = "iso_a4_210x297mm";
          };
        }
      ];
      ensureDefaultPrinter = "Canon_LBP2900";
    };

    systemd.services.smart-canon-proxy = let
      printCmd = pkgs.writeShellScript "ipp-to-lp" ''
        exec ${pkgs.cups}/bin/lp -d Canon_LBP2900 "$@"
      '';
    in {
      description = "Mopria IPP Proxy for Canon LBP2900";
      wantedBy = [ "multi-user.target" ];
      requires = [ "cups.service" "avahi-daemon.service" ];
      after = [ "cups.service" "avahi-daemon.service" ];
      serviceConfig = {
        ExecStart = "${pkgs.cups}/bin/ippeveprinter -k -p 8000 -c ${printCmd} Smart_Canon";
        Restart = "always";
        RestartSec = "3s";
      };
    };

    networking.firewall.allowedTCPPorts = [ 8000 ];

    services.avahi = {
      enable = true;
      nssmdns4 = true;
      nssmdns6 = true;
      openFirewall = true;
      publish = {
        enable = true;
        userServices = true;
      };
    };
  };
}
