{ pkgs, ... }: {
  channel = "stable-24.11";
  packages = [
    pkgs.flutter
    pkgs.jdk17
    pkgs.android-tools
  ];
  idx = {
    extensions = [ "Dart-Code.flutter" ];
    previews = {
      enable = true;
      previews = {
        # إعداد تشغيل الأندرويد
        android = {
          command = [ "flutter" "run" "--machine" "-d" "android" "-d" "emulator-5554" ];
          manager = "flutter";
        };
      };
    };
  };
}
