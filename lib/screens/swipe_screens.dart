import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/food_swipe_controller.dart';
import '../controllers/match_controller.dart';
import '../models/foodspot.dart';
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
  final String? onlineMemberId;

  const FoodSwipeScreen({
    super.key,
    required this.gate,
    required this.budget,
    this.isGroup = false,
    this.roomCode,
    this.memberIds,
    this.onlineMemberId,
  });

  @override
  State<FoodSwipeScreen> createState() => _FoodSwipeScreenState();
}

class _FoodSwipeScreenState extends State<FoodSwipeScreen> {
  late final FoodSwipeController _controller;
  bool _resultNavigationStarted = false;
  double _dragOffset = 0;

  static const double _swipeDistanceThreshold = 100;
  static const double _swipeVelocityThreshold = 600;

  @override
  void initState() {
    super.initState();
    _controller = FoodSwipeController(
      gate: widget.gate,
      budget: widget.budget,
      isGroup: widget.isGroup,
      roomCode: widget.roomCode,
      memberIds: widget.memberIds,
      onlineMemberId: widget.onlineMemberId,
    )..addListener(_handleControllerChanged);
    unawaited(_controller.loadCards());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (!mounted) return;
    setState(() {});

    final errorMessage = _controller.takeErrorMessage();
    if (errorMessage != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessage)));
    }

    final match = _controller.matchedSpot;
    if (match == null || _resultNavigationStarted) return;

    _resultNavigationStarted = true;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MatchScreen(gate: widget.gate, group: widget.isGroup, spot: match),
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
    _controller.swipe(direction);
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: TiniderColors.yellow),
        ),
      );
    }
    if (_controller.cards.isEmpty) {
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
    if (_controller.waitingForResults) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: TiniderColors.yellow),
                  const SizedBox(height: 24),
                  const Text(
                    'Waiting for everyone to finish swiping',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: TiniderColors.brown,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Room ${widget.roomCode}',
                    style: const TextStyle(
                      fontSize: 18,
                      color: TiniderColors.muted,
                    ),
                  ),
                  if (_controller.firebaseError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _controller.firebaseError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: TiniderColors.red),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    final card = _controller.currentCard!;
    final progress = _controller.currentProgress;
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
                  _controller.isOnlineGroup
                      ? 'Your swipes · $progress/${_controller.cards.length}'
                      : '${_memberLabel(_controller.activeMemberIndex)} · $progress/${_controller.cards.length}',
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
                      '$progress/${_controller.cards.length}',
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
                      onTap: () => _controller.swipe(SwipeDirection.left),
                      yellow: false,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _SwipeAction(
                      label: 'Crave',
                      icon: Icons.favorite_border,
                      hint: 'Swipe right to like',
                      onTap: () => _controller.swipe(SwipeDirection.right),
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
    final memberIds = _controller.sessionMemberIds;
    if (memberIds[memberIndex] == 'you') return 'You';
    if (memberIds[memberIndex] == 'friend') return 'Friend';
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
                    const _DirectionRow(
                      number: '2',
                      text: 'Walk straight along P. Noval St · 150 m',
                    ),
                    const _DirectionRow(
                      number: '3',
                      text: 'Turn right at the jeepney stop',
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
                            title: 'Landmarks',
                            value: 'Jeepney stop\nCorner bakery',
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
