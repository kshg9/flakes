{ ... }: {
  flake.nixosModules.android = { pkgs, config, lib, ... }: let
    predefine = pkgs.androidenv.androidPkgs;
    buildToolsVersion = (builtins.head predefine.build-tools).version;
    aapt2Path = "${predefine.androidsdk}/libexec/android-sdk/build-tools/${buildToolsVersion}/aapt2";
  in {
    config = lib.mkIf config.extras.android.enable {
      users.groups.adbusers.members = [ "kdj" ];
      virtualisation.waydroid.enable = true;
      
      environment.systemPackages = with pkgs; [
        android-tools
      ];

      hjem.users.kdj = {
        packages = [
          predefine.androidsdk
          (pkgs.androidStudioPackages.canary.override { tiling_wm = true; })
          pkgs.jdk17
        ];
        environment.sessionVariables = {
          ANDROID_HOME = "${predefine.androidsdk}/libexec/android-sdk";
          ANDROID_SDK_ROOT = "${predefine.androidsdk}/libexec/android-sdk";
          JAVA_HOME = "${pkgs.jdk17}";
          
          # Force Gradle to use the Nix-provided aapt2 (avoids download failures on read-only store)
          GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${aapt2Path}";
        };
      };
    };
  };
}
