import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/domain/entities/device_snapshot.dart';
import '../../logs/domain/entities/dose_log.dart';
import '../../schedules/domain/entities/med_schedule.dart';

const defaultDeviceId = 'device-001';

final repositoryProvider = Provider<CureConnectRepository>((ref) {
  return CureConnectRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    rtdb: FirebaseDatabase.instance,
  );
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(repositoryProvider).authStateChanges();
});

final deviceSnapshotProvider = StreamProvider<DeviceSnapshot>((ref) {
  return ref.watch(repositoryProvider).watchDeviceSnapshot(defaultDeviceId);
});

final schedulesProvider = StreamProvider<List<MedSchedule>>((ref) {
  return ref.watch(repositoryProvider).watchSchedules(defaultDeviceId);
});

final logsProvider = StreamProvider<List<DoseLog>>((ref) {
  return ref.watch(repositoryProvider).watchLogs(defaultDeviceId);
});

class CureConnectRepository {
  CureConnectRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required FirebaseDatabase rtdb,
  })  : _auth = auth,
        _firestore = firestore,
        _rtdb = rtdb;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseDatabase _rtdb;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();

  Stream<DeviceSnapshot> watchDeviceSnapshot(String deviceId) {
    return _rtdb.ref('deviceState/$deviceId').onValue.map((event) {
      final map = Map<String, dynamic>.from(
        (event.snapshot.value as Map?) ??
            {
              'deviceName': 'CureConnect Unit',
              'batteryPercent': 76,
              'isOnline': false,
              'lastSync': DateTime.now().toIso8601String(),
              'lastDoseState': 'idle',
            },
      );
      return DeviceSnapshot.fromMap(deviceId, map);
    });
  }

  Stream<List<MedSchedule>> watchSchedules(String deviceId) {
    return _firestore
        .collection('devices')
        .doc(deviceId)
        .collection('schedules')
        .orderBy('time24h')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MedSchedule.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<DoseLog>> watchLogs(String deviceId) {
    return _firestore
        .collection('devices')
        .doc(deviceId)
        .collection('logs')
        .orderBy('loggedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => DoseLog.fromMap(doc.id, doc.data())).toList());
  }

  Future<void> upsertSchedule(String deviceId, MedSchedule schedule) async {
    await _firestore
        .collection('devices')
        .doc(deviceId)
        .collection('schedules')
        .doc(schedule.id)
        .set(schedule.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteSchedule(String deviceId, String scheduleId) async {
    await _firestore
        .collection('devices')
        .doc(deviceId)
        .collection('schedules')
        .doc(scheduleId)
        .delete();
  }

  Future<void> triggerDrawer(String deviceId, int drawer) async {
    await _rtdb.ref('commands/$deviceId').set({
      'type': 'remote_trigger',
      'drawer': drawer,
      'issuedAt': ServerValue.timestamp,
      'issuedBy': _auth.currentUser?.uid ?? 'unknown',
      'status': 'pending',
    });
  }
}
