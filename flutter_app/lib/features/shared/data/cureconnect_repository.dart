import 'dart:convert';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../../dashboard/domain/entities/device_snapshot.dart';
import '../../logs/domain/entities/dose_log.dart';
import '../../schedules/domain/entities/med_schedule.dart';

const defaultDeviceId = 'device-001';

final repositoryProvider = Provider<CureConnectRepository>((ref) {
  return CureConnectRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    rtdb: FirebaseDatabase.instance,
    googleSignIn: GoogleSignIn.instance,
    audioPlayer: AudioPlayer(),
    httpClient: http.Client(),
  );
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(repositoryProvider).authStateChanges();
});

final deviceSnapshotProvider = StreamProvider<DeviceSnapshot>((ref) {
  return ref.watch(repositoryProvider).watchDeviceSnapshot(defaultDeviceId);
});

final schedulesProvider = StreamProvider<List<MedSchedule>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value(const []);
  }
  return ref.watch(repositoryProvider).watchSchedules(user.uid);
});

final logsProvider = StreamProvider<List<DoseLog>>((ref) {
  return ref.watch(repositoryProvider).watchLogs(defaultDeviceId);
});

class CureConnectRepository {
  CureConnectRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required FirebaseDatabase rtdb,
    required GoogleSignIn googleSignIn,
    required AudioPlayer audioPlayer,
    required http.Client httpClient,
  })  : _auth = auth,
        _firestore = firestore,
        _rtdb = rtdb,
        _googleSignIn = googleSignIn,
        _audioPlayer = audioPlayer,
        _httpClient = httpClient;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseDatabase _rtdb;
  final GoogleSignIn _googleSignIn;
  final AudioPlayer _audioPlayer;
  final http.Client _httpClient;

  static const _elevenLabsApiKey = String.fromEnvironment('ELEVENLABS_API_KEY');
  static const _elevenLabsVoiceId = String.fromEnvironment('ELEVENLABS_VOICE_ID');
  static const _elevenLabsModelId = String.fromEnvironment(
    'ELEVENLABS_MODEL_ID',
    defaultValue: 'eleven_multilingual_v2',
  );

  Stream<User?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user != null) {
        await _syncUserProfile(user);
      }
      return user;
    });
  }

  Future<void> signIn({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (credential.user != null) {
      await _syncUserProfile(credential.user!);
    }
  }

  Future<void> signInWithGoogle() async {
    await _googleSignIn.initialize();
    final account = await _googleSignIn.authenticate();
    final authData = account.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: authData.idToken,
    );

    final result = await _auth.signInWithCredential(credential);
    if (result.user != null) {
      await _syncUserProfile(result.user!);
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _audioPlayer.stop();
    await _auth.signOut();
  }

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

  Stream<List<MedSchedule>> watchSchedules(String uid) {
    return _rtdb.ref('users/$uid/schedules/items').onValue.map((event) {
      final rawMap = (event.snapshot.value as Map?) ?? const {};
      final items = rawMap.entries
          .map((entry) => MedSchedule.fromMap(
                entry.key.toString(),
                Map<String, dynamic>.from(entry.value as Map),
              ))
          .toList()
        ..sort((a, b) => a.time24h.compareTo(b.time24h));
      return items;
    });
  }

  Stream<List<DoseLog>> watchLogs(String deviceId) {
    return _firestore
        .collection('devices')
        .doc(deviceId)
        .collection('logs')
        .orderBy('loggedAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DoseLog.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> upsertSchedule(String uid, MedSchedule schedule) async {
    await _rtdb.ref('users/$uid/schedules/items/${schedule.id}').set({
      ...schedule.toMap(),
      'updatedAt': ServerValue.timestamp,
    });
    await _syncScheduleJson(uid);
  }

  Future<void> deleteSchedule(String uid, String scheduleId) async {
    await _rtdb.ref('users/$uid/schedules/items/$scheduleId').remove();
    await _syncScheduleJson(uid);
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

  Future<void> triggerEmergencyAlert() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('You need to be signed in before sending an SOS alert.');
    }

    await _rtdb.ref('users/${user.uid}/emergency_status').set({
      'active': true,
      'message': 'Emergency assistance requested from the CureConnect mobile app.',
      'triggeredAt': ServerValue.timestamp,
      'triggeredBy': user.uid,
    });

    final audioBytes = await _requestElevenLabsAudio(
      text:
          'Emergency alert from CureConnect. Immediate assistance is required for this patient.',
    );
    await _audioPlayer.play(BytesSource(audioBytes));
  }

  Future<void> _syncUserProfile(User user) async {
    final profileRef = _rtdb.ref('users/${user.uid}/profile');
    final snapshot = await profileRef.get();
    final existing = (snapshot.value as Map?) ?? const {};

    await profileRef.update({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName ?? existing['displayName'],
      'photoUrl': user.photoURL ?? existing['photoUrl'],
      'providerId': user.providerData.isNotEmpty ? user.providerData.first.providerId : 'password',
      'lastLoginAt': ServerValue.timestamp,
      if (!snapshot.exists) 'createdAt': ServerValue.timestamp,
    });
  }

  Future<void> _syncScheduleJson(String uid) async {
    final snapshot = await _rtdb.ref('users/$uid/schedules/items').get();
    final rawMap = (snapshot.value as Map?) ?? const {};

    final items = rawMap.entries
        .map((entry) => MedSchedule.fromMap(
              entry.key.toString(),
              Map<String, dynamic>.from(entry.value as Map),
            ))
        .where((schedule) => schedule.enabled)
        .toList()
      ..sort((a, b) => a.time24h.compareTo(b.time24h));

    final scheduleJson = <Map<String, dynamic>>[];
    for (var index = 0; index < items.length; index++) {
      scheduleJson.add(items[index].toScheduleJsonMap(index % 10));
    }

    await _rtdb.ref('users/$uid/schedules').update({
      'schedule_json': scheduleJson,
      'lastSyncedAt': ServerValue.timestamp,
    });
  }

  Future<Uint8List> _requestElevenLabsAudio({required String text}) async {
    if (_elevenLabsApiKey.isEmpty || _elevenLabsVoiceId.isEmpty) {
      throw StateError(
        'Missing ElevenLabs configuration. Pass ELEVENLABS_API_KEY and ELEVENLABS_VOICE_ID with --dart-define.',
      );
    }

    final uri = Uri.parse(
      'https://api.elevenlabs.io/v1/text-to-speech/$_elevenLabsVoiceId',
    );

    final response = await _httpClient.post(
      uri,
      headers: {
        'Accept': 'audio/mpeg',
        'Content-Type': 'application/json',
        'xi-api-key': _elevenLabsApiKey,
      },
      body: jsonEncode({
        'text': text,
        'model_id': _elevenLabsModelId,
        'voice_settings': {
          'stability': 0.35,
          'similarity_boost': 0.8,
        },
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'ElevenLabs request failed with status ${response.statusCode}: ${response.body}',
      );
    }

    return response.bodyBytes;
  }
}
