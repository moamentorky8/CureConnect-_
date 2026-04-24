class DoseLog {
  const DoseLog({
    required this.id,
    required this.drawer,
    required this.status,
    required this.batteryPercent,
    required this.scheduledFor,
    required this.loggedAt,
  });

  final String id;
  final int drawer;
  final String status;
  final double batteryPercent;
  final DateTime scheduledFor;
  final DateTime loggedAt;

  factory DoseLog.fromMap(String id, Map<String, dynamic> map) {
    return DoseLog(
      id: id,
      drawer: map['drawer'] as int? ?? 1,
      status: map['status'] as String? ?? 'unknown',
      batteryPercent: (map['batteryPercent'] as num?)?.toDouble() ?? 0,
      scheduledFor:
          DateTime.tryParse(map['scheduledFor'] as String? ?? '') ?? DateTime.now(),
      loggedAt: DateTime.tryParse(map['loggedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
