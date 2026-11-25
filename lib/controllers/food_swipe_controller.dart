import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/foodspot.dart';
import '../services/firebase_group_session_service.dart';
import 'match_controller.dart';

class FoodSwipeController extends ChangeNotifier {
  FoodSwipeController({
    required this.gate,
    required this.budget,
    this.isGroup = false,
    this.roomCode,
    this.memberIds,
    this.onlineMemberId,
    FirebaseGroupSessionService? groupSessionService,
  }) : _groupSessionService =
           groupSessionService ?? FirebaseGroupSessionService();

  final String gate;
  final String budget;
  final bool isGroup;
  final String? roomCode;
  final List<String>? memberIds;
  final String? onlineMemberId;
  final FirebaseGroupSessionService _groupSessionService;
  final QuickMatchState _matchState = QuickMatchState();

  int activeMemberIndex = 0;
  List<FoodSpot> cards = [];
  List<String> _memberIds = [];
  bool isLoading = true;
  bool isSubmitting = false;
  bool waitingForResults = false;
  String? firebaseError;
  String? _errorMessage;
  FoodSpot? matchedSpot;
  StreamSubscription<FirebaseGroupResults?>? _resultsSubscription;
  bool _isDisposed = false;

  bool get isOnlineGroup =>
      isGroup && roomCode != null && roomCode != 'OFFLINE';
  List<String> get sessionMemberIds => List.unmodifiable(_memberIds);

  FoodSpot? get currentCard {
    if (_memberIds.isEmpty || activeMemberIndex >= _memberIds.length) {
      return null;
    }
    return _matchState.currentCardFor(_memberIds[activeMemberIndex]);
  }

  int get currentProgress {
    if (_memberIds.isEmpty || activeMemberIndex >= _memberIds.length) return 0;
    return _matchState.progressFor(_memberIds[activeMemberIndex]) + 1;
  }

  String? takeErrorMessage() {
    final message = _errorMessage;
    _errorMessage = null;
    return message;
  }

  Future<void> loadCards() async {
    try {
      await _matchState.loadDataset();
      if (_isDisposed) {
        _matchState.dispose();
        return;
      }
      final loadError = _matchState.error;
      if (loadError != null) throw StateError(loadError);

      final budgetRange = switch (budget) {
        'Thrifty' => (min: null, max: 99),
        'Regular' => (min: 100, max: 180),
        'Special Treat' => (min: 181, max: null),
        _ => (min: null, max: null),
      };
      if (isOnlineGroup) {
        final memberId = onlineMemberId;
        if (memberId == null) {
          throw StateError('The Firebase room member ID is missing.');
        }
        _memberIds = [memberId];
      } else {
        _memberIds =
            memberIds ?? (isGroup ? const ['you', 'friend'] : const ['you']);
      }

      _matchState.startGroupSession(
        groupMemberIds: _memberIds,
        minBudgetPhp: budgetRange.min,
        maxBudgetPhp: budgetRange.max,
        preferredGateKeyword: gate,
        shuffleDeck: false,
      );
      cards = _matchState.sessionDeck;
      isLoading = false;
      notifyListeners();

      if (isOnlineGroup) {
        _resultsSubscription = _groupSessionService
            .watchResults(roomCode: roomCode!, sessionDeck: cards)
            .listen(
              _handleFirebaseResults,
              onError: (Object error, StackTrace stackTrace) {
                if (_isDisposed) return;
                firebaseError = error.toString();
                _errorMessage = 'Could not load group results: $error';
                notifyListeners();
              },
            );
      }
    } catch (error) {
      if (_isDisposed) return;
      isLoading = false;
      _errorMessage = 'Could not load food options: $error';
      notifyListeners();
    }
  }

  void swipe(SwipeDirection direction) {
    if (isSubmitting || waitingForResults || currentCard == null) return;
    if (isOnlineGroup) {
      unawaited(_recordOnlineSwipe(direction));
      return;
    }

    _recordLocalSwipe(direction);
  }

  void _recordLocalSwipe(SwipeDirection direction) {
    final memberId = _memberIds[activeMemberIndex];
    _matchState.swipe(memberId: memberId, direction: direction);

    if (!_matchState.isMemberDone(memberId)) {
      notifyListeners();
      return;
    }

    if (activeMemberIndex < _memberIds.length - 1) {
      activeMemberIndex++;
      notifyListeners();
      return;
    }

    final rankedMatches = _matchState.getRankedMatches();
    if (rankedMatches.isNotEmpty) {
      matchedSpot = (_matchState.getFinalMatch() ?? rankedMatches.first).spot;
      notifyListeners();
    }
  }

  Future<void> _recordOnlineSwipe(SwipeDirection direction) async {
    final memberId = _memberIds[activeMemberIndex];
    final spot = _matchState.currentCardFor(memberId);
    if (spot == null) return;

    final nextProgress = _matchState.progressFor(memberId) + 1;
    final isComplete = nextProgress >= cards.length;
    isSubmitting = true;
    notifyListeners();
    try {
      await _groupSessionService.recordSwipe(
        roomCode: roomCode!,
        memberId: memberId,
        spotId: spot.id,
        direction: direction,
        progress: nextProgress,
        isComplete: isComplete,
      );
      if (_isDisposed) return;

      _matchState.swipe(memberId: memberId, direction: direction);
      isSubmitting = false;
      waitingForResults = isComplete;
      notifyListeners();
    } catch (error) {
      if (_isDisposed) return;
      isSubmitting = false;
      _errorMessage = 'Could not save your swipe: $error';
      notifyListeners();
    }
  }

  void _handleFirebaseResults(FirebaseGroupResults? results) {
    if (_isDisposed || results == null || matchedSpot != null) return;
    if (results.rankedMatches.isEmpty) return;

    matchedSpot = results.rankedMatches.first.spot;
    unawaited(_resultsSubscription?.cancel());
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_resultsSubscription?.cancel());
    if (!isLoading) _matchState.dispose();
    super.dispose();
  }
}
