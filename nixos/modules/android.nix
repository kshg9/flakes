{ inputs, ... }: {
  flake.nixosModules.android = { pkgs, config, lib, ... }: let
    android-sdk = inputs.android-nixpkgs.sdk.${pkgs.stdenv.hostPlatform.system} (sdkPkgs: with sdkPkgs; [
      cmdline-tools-latest
      build-tools-36-0-0
      platform-tools
      platforms-android-37-0
      sources-android-37-0
      emulator
    ]);
  in {
    config = lib.mkIf config.extras.android.enable {
      users.groups.adbusers.members = [ "kdj" ];
      virtualisation.waydroid.enable = true;
      
      environment.systemPackages = with pkgs; [
        android-tools
      ];

      hjem.users.kdj = {
        packages = [
          android-sdk
          pkgs.androidStudioPackages.stable
          pkgs.jdk17
        ];
        environment.sessionVariables = {
          ANDROID_HOME = "${android-sdk}/libexec/android-sdk";
          ANDROID_SDK_ROOT = "${android-sdk}/libexec/android-sdk";
          JAVA_HOME = "${pkgs.jdk17}";
        };
      };
    };
  };
}
