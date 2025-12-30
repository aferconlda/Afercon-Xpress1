{pkgs}: {
  channel = "stable-24.05";
  packages = [
    pkgs.jdk17
    pkgs.unzip
    pkgs.ruby
    pkgs.fastlane
    pkgs.cmake
    pkgs.android-tools
  ];
  env = {
    ANDROID_SDK_ROOT = "/home/user/.androidsdkroot";
    ANDROID_HOME = "/home/user/.androidsdkroot";
  };
  idx.extensions = [];
  idx.previews = {
    previews = {
      web = {
        command = [
          "flutter"
          "run"
          "--machine"
          "-d"
          "web-server"
          "--web-hostname"
          "0.0.0.0"
          "--web-port"
          "$PORT"
        ];
        manager = "flutter";
      };
      android = {
        command = [
          "flutter"
          "run"
          "--machine"
          "-d"
          "android"
          "-d"
          "localhost:5555"
        ];
        manager = "flutter";
      };
    };
  };
}