import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';
import '../models/foodspot.dart';

class SavedSpotRecord {
  final String spotId;
  final String name;
  final String gate;
  final String streetAddress;
  final int walkingTimeMinutes;
  final int averageMealPhp;
  final String operatingHours;
  final String note;
  final bool visited;

  const SavedSpotRecord({
    required this.spotId,
    required this.name,
    required this.gate,
    required this.streetAddress,
    required this.walkingTimeMinutes,
    required this.averageMealPhp,
    required this.operatingHours,
    required this.note,
    required this.visited,
  });

  factory SavedSpotRecord.fromMap(Map<String, dynamic> data) {
    return SavedSpotRecord(
      spotId: data['spotId'] as String? ?? '',
      name: data['name'] as String? ?? 'Unknown Spot',
      gate: data['gate'] as String? ?? '',
      streetAddress: data['streetAddress'] as String? ?? '',
      walkingTimeMinutes: (data['walkingTimeMinutes'] as num?)?.toInt() ?? 0,
      averageMealPhp: (data['averageMealPhp'] as num?)?.toInt() ?? 0,
      operatingHours: data['operatingHours'] as String? ?? '',
      note: data['note'] as String? ?? '',
      visited: data['visited'] as bool? ?? false,
    );
  }
}

class SavedSpotsService {
  static const Duration _timeout = Duration(seconds: 8);

  Future<String> _ensureSignedIn() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    final auth = FirebaseAuth.instance;
    final user =
        auth.currentUser ??
        (await auth.signInAnonymously().timeout(_timeout)).user;
    if (user == null) {
      throw StateError('Could not initialize anonymous user session.');
    }
    return user.uid;
  }

  CollectionReference> _collectionFor(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('savedSpots');
  }

  /// CREATE / UPSERT
  Future<void> saveSpot({
    required FoodSpot spot,
    required String gate,
  }) async {
    final uid = await _ensureSignedIn();
    final docRef = _collectionFor(uid).doc(spot.id);
    final existing = await docRef.get().timeout(_timeout);
    final existingData = existing.data();

    await docRef
        .set({
          'spotId': spot.id,
          'name': spot.name.replaceAll(RegExp(r' \(.+\)$'), ''),
          'gate': gate,
          'streetAddress': spot.streetAddress,
          'walkingTimeMinutes': spot.walkingTimeMinutes,
          'averageMealPhp': spot.priceRangePhp.averageMeal,
          'operatingHours': spot.operatingHours,
          'note': existingData?['note'] as String? ?? '',
          'visited': existingData?['visited'] as bool? ?? false,
          'updatedAt': FieldValue.serverTimestamp(),
        })
        .timeout(_timeout);
  }

  /// READ
  Stream<List<SavedSpotRecord>> watchSavedSpots() async* {
    final uid = await _ensureSignedIn();
    yield* _collectionFor(uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SavedSpotRecord.fromMap(doc.data()))
              .toList(),
        );
  }

  /// UPDATE
  Future<void> updateSpot({
    required String spotId,
    String? note,
    bool? visited,
  }) async {
    if (note != null && note.trim().length > 120) {
      throw ArgumentError('Keep notes under 120 characters.');
    }
    final uid = await _ensureSignedIn();
    await _collectionFor(uid)
        .doc(spotId)
        .update({
          if (note != null) 'note': note.trim(),
          if (visited != null) 'visited': visited,
          'updatedAt': FieldValue.serverTimestamp(),
        })
        .timeout(_timeout);
  }

  /// DELETE
  Future<void> deleteSpot(String spotId) async {
    final uid = await _ensureSignedIn();
    await _collectionFor(uid).doc(spotId).delete().timeout(_timeout);
  }
}