# Self-cleaning guest: wipes the restricted guest's home on a weekly cadence so
# it returns to a pristine state even without a reboot. (Under impermanence the
# home is ALSO wiped on boot — this timer covers the uptime-in-between.)
# Wired into uriel only; the sandbox `biyoo` dev user is NOT subject to this.
{ ... }: {
  flake.nixosModules.guestWipe =
    let
      guest = "yjh";
    in
    {
      systemd.services."${guest}-wipe" = {
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
      };

      systemd.timers."${guest}-wipe" = {
        description = "Weekly ${guest} home wipe";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          Persistent = true;
          OnCalendar = "weekly";
        };
      };
    };
}