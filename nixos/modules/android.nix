{ ... }: {
  flake.nixosModules.android = { pkgs, config, lib, ... }: let
    customSdk = pkgs.androidenv.composeAndroidPackages {
      buildToolsVersions = [ "36.0.0" ];
      platformVersions = [ "37" ];
      includeSources = true;
      includeEmulator = true;
      includeSystemImages = true;
      systemImageTypes = [ "google_apis_playstore" ];
      abiVersions = [ "x86_64" ];
    };
    buildToolsVersion = (builtins.head customSdk.build-tools).version;
    aapt2Path = "${customSdk.androidsdk}/libexec/android-sdk/build-tools/${buildToolsVersion}/aapt2";
  in {
    config = lib.mkIf config.extras.android.enable {
      users.groups.adbusers.members = [ "kdj" ];
      users.groups.kvm.members = [ "kdj" ];
      virtualisation.waydroid.enable = true;
      
      environment.systemPackages = with pkgs; [
        android-tools
      ];

      hjem.users.kdj = {
        packages = [
          customSdk.androidsdk
          (pkgs.androidStudioPackages.canary.override { tiling_wm = true; })
          pkgs.jdk17
        ];
        environment.sessionVariables = {
          ANDROID_HOME = "${customSdk.androidsdk}/libexec/android-sdk";
          ANDROID_SDK_ROOT = "${customSdk.androidsdk}/libexec/android-sdk";
          JAVA_HOME = "${pkgs.jdk17}";
          
          # Force Gradle to use the Nix-provided aapt2 (avoids download failures on read-only store)
          GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${aapt2Path}";
        };
      };
    };
  };
}
