class MedSchedule {
  const MedSchedule({
    required this.id,
    required this.medicationName,
    required this.dosage,
    required this.time24h,
    required this.enabled,
    this.drawerIndex,
  });

  final String id;
  final String medicationName;
  final String dosage;
  final String time24h;
  final bool enabled;
  final int? drawerIndex;

  factory MedSchedule.create({
    required String id,
    required String medicationName,
    required String dosage,
    required String time24h,
    required bool enabled,
    int? drawerIndex,
  }) {
    return MedSchedule(
      id: id,
      medicationName: medicationName,
      dosage: dosage,
      time24h: time24h,
      enabled: enabled,
      drawerIndex: drawerIndex,
    );
  }

  factory MedSchedule.fromMap(String id, Map<String, dynamic> map) {
    return MedSchedule(
      id: id,
      medicationName: map['medicationName'] as String? ?? 'Medication',
      dosage: map['dosage'] as String? ?? '1 tablet',
      time24h: map['time24h'] as String? ?? '08:00',
      enabled: map['enabled'] as bool? ?? true,
      drawerIndex: map['drawerIndex'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'medicationName': medicationName,
      'dosage': dosage,
      'time24h': time24h,
      'enabled': enabled,
      'drawerIndex': drawerIndex,
    };
  }

  Map<String, dynamic> toScheduleJsonMap(int fallbackDrawerIndex) {
    final parts = time24h.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts.first) ?? 0 : 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    return {
      'drawer': drawerIndex ?? fallbackDrawerIndex,
      'hour': hour,
      'minute': minute,
      'name': medicationName,
      'dosage': dosage,
      'time': time24h,
    };
  }
}
