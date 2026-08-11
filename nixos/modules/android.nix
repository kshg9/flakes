{ ... }: {
  flake.nixosModules.android = { pkgs, config, lib, ... }: {
    config = lib.mkIf config.extras.android.enable {
      users.groups.adbusers.members = [ "kdj" ];
      virtualisation.waydroid.enable = true;
      
      environment.systemPackages = with pkgs; [
        android-tools
      ];

      hjem.users.kdj = {
        packages = [
          (pkgs.androidStudioPackages.stable.override { tiling_wm = true; })
          pkgs.jdk17
        ];
        environment.sessionVariables = {
          ANDROID_HOME = "$HOME/Android/Sdk";
          ANDROID_SDK_ROOT = "$HOME/Android/Sdk";
          JAVA_HOME = "${pkgs.jdk17}";
        };
      };
    };
  };
}
