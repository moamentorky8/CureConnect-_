class DeviceSnapshot {
  const DeviceSnapshot({
    required this.deviceId,
    required this.deviceName,
    required this.batteryPercent,
    required this.isOnline,
    required this.lastSync,
    required this.lastDoseState,
    required this.pendingCommandDrawer,
  });

  final String deviceId;
  final String deviceName;
  final double batteryPercent;
  final bool isOnline;
  final DateTime lastSync;
  final String lastDoseState;
  final int? pendingCommandDrawer;

  factory DeviceSnapshot.fromMap(String id, Map<String, dynamic> map) {
    return DeviceSnapshot(
      deviceId: id,
      deviceName: map['deviceName'] as String? ?? 'CureConnect Unit',
      batteryPercent: (map['batteryPercent'] as num?)?.toDouble() ?? 0,
      isOnline: map['isOnline'] as bool? ?? false,
      lastSync: DateTime.tryParse(map['lastSync'] as String? ?? '') ?? DateTime.now(),
      lastDoseState: map['lastDoseState'] as String? ?? 'idle',
      pendingCommandDrawer: map['pendingCommandDrawer'] as int?,
    );
  }
}
