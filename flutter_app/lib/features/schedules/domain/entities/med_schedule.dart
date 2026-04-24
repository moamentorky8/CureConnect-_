class MedSchedule {
  const MedSchedule({
    required this.id,
    required this.drawer,
    required this.label,
    required this.time24h,
    required this.days,
    required this.enabled,
  });

  final String id;
  final int drawer;
  final String label;
  final String time24h;
  final List<String> days;
  final bool enabled;

  factory MedSchedule.create({
    required String id,
    required int drawer,
    required String label,
    required String time24h,
    required List<String> days,
    required bool enabled,
  }) {
    return MedSchedule(
      id: id,
      drawer: drawer,
      label: label,
      time24h: time24h,
      days: days,
      enabled: enabled,
    );
  }

  factory MedSchedule.fromMap(String id, Map<String, dynamic> map) {
    return MedSchedule(
      id: id,
      drawer: map['drawer'] as int? ?? 1,
      label: map['label'] as String? ?? 'Medication',
      time24h: map['time24h'] as String? ?? '08:00',
      days: List<String>.from(map['days'] as List? ?? const []),
      enabled: map['enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'drawer': drawer,
      'label': label,
      'time24h': time24h,
      'days': days,
      'enabled': enabled,
    };
  }
}
