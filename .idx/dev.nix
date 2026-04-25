{ pkgs, ... }: {
  # قناة النسخ المستقرة لضمان أفضل أداء
  channel = "stable-24.11";

  # تعريف الأدوات المطلوبة لتشغيل فلاتر وأندرويد
  packages = [
    pkgs.flutter
    pkgs.jdk17
    pkgs.android-tools
  ];

  # إعدادات البيئة
  env = {};

  idx = {
    # الإضافات البرمجية المهمة للكود
    extensions = [
      "Dart-Code.flutter"
      "Dart-Code.dart"
    ];

    # تفعيل نافذة العرض (Preview) لتشغيل المحاكي السحابي
    previews = {
      enable = true;
      previews = {
        # تشغيل محاكي الأندرويد (الموبايل اللي هيظهر على اليمين)
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

    # الأوامر التي تنفذ عند إنشاء البيئة لأول مرة
    onCreate = {
      # سحب مكتبات فلاتر تلقائياً
      install-dependencies = "cd flutter_app && flutter pub get";
    };
  };
}
