{
  description = "FlutterDev environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            android_sdk.accept_license = true;
          };
        };

        androidComposition = pkgs.androidenv.composeAndroidPackages {
          buildToolsVersions = [ "28.0.3" "34.0.0" ];
          platformVersions = [ "36" ];
          abiVersions = [ "x86_64" ];
          includeEmulator = false;
          includeSystemImages = false;
        };

      in {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.flutter
            pkgs.jdk17
            androidComposition.androidsdk
            pkgs.gradle
            pkgs.git
          ];

          ANDROID_SDK_ROOT = "${androidComposition.androidsdk}/libexec/android-sdk";
          JAVA_HOME = pkgs.jdk17;

          shellHook = ''
            export PATH=$ANDROID_SDK_ROOT/platform-tools:$PATH
            export ANDROID_HOME=$ANDROID_SDK_ROOT
            export ANDROID_SDK_HOME=$HOME/.android

            mkdir -p $ANDROID_SDK_HOME
            mkdir -p $ANDROID_SDK_HOME/licenses
            cp -r $ANDROID_SDK_ROOT/licenses/* $ANDROID_SDK_HOME/licenses/ 2>/dev/null || true

            echo "🚀 FlutterDev ready"
          '';
        };
      }
    );
}
