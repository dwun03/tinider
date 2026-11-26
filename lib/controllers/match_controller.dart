import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/foodspot.dart';

enum SwipeDirection { left, right, superLike }

class MatchResult {
  final FoodSpot spot;
  final int totalScore;
  final int likeCount;
  final List<String> likedByMemberIds;
  final bool isUnanimous;

  const MatchResult({
    required this.spot,
    required this.totalScore,
    required this.likeCount,
    required this.likedByMemberIds,
    required this.isUnanimous,
  });
}

class QuickMatchState extends ChangeNotifier {
  List<FoodSpot> _allSpots = [];
  List<FoodSpot> _sessionDeck = [];
  List<String> _memberIds = [];

  // Tracks current card index per group member: { memberId: cardIndex }
  final Map<String, int> _memberProgress = {};

  // Tracks votes per spot: { spotId: { memberId: SwipeDirection } }
  final Map<String, Map<String, SwipeDirection>> _swipes = {};

  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<FoodSpot> get allSpots => List.unmodifiable(_allSpots);
  List<FoodSpot> get sessionDeck => List.unmodifiable(_sessionDeck);
  List<String> get memberIds => List.unmodifiable(_memberIds);

  /// 1. Loads and parses the offline JSON asset into app state.
  Future<void> loadDataset({
    String assetPath = 'assets/data/food_dataset.json',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final rawJson = await rootBundle.loadString(assetPath);
      final Map<String, dynamic> decoded = json.decode(rawJson);
      final List<dynamic> spotsJson = decoded['food_spots'] as List<dynamic>;

      final uniqueSpots = <String, FoodSpot>{};
      for (final item in spotsJson) {
        final spot = FoodSpot.fromJson(item as Map<String, dynamic>);
        uniqueSpots.putIfAbsent(spot.id, () => spot);
      }
      _allSpots = uniqueSpots.values.toList();
    } catch (e) {
      _error = 'Failed to parse UST food spots dataset: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 2. Starts a paired/group swipe session with optional pre-filters.
  void startGroupSession({
    required List<String> groupMemberIds,
    int? maxBudgetPhp,
    int? minBudgetPhp,
    int? maxWalkMinutes,
    String? preferredGateKeyword,
    bool shuffleDeck = true,
  }) {
    if (groupMemberIds.isEmpty) {
      throw ArgumentError.value(
        groupMemberIds,
        'groupMemberIds',
        'At least one member is required.',
      );
    }
    if (groupMemberIds.toSet().length != groupMemberIds.length) {
      throw ArgumentError.value(
        groupMemberIds,
        'groupMemberIds',
        'Member IDs must be unique.',
      );
    }

    _memberIds = List.from(groupMemberIds);
    _memberProgress.clear();
    _swipes.clear();

    for (final memberId in _memberIds) {
      _memberProgress[memberId] = 0;
    }

    // Filter dataset based on group constraints
    _sessionDeck = _allSpots.where((spot) {
      if (maxBudgetPhp != null &&
          spot.priceRangePhp.averageMeal > maxBudgetPhp) {
        return false;
      }
      if (minBudgetPhp != null &&
          spot.priceRangePhp.averageMeal < minBudgetPhp) {
        return false;
      }
      if (maxWalkMinutes != null && spot.walkingTimeMinutes > maxWalkMinutes) {
        return false;
      }
      if (preferredGateKeyword != null &&
          preferredGateKeyword.isNotEmpty &&
          !spot.nearestGate.toLowerCase().contains(
            preferredGateKeyword.toLowerCase(),
          )) {
        return false;
      }
      return true;
    }).toList();

    if (shuffleDeck) {
      _sessionDeck.shuffle();
    }

    notifyListeners();
  }

  /// Returns the current FoodSpot card for a specific member, or null if done.
  FoodSpot? currentCardFor(String memberId) {
    final index = _memberProgress[memberId] ?? 0;
    if (index >= _sessionDeck.length) return null;
    return _sessionDeck[index];
  }

  /// Checks if a specific member has finished swiping the entire deck.
  bool isMemberDone(String memberId) {
    return (_memberProgress[memberId] ?? 0) >= _sessionDeck.length;
  }

  /// Checks if every member in the paired group has finished swiping.
  bool get isSessionComplete {
    return _memberIds.isNotEmpty && _memberIds.every(isMemberDone);
  }

  /// Returns how many spots a member has swiped in the current session.
  int progressFor(String memberId) => _memberProgress[memberId] ?? 0;

  /// 3. Records a member's swipe on their current card and advances their deck.
  void swipe({required String memberId, required SwipeDirection direction}) {
    if (!_memberIds.contains(memberId)) {
      throw ArgumentError.value(
        memberId,
        'memberId',
        'Unknown session member.',
      );
    }

    final currentSpot = currentCardFor(memberId);
    if (currentSpot == null) return;

    _swipes.putIfAbsent(currentSpot.id, () => {});
    _swipes[currentSpot.id]![memberId] = direction;

    _memberProgress[memberId] = (_memberProgress[memberId] ?? 0) + 1;
    notifyListeners();
  }

  /// 4. Ranks all swiped spots and returns the leaderboard.
  /// Scoring: right = +1, superLike = +2, left = 0.
  List<MatchResult> getRankedMatches() => rankVotes(
    spots: _sessionDeck,
    memberIds: _memberIds,
    votesBySpot: _swipes,
  );

  static List<MatchResult> rankVotes({
    required List<FoodSpot> spots,
    required List<String> memberIds,
    required Map<String, Map<String, SwipeDirection>> votesBySpot,
  }) {
    final results = <MatchResult>[];

    for (final spot in spots) {
      final votes = votesBySpot[spot.id] ?? {};
      int score = 0;
      final likedBy = <String>[];

      for (final memberId in memberIds) {
        final direction = votes[memberId];
        if (direction == SwipeDirection.right) {
          score += 1;
          likedBy.add(memberId);
        } else if (direction == SwipeDirection.superLike) {
          score += 2;
          likedBy.add(memberId);
        }
      }

      results.add(
        MatchResult(
          spot: spot,
          totalScore: score,
          likeCount: likedBy.length,
          likedByMemberIds: likedBy,
          isUnanimous: likedBy.length == memberIds.length,
        ),
      );
    }

    // Sort by highest score -> most unique likes -> shortest walk -> cheapest meal
    results.sort((a, b) {
      final scoreCompare = b.totalScore.compareTo(a.totalScore);
      if (scoreCompare != 0) return scoreCompare;

      final countCompare = b.likeCount.compareTo(a.likeCount);
      if (countCompare != 0) return countCompare;

      final walkCompare = a.spot.walkingTimeMinutes.compareTo(
        b.spot.walkingTimeMinutes,
      );
      if (walkCompare != 0) return walkCompare;

      return a.spot.priceRangePhp.averageMeal.compareTo(
        b.spot.priceRangePhp.averageMeal,
      );
    });

    return results;
  }

  /// Returns the single top matched spot (null if nobody swiped right on anything).
  MatchResult? getFinalMatch() {
    final ranked = getRankedMatches();
    if (ranked.isEmpty || ranked.first.totalScore == 0) return null;
    return ranked.first;
  }
}
