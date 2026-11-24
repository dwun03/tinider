import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../controllers/match_controller.dart';
import '../models/foodspot.dart';
import '../services/room_service.dart';
import '../theme/tinider_theme.dart';
import '../widgets/food_image_placeholder.dart';
import '../widgets/tinider_widgets.dart';
import 'setup_screens.dart';

class FoodSwipeScreen extends StatefulWidget {
  final String gate;
  final String budget;
  final bool isGroup;
  final String? roomCode;
  final List<String>? memberIds;

  const FoodSwipeScreen({
    super.key,
    required this.gate,
    required this.budget,
    this.isGroup = false,
    this.roomCode,
    this.memberIds,
  });

  @override
  State<FoodSwipeScreen> createState() => _FoodSwipeScreenState();
}

class _FoodSwipeScreenState extends State<FoodSwipeScreen> {
  final QuickMatchState _matchState = QuickMatchState();
  final RoomService _roomService = RoomService();
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _roomSubscription;
  int activeMemberIndex = 0;
  List<FoodSpot> cards = [];
  List<String> _memberIds = [];
  bool isLoading = true;
  double _dragOffset = 0;
  bool _winnerHandled = false;

  static const double _swipeDistanceThreshold = 100;
  static const double _swipeVelocityThreshold = 600;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    _matchState.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    try {
      await _matchState.loadDataset();
      final loadError = _matchState.error;
      if (loadError != null) {
        throw StateError(loadError);
      }

      final budgetRange = switch (widget.budget) {
        'Tipid' => (min: null, max: 99),
        'Regular' => (min: 100, max: 180),
        "Deserve 'Ko To" => (min: 181, max: null),
        'Thrifty' => (min: null, max: 99),
        'Special Treat' => (min: 181, max: null),
        _ => (min: null, max: null),
      };
      _memberIds =
          widget.memberIds ??
          (widget.isGroup ? const ['you', 'friend'] : const ['you']);
      if (widget.isGroup &&
          widget.roomCode != null &&
          widget.roomCode != 'OFFLINE') {
        final memberId = await _roomService.ensureIdentity();
        _memberIds = [memberId];
      }
      _matchState.startGroupSession(
        groupMemberIds: _memberIds,
        minBudgetPhp: budgetRange.min,
        maxBudgetPhp: budgetRange.max,
        preferredGateKeyword: widget.gate,
        shuffleDeck: false,
      );

      if (!mounted) return;
      setState(() {
        cards = _matchState.sessionDeck;
        isLoading = false;
      });
      if (widget.isGroup &&
          widget.roomCode != null &&
          widget.roomCode != 'OFFLINE') {
        _watchOnlineRoom();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load food options: $error')),
      );
    }
  }

  void nextCard(SwipeDirection direction) {
    _matchState.swipe(
      memberId: _memberIds[activeMemberIndex],
      direction: direction,
    );

    if (widget.isGroup &&
        widget.roomCode != null &&
        widget.roomCode != 'OFFLINE') {
      final memberId = _memberIds[activeMemberIndex];
      final cardIndex = _matchState.progressFor(memberId);
      final currentCard = cards[cardIndex - 1];
      _roomService.recordSwipe(
        code: widget.roomCode!,
        memberId: memberId,
        spotId: currentCard.id,
        direction: direction.name,
        progress: cardIndex,
        deckLength: cards.length,
      );
      setState(() {});
      return;
    }

    if (!_matchState.isMemberDone(_memberIds[activeMemberIndex])) {
      setState(() {});
      return;
    }

    if (activeMemberIndex < _memberIds.length - 1) {
      setState(() {
        activeMemberIndex++;
      });
      return;
    }

    final rankedMatches = _matchState.getRankedMatches();
    if (rankedMatches.isNotEmpty) {
      final match = _matchState.getFinalMatch() ?? rankedMatches.first;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MatchScreen(
            gate: widget.gate,
            group: widget.isGroup,
            spot: match.spot,
          ),
        ),
      );
    }
  }

  void _watchOnlineRoom() {
    _roomSubscription = _roomService
        .watchRoom(widget.roomCode!)
        .listen(
          (snapshot) async {
            if (!snapshot.exists || _winnerHandled) return;
            final data = snapshot.data()!;
            final winnerId = data['winnerId'] as String?;
            if (winnerId != null) {
              _showOnlineWinner(winnerId);
              return;
            }

            final participants = Map<String, dynamic>.from(
              data['participants'] as Map? ?? {},
            );
            if (participants.isEmpty) return;
            final allFinished = participants.values.every(
              (participant) =>
                  participant is Map && participant['finished'] == true,
            );
            if (!allFinished) return;

            final winner = await _roomService.finalizeWinner(
              widget.roomCode!,
              cards.map((spot) => spot.id).toList(),
            );
            if (winner != null) _showOnlineWinner(winner);
          },
          onError: (error) {
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Room sync error: $error')));
          },
        );
  }

  void _showOnlineWinner(String spotId) {
    if (!mounted || _winnerHandled) return;
    FoodSpot? spot;
    for (final item in cards) {
      if (item.id == spotId) {
        spot = item;
        break;
      }
    }
    if (spot == null) {
      for (final item in _matchState.allSpots) {
        if (item.id == spotId) {
          spot = item;
          break;
        }
      }
    }
    if (spot == null) return;
    final matchedSpot = spot;
    _winnerHandled = true;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MatchScreen(gate: widget.gate, group: true, spot: matchedSpot),
      ),
    );
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final direction = _dragOffset.abs() >= _swipeDistanceThreshold
        ? (_dragOffset > 0 ? SwipeDirection.right : SwipeDirection.left)
        : velocity.abs() >= _swipeVelocityThreshold
        ? (velocity > 0 ? SwipeDirection.right : SwipeDirection.left)
        : null;

    if (direction == null) {
      setState(() => _dragOffset = 0);
      return;
    }

    _dragOffset = 0;
    nextCard(direction);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: TiniderColors.yellow),
        ),
      );
    }
    if (cards.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No matches nearby',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: TiniderColors.brown,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Try another gate or budget.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: TiniderColors.muted),
                  ),
                  const SizedBox(height: 24),
                  TiniderPrimaryButton(
                    label: 'Go back',
                    onPressed: () => Navigator.maybePop(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final memberId = _memberIds[activeMemberIndex];
    final card = _matchState.currentCardFor(memberId)!;
    final progress = _matchState.progressFor(memberId) + 1;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 20, 32, 18),
          child: Column(
            children: [
              Row(
                children: [
                  const TiniderBackButton(),
                  const Spacer(),
                  TiniderContextPill(
                    widget.isGroup
                        ? 'Group · Room ${widget.roomCode ?? '4271'}'
                        : 'Solo · ${widget.gate} · ${widget.budget}',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (widget.isGroup) ...[
                Text(
                  '${_memberLabel(activeMemberIndex)} · $progress/${cards.length}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: TiniderColors.brown,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Take turns swiping the same food spots.',
                  style: TextStyle(fontSize: 15, color: TiniderColors.muted),
                ),
                const SizedBox(height: 16),
              ] else ...[
                Row(
                  children: [
                    const Text(
                      'Cravings',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: TiniderColors.brown,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$progress/${cards.length}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: TiniderColors.brown,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Expanded(
                child: GestureDetector(
                  onHorizontalDragStart: (_) => _dragOffset = 0,
                  onHorizontalDragUpdate: (details) {
                    setState(() => _dragOffset += details.delta.dx);
                  },
                  onHorizontalDragEnd: _handleHorizontalDragEnd,
                  onHorizontalDragCancel: () {
                    setState(() => _dragOffset = 0);
                  },
                  child: Transform.translate(
                    offset: Offset(_dragOffset, 0),
                    child: Transform.rotate(
                      angle:
                          _dragOffset / MediaQuery.sizeOf(context).width * 0.25,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color:
                              card.cuisineType.any(
                                (cuisine) =>
                                    cuisine.toLowerCase().contains('dimsum'),
                              )
                              ? TiniderColors.mint
                              : TiniderColors.yellow,
                          borderRadius: BorderRadius.circular(34),
                          border: Border.all(
                            color: TiniderColors.brown,
                            width: 4,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: TiniderColors.brown,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(30),
                                ),
                                child: FoodImagePlaceholder(spot: card),
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(
                                22,
                                18,
                                22,
                                16,
                              ),
                              decoration: const BoxDecoration(
                                color: TiniderColors.cream,
                                borderRadius: BorderRadius.vertical(
                                  bottom: Radius.circular(30),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          card.name.replaceAll(
                                            ' (Juaning)',
                                            '',
                                          ),
                                          style: const TextStyle(
                                            fontSize: 29,
                                            fontWeight: FontWeight.w900,
                                            color: TiniderColors.brown,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '₱${card.priceRangePhp.averageMeal}',
                                        style: const TextStyle(
                                          fontSize: 25,
                                          fontWeight: FontWeight.w900,
                                          color: TiniderColors.brown,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    card.popularItems.isNotEmpty
                                        ? card.popularItems.first
                                        : card.cuisineType.join(', '),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: TiniderColors.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      _Chip(
                                        '${card.walkingTimeMinutes} min walk',
                                      ),
                                      const SizedBox(width: 8),
                                      _Chip('Near ${widget.gate}'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SwipeAction(
                      label: 'Pass',
                      icon: Icons.close,
                      hint: 'Swipe left to pass',
                      onTap: () => nextCard(SwipeDirection.left),
                      yellow: false,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _SwipeAction(
                      label: 'Crave',
                      icon: Icons.favorite_border,
                      hint: 'Swipe right to like',
                      onTap: () => nextCard(SwipeDirection.right),
                      yellow: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _memberLabel(int memberIndex) {
    if (_memberIds[memberIndex] == 'you') return 'You';
    if (_memberIds[memberIndex] == 'friend') return 'Friend';
    return 'Player ${memberIndex + 1}';
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: TiniderColors.cream,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: TiniderColors.brown, width: 2),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: TiniderColors.brown,
        ),
      ),
    );
  }
}

class _SwipeAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final String hint;
  final VoidCallback onTap;
  final bool yellow;

  const _SwipeAction({
    required this.label,
    required this.icon,
    required this.hint,
    required this.onTap,
    required this.yellow,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: yellow ? TiniderColors.yellow : TiniderColors.cream,
              shape: BoxShape.circle,
              border: Border.all(color: TiniderColors.brown, width: 3),
              boxShadow: const [
                BoxShadow(color: TiniderColors.brown, offset: Offset(0, 5)),
              ],
            ),
            child: Icon(icon, size: 42, color: TiniderColors.brown),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: TiniderColors.brown,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            hint,
            style: const TextStyle(fontSize: 14, color: TiniderColors.muted),
          ),
        ],
      ),
    );
  }
}

class MatchScreen extends StatelessWidget {
  final String gate;
  final bool group;
  final FoodSpot spot;

  const MatchScreen({
    super.key,
    required this.gate,
    required this.group,
    required this.spot,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 30, 32, 24),
          child: Column(
            children: [
              const Text(
                'Match!',
                style: TextStyle(
                  fontSize: 58,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: TiniderColors.brown,
                ),
              ),
              const SizedBox(height: 18),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 24,
                    height: 1.2,
                    color: TiniderColors.brown,
                    fontFamily: 'Arial',
                    fontWeight: FontWeight.w700,
                  ),
                  children: [
                    const TextSpan(text: "Let's eat at "),
                    TextSpan(
                      text: spot.name.replaceAll(RegExp(r' \(.+\)$'), ''),
                      style: const TextStyle(
                        backgroundColor: TiniderColors.yellow,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: TiniderColors.yellow,
                    borderRadius: BorderRadius.circular(34),
                    border: Border.all(color: TiniderColors.brown, width: 4),
                    boxShadow: const [
                      BoxShadow(
                        color: TiniderColors.brown,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(30),
                          ),
                          child: FoodImagePlaceholder(spot: spot),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
                        decoration: const BoxDecoration(
                          color: TiniderColors.cream,
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(30),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    spot.name.replaceAll(
                                      RegExp(r' \(.+\)$'),
                                      '',
                                    ),
                                    style: const TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900,
                                      color: TiniderColors.brown,
                                    ),
                                  ),
                                ),
                                Text(
                                  '₱${spot.priceRangePhp.averageMeal}',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: TiniderColors.brown,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              spot.popularItems.isNotEmpty
                                  ? spot.popularItems.first
                                  : spot.cuisineType.join(', '),
                              style: const TextStyle(
                                fontSize: 16,
                                color: TiniderColors.muted,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _Chip('${spot.walkingTimeMinutes} min walk'),
                                const SizedBox(width: 8),
                                _Chip('Near $gate'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TiniderPrimaryButton(
                label: 'Show the way',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WalkCardScreen(gate: gate, spot: spot),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WalkCardScreen extends StatelessWidget {
  final String gate;
  final FoodSpot spot;

  const WalkCardScreen({super.key, required this.gate, required this.spot});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 20, 32, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const TiniderBackButton(),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: TiniderColors.cream,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: TiniderColors.brown, width: 2),
                    ),
                    child: const Text(
                      'WalkCard · saved offline',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: TiniderColors.brown,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                spot.name.replaceAll(RegExp(r' \(.+\)$'), ''),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: TiniderColors.brown,
                ),
              ),
              Text(
                'From $gate gate',
                style: const TextStyle(
                  fontSize: 18,
                  color: TiniderColors.muted,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: TiniderColors.white,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: TiniderColors.brown, width: 3),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 170,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: TiniderColors.green,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: TiniderColors.brown,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        size: 64,
                        color: TiniderColors.brown,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '$gate gate',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: TiniderColors.brown,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Directions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: TiniderColors.brown,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const _DirectionRow(
                      number: '1',
                      text: 'Exit through the gate',
                    ),
                    _DirectionRow(
                      number: '2',
                      text:
                          '${spot.streetAddress} · ${spot.walkingTimeMinutes} min walk',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _WalkInfo(
                            title: 'Hours',
                            value: spot.operatingHours,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _WalkInfo(
                            title: 'Address',
                            value: spot.streetAddress,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TiniderPrimaryButton(
                label: 'Done',
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const WhereAtScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DirectionRow extends StatelessWidget {
  final String number;
  final String text;

  const _DirectionRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: TiniderColors.yellow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: TiniderColors.brown, width: 2),
            ),
            child: Text(
              number,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: TiniderColors.brown,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                height: 1.35,
                color: TiniderColors.brown,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalkInfo extends StatelessWidget {
  final String title;
  final String value;

  const _WalkInfo({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TiniderColors.cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TiniderColors.brown, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: TiniderColors.muted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: TiniderColors.brown,
            ),
          ),
        ],
      ),
    );
  }
}
