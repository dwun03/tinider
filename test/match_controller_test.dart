import 'package:flutter_test/flutter_test.dart';
import 'package:tinider/controllers/match_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late QuickMatchState state;

  setUp(() async {
    state = QuickMatchState();
    await state.loadDataset();
  });

  tearDown(() {
    state.dispose();
  });

  test('filters the JSON deck without changing its order', () {
    state.startGroupSession(
      groupMemberIds: const ['solo'],
      preferredGateKeyword: 'Dapitan',
      minBudgetPhp: 100,
      maxBudgetPhp: 180,
      shuffleDeck: false,
    );

    expect(state.sessionDeck, isNotEmpty);
    expect(state.sessionDeck.first.id, 'UST-FS-004');
    expect(
      state.sessionDeck.every(
        (spot) =>
            spot.nearestGate.toLowerCase().contains('dapitan') &&
            spot.priceRangePhp.averageMeal >= 100 &&
            spot.priceRangePhp.averageMeal <= 180,
      ),
      isTrue,
    );
  });

  test('ranks votes and identifies unanimous matches', () {
    state.startGroupSession(
      groupMemberIds: const ['alice', 'bob'],
      shuffleDeck: false,
    );
    final firstSpot = state.sessionDeck.first;

    state.swipe(memberId: 'alice', direction: SwipeDirection.right);
    state.swipe(memberId: 'alice', direction: SwipeDirection.left);
    state.swipe(memberId: 'bob', direction: SwipeDirection.superLike);
    state.swipe(memberId: 'bob', direction: SwipeDirection.right);

    for (final memberId in const ['alice', 'bob']) {
      while (state.currentCardFor(memberId) != null) {
        state.swipe(memberId: memberId, direction: SwipeDirection.left);
      }
    }

    final ranked = state.getRankedMatches();
    expect(state.isSessionComplete, isTrue);
    expect(ranked.first.spot.id, firstSpot.id);
    expect(ranked.first.totalScore, 3);
    expect(ranked.first.likeCount, 2);
    expect(ranked.first.likedByMemberIds, ['alice', 'bob']);
    expect(ranked.first.isUnanimous, isTrue);
    expect(state.getFinalMatch()?.spot.id, firstSpot.id);
  });

  test('returns no final match when every vote is a pass', () {
    state.startGroupSession(groupMemberIds: const ['solo'], shuffleDeck: false);

    while (state.currentCardFor('solo') != null) {
      state.swipe(memberId: 'solo', direction: SwipeDirection.left);
    }

    expect(state.getFinalMatch(), isNull);
  });
}
