import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class RoomService {
  static bool get isAvailable => Firebase.apps.isNotEmpty;

  final Random _random = Random();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  Future<String> ensureIdentity() async {
    if (!isAvailable) {
      throw StateError('Firebase is not configured for this app.');
    }
    var user = _auth.currentUser;
    user ??= (await _auth.signInAnonymously()).user;
    if (user == null) {
      throw StateError('Could not create an anonymous participant identity.');
    }
    return user.uid;
  }

  Future<String> createRoom({
    required String gate,
    required String budget,
  }) async {
    final uid = await ensureIdentity();
    for (var attempt = 0; attempt < 20; attempt++) {
      final code = (1000 + _random.nextInt(9000)).toString();
      final roomRef = _firestore.collection('rooms').doc(code);
      final snapshot = await roomRef.get();
      if (snapshot.exists) continue;

      await roomRef.set({
        'gate': gate,
        'budget': budget,
        'hostId': uid,
        'status': 'waiting',
        'createdAt': FieldValue.serverTimestamp(),
        'participants': {
          uid: {'progress': 0, 'finished': false},
        },
      });
      return code;
    }
    throw StateError('Could not generate a unique room code.');
  }

  Future<String> joinRoom(String code) async {
    final uid = await ensureIdentity();
    final roomRef = _firestore.collection('rooms').doc(code);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) {
        throw StateError('Room $code was not found.');
      }
      final data = snapshot.data()!;
      if (data['status'] == 'finished') {
        throw StateError('This room has already finished.');
      }
      final participants = Map<String, dynamic>.from(
        data['participants'] as Map,
      );
      participants.putIfAbsent(uid, () => {'progress': 0, 'finished': false});
      transaction.update(roomRef, {
        'participants': participants,
        'status': 'matching',
      });
    });
    return uid;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchRoom(String code) {
    return _firestore.collection('rooms').doc(code).snapshots();
  }

  Future<void> recordSwipe({
    required String code,
    required String memberId,
    required String spotId,
    required String direction,
    required int progress,
    required int deckLength,
  }) async {
    final roomRef = _firestore.collection('rooms').doc(code);
    final voteRef = roomRef.collection('votes').doc(memberId);
    await _firestore.runTransaction((transaction) async {
      final roomSnapshot = await transaction.get(roomRef);
      if (!roomSnapshot.exists) return;
      final data = roomSnapshot.data()!;
      final participants = Map<String, dynamic>.from(
        data['participants'] as Map,
      );
      participants[memberId] = {
        'progress': progress,
        'finished': progress >= deckLength,
      };

      final voteSnapshot = await transaction.get(voteRef);
      final voteData = voteSnapshot.data() ?? <String, dynamic>{};
      final swipes = Map<String, dynamic>.from(
        voteData['swipes'] as Map? ?? const {},
      );
      swipes[spotId] = direction;

      transaction.set(voteRef, {
        'swipes': swipes,
        'progress': progress,
      }, SetOptions(merge: true));
      transaction.update(roomRef, {'participants': participants});
    });
  }

  Future<String?> finalizeWinner(String code, List<String> spotIds) async {
    final roomRef = _firestore.collection('rooms').doc(code);
    final roomSnapshot = await roomRef.get();
    if (roomSnapshot.data()?['winnerId'] != null) {
      return roomSnapshot.data()!['winnerId'] as String;
    }

    final votes = await roomRef.collection('votes').get();
    final scores = <String, int>{for (final spotId in spotIds) spotId: 0};

    for (final vote in votes.docs) {
      final swipes = Map<String, dynamic>.from(
        vote.data()['swipes'] as Map? ?? const {},
      );
      for (final entry in swipes.entries) {
        if (entry.value == 'right' || entry.value == 'superLike') {
          scores[entry.key] = (scores[entry.key] ?? 0) + 1;
        }
      }
    }

    final bestScore = scores.values.fold<int>(
      0,
      (maximum, score) => max(maximum, score),
    );
    if (bestScore == 0) return null;

    final topIds = scores.entries
        .where((entry) => entry.value == bestScore)
        .map((entry) => entry.key)
        .toList();
    final winnerId = topIds[_random.nextInt(topIds.length)];

    await roomRef.set({
      'winnerId': winnerId,
      'status': 'finished',
    }, SetOptions(merge: true));
    return winnerId;
  }
}
