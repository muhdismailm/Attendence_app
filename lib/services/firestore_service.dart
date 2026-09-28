import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance_local.dart';

class FirestoreService {
  FirebaseFirestore? _firestore;

  FirebaseFirestore get _db {
    _firestore ??= FirebaseFirestore.instance;
    return _firestore!;
  }

  CollectionReference get attendanceCollection => _db.collection('attendance');

  /// Check active internet connectivity by looking up a reliable host
  Future<bool> checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
      return false;
    } catch (_) {
      try {
        // Fallback secondary check
        final fallback = await InternetAddress.lookup('firestore.googleapis.com')
            .timeout(const Duration(seconds: 3));
        return fallback.isNotEmpty && fallback[0].rawAddress.isNotEmpty;
      } catch (_) {
        return false;
      }
    }
  }

  /// Upload a single attendance record using deterministic document ID and .set(...)
  /// Never uses .add(...) to ensure idempotency and prevent duplicates.
  Future<bool> uploadAttendanceRecord(AttendanceLocal record) async {
    try {
      final docRef = attendanceCollection.doc(record.id);
      await docRef.set(record.toFirestoreMap(), SetOptions(merge: true));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Synchronize a list of pending attendance records to Firestore.
  /// Returns the list of record IDs that were successfully synced.
  /// If one fails, others will still proceed and failed ones remain pending.
  Future<List<String>> syncPendingBatch(List<AttendanceLocal> pendingRecords) async {
    if (pendingRecords.isEmpty) return [];

    final hasInternet = await checkInternetConnection();
    if (!hasInternet) {
      throw const SocketException('No internet connection available');
    }

    final List<String> successfullySyncedIds = [];

    // Sync records individually or in small batches using deterministic .set()
    for (var record in pendingRecords) {
      try {
        final docRef = attendanceCollection.doc(record.id);
        await docRef.set(record.toFirestoreMap(), SetOptions(merge: true));
        successfullySyncedIds.add(record.id);
      } catch (e) {
        // Continue with other records; this record will remain pending
      }
    }

    return successfullySyncedIds;
  }
}
