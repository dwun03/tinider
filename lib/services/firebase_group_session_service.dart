import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../controllers/match_controller.dart';
import '../models/foodspot.dart';

class FirebaseGroupSession {
  final String roomCode;
  final String gate;
  final String budget;
  final String memberId;

  const FirebaseGroupSession({
    required this.roomCode,
    required this.gate,
    required this.budget,
    required this.memberId,
  });
}

class FirebaseGroupResults {
  final List<MatchResult> rankedMatches;

  const FirebaseGroupResults(this.rankedMatches);
}

class FirebaseGroupRoomState {
  final int expectedPlayers;
  final int joinedPlayers;
  final String status;

  const FirebaseGroupRoomState({
    required this.expectedPlayers,
    required this.joinedPlayers,
    required this.status,
  });
}

class FirebaseGroupSessionService {
  FirebaseGroupSessionService();

  static const int minParticipants = 2;
  static const int maxParticipants = 8;
  static final Random _random = Random.secure();

  static bool areAllExpectedMembersComplete({
    required int expectedPlayers,
    required Iterable<bool> completionStates,
  }) {
    if (expectedPlayers < minParticipants ||
        expectedPlayers > maxParticipants) {
      return false;
    }
    final states = completionStates.toList();
    return states.length == expectedPlayers &&
        states.every((isComplete) => isComplete);
  }

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseAuth get _authClient => FirebaseAuth.instance;
  CollectionReference<Map<String, dynamic>> get _rooms =>
      _db.collection('groupRooms');

  Future<String> _ensureSignedIn() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }

    final auth = _authClient;
    final user = auth.currentUser ?? (await auth.signInAnonymously()).user;
    if (user == null) {
      throw StateError('Firebase anonymous sign-in did not return a user.');
    }
    return user.uid;
  }

  Future<FirebaseGroupSession> createRoom({
    required String gate,
    required String budget,
    required int expectedPlayers,
  }) async {
    if (expectedPlayers < minParticipants ||
        expectedPlayers > maxParticipants) {
      throw RangeError.range(
        expectedPlayers,
        minParticipants,
        maxParticipants,
        'expectedPlayers',
      );
    }

    final memberId = await _ensureSignedIn();

    for (var attempt = 0; attempt < 30; attempt++) {
      final roomCode = '${1000 + _random.nextInt(9000)}';
      final roomRef = _rooms.doc(roomCode);
      final memberRef = roomRef.collection('members').doc(memberId);
      final created = await _db.runTransaction<bool>((transaction) async {
        final existingRoom = await transaction.get(roomRef);
        if (existingRoom.exists) return false;

        transaction.set(roomRef, {
          'roomCode': roomCode,
          'hostUid': memberId,
          'memberUids': [memberId],
          'gate': gate,
          'budget': budget,
          'expectedPlayers': expectedPlayers,
          'completedMemberUids': <String>[],
          'status': 'open',
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.set(memberRef, {
          'memberUid': memberId,
          'progress': 0,
          'completed': false,
          'joinedAt': FieldValue.serverTimestamp(),
        });
        return true;
      });

      if (created) {
        return FirebaseGroupSession(
          roomCode: roomCode,
          gate: gate,
          budget: budget,
          memberId: memberId,
        );
      }
    }

    throw StateError('Could not generate an available room code. Try again.');
  }

  Future<FirebaseGroupSession> joinRoom(String requestedCode) async {
    final roomCode = requestedCode.trim();
    if (!RegExp(r'^\d{4}$').hasMatch(roomCode)) {
      throw ArgumentError.value(
        requestedCode,
        'roomCode',
        'Room codes must contain four digits.',
      );
    }

    final memberId = await _ensureSignedIn();
    final roomRef = _rooms.doc(roomCode);
    final memberRef = roomRef.collection('members').doc(memberId);

    return _db.runTransaction<FirebaseGroupSession>((transaction) async {
      final roomSnapshot = await transaction.get(roomRef);
      if (!roomSnapshot.exists) {
        throw StateError('Room $roomCode was not found.');
      }

      final room = roomSnapshot.data()!;
      final currentMember = await transaction.get(memberRef);
      final memberUids = List<String>.from(room['memberUids'] as List);
      final expectedPlayers = room['expectedPlayers'] as int;
      if (room['status'] == 'completed') {
        throw StateError('This room has already completed its match.');
      }

      if (!memberUids.contains(memberId)) {
        if (room['status'] != 'open') {
          throw StateError('This room has already started.');
        }
        if (memberUids.length >= expectedPlayers) {
          throw StateError('Room $roomCode is full.');
        }
        memberUids.add(memberId);
        transaction.update(roomRef, {
          'memberUids': memberUids,
          'status': memberUids.length == expectedPlayers ? 'swiping' : 'open',
        });
      }

      if (!currentMember.exists) {
        transaction.set(memberRef, {
          'memberUid': memberId,
          'progress': 0,
          'completed': false,
          'joinedAt': FieldValue.serverTimestamp(),
        });
      }

      return FirebaseGroupSession(
        roomCode: roomCode,
        gate: room['gate'] as String,
        budget: room['budget'] as String,
        memberId: memberId,
      );
    });
  }

  Future<void> recordSwipe({
    required String roomCode,
    required String memberId,
    required String spotId,
    required SwipeDirection direction,
    required int progress,
    required bool isComplete,
  }) async {
    final currentUid = _authClient.currentUser?.uid;
    if (currentUid == null || currentUid != memberId) {
      throw StateError('The signed-in user does not match this room member.');
    }

    final roomRef = _rooms.doc(roomCode);
    final batch = _db.batch();
    batch.set(roomRef.collection('votes').doc('${memberId}_$spotId'), {
      'memberUid': memberId,
      'spotId': spotId,
      'direction': direction.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(roomRef.collection('members').doc(memberId), {
      'memberUid': memberId,
      'progress': progress,
      'completed': isComplete,
      if (isComplete) 'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (isComplete) {
      batch.update(roomRef, {
        'completedMemberUids': FieldValue.arrayUnion([memberId]),
      });
    }
    await batch.commit();
  }

  Stream<FirebaseGroupRoomState> watchRoomState(String roomCode) {
    return _rooms.doc(roomCode).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        throw StateError('Room $roomCode was not found.');
      }

      final room = snapshot.data()!;
      return FirebaseGroupRoomState(
        expectedPlayers: room['expectedPlayers'] as int,
        joinedPlayers: (room['memberUids'] as List).length,
        status: room['status'] as String,
      );
    });
  }

  Stream<FirebaseGroupResults?> watchResults({
    required String roomCode,
    required List<FoodSpot> sessionDeck,
  }) {
    final roomRef = _rooms.doc(roomCode);
    final membersRef = roomRef.collection('members');

    return membersRef.snapshots().asyncMap((memberSnapshot) async {
      final roomSnapshot = await roomRef.get();
      if (!roomSnapshot.exists) return null;
      final room = roomSnapshot.data()!;
      final expectedPlayers = room['expectedPlayers'];
      final roomMemberIds = List<String>.from(room['memberUids'] as List);
      final memberIds = memberSnapshot.docs.map((doc) => doc.id).toList()
        ..sort();
      if (expectedPlayers is! int ||
          room['status'] != 'swiping' ||
          memberIds.length != expectedPlayers ||
          roomMemberIds.length != expectedPlayers ||
          !Set<String>.from(memberIds).containsAll(roomMemberIds) ||
          !areAllExpectedMembersComplete(
            expectedPlayers: expectedPlayers,
            completionStates: memberSnapshot.docs.map(
              (member) => member.data()['completed'] == true,
            ),
          )) {
        return null;
      }

      final voteSnapshot = await roomRef.collection('votes').get();
      final votesBySpot = <String, Map<String, SwipeDirection>>{};
      for (final voteDoc in voteSnapshot.docs) {
        final vote = voteDoc.data();
        final memberId = vote['memberUid'];
        final spotId = vote['spotId'];
        final directionName = vote['direction'];
        if (memberId is! String ||
            spotId is! String ||
            !memberIds.contains(memberId)) {
          continue;
        }
        for (final direction in SwipeDirection.values) {
          if (direction.name == directionName) {
            votesBySpot.putIfAbsent(spotId, () => {})[memberId] = direction;
            break;
          }
        }
      }

      final ranked = QuickMatchState.rankVotes(
        spots: sessionDeck,
        memberIds: memberIds,
        votesBySpot: votesBySpot,
      );
      await _saveResults(roomRef, ranked);
      return FirebaseGroupResults(ranked);
    });
  }

  Future<void> _saveResults(
    DocumentReference<Map<String, dynamic>> roomRef,
    List<MatchResult> rankedMatches,
  ) async {
    if (rankedMatches.isEmpty) {
      throw StateError('Cannot save results for an empty food deck.');
    }

    await _db.runTransaction<void>((transaction) async {
      final roomSnapshot = await transaction.get(roomRef);
      if (!roomSnapshot.exists) {
        throw StateError('The group room no longer exists.');
      }
      if (roomSnapshot.data()?['status'] == 'completed') return;

      transaction.update(roomRef, {
        'status': 'completed',
        'resultSpotId': rankedMatches.first.spot.id,
        'results': rankedMatches
            .map(
              (match) => {
                'spotId': match.spot.id,
                'totalScore': match.totalScore,
                'likeCount': match.likeCount,
                'likedByMemberIds': match.likedByMemberIds,
                'isUnanimous': match.isUnanimous,
              },
            )
            .toList(),
        'completedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
