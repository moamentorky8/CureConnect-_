{ pkgs, ... }: {
  # اختيار قناة النسخ المستقرة لضمان أفضل أداء
  channel = "stable-24.11";

  # تعريف الأدوات البرمجية اللي IDX محتاجها عشان يشغل فلاتر
  packages = [
    pkgs.flutter
    pkgs.jdk17
    pkgs.android-tools
  ];

  # إعدادات البيئة الافتراضية
  env = {};

  idx = {
    # الإضافات (Extensions) اللي هتساعدك في كتابة كود فلاتر
    extensions = [
      "Dart-Code.flutter"
      "Dart-Code.dart"
    ];

    # تفعيل واجهة العرض (Preview) عشان الموبايل يظهر على اليمين
    previews = {
      enable = true;
      previews = {
        # إعداد تشغيل المحاكي (Android Emulator)
        android = {
          command = [
            "flutter"
            "run"
            "--machine"
            "-d"
            "android"
            "-d"
            "emulator-5554"
          ];
          manager = "flutter";
        };
      };
    };

    # الأوامر اللي هتتنفذ أول ما البيئة تشتغل (أوتوماتيك)
    onCreate = {
      # هيدخل فولدر flutter_app ويحمل المكتبات لوحدها
      install-dependencies = "cd flutter_app && flutter pub get";
    };
  };
}
