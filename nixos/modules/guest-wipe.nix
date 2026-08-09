# Self-cleaning guest: wipes the restricted guest's home on a configured cadence so
# it returns to a pristine state even without a reboot. (Under impermanence the
# home is ALSO wiped on boot — this timer covers the uptime-in-between.)
{ ... }: {
  flake.nixosModules.guestWipe =
    { lib, config, ... }:
    let
      cfg = config.guestWipe;
    in
    {
      options.guestWipe = {
        users = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "List of guest users to wipe regularly.";
        };
        schedule = lib.mkOption {
          type = lib.types.str;
          default = "weekly";
          description = "systemd OnCalendar schedule for the wipe.";
        };
      };

      config = lib.mkIf (cfg.users != []) {
        systemd.services = lib.genAttrs (map (u: "${u}-wipe") cfg.users) (name:
          let
            guest = lib.removeSuffix "-wipe" name;
          in
          {
            description = "Wipe ${guest}'s home back to a pristine state";
            serviceConfig.Type = "oneshot";
            script = ''
              # Log out any live session, then blow away everything they created.
              loginctl terminate-user ${guest} 2>/dev/null || true
              sleep 1
              rm -rf /home/${guest}
              # Recreate the (empty, correctly-owned) home. hjem re-links the
              # managed dotfiles on next login; createHome supplies the skeleton.
              install -d -o ${guest} -g users -m 700 /home/${guest}
            '';
          }
        );

        systemd.timers = lib.genAttrs (map (u: "${u}-wipe") cfg.users) (name:
          let
            guest = lib.removeSuffix "-wipe" name;
          in
          {
            description = "${cfg.schedule} ${guest} home wipe";
            wantedBy = [ "timers.target" ];
            timerConfig = {
              Persistent = true;
              OnCalendar = cfg.schedule;
            };
          }
        );
      };
    };
}