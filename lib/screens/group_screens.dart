import 'dart:async';

import 'package:flutter/material.dart';

import '../services/firebase_group_session_service.dart';
import '../theme/tinider_theme.dart';
import '../widgets/tinider_widgets.dart';
import 'swipe_screens.dart';

class GroupChoiceScreen extends StatelessWidget {
  final String gate;
  final String budget;

  const GroupChoiceScreen({
    super.key,
    required this.gate,
    required this.budget,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 20, 32, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const TiniderBackButton(),
                  const Spacer(),
                  TiniderContextPill('$gate · $budget'),
                ],
              ),
              const SizedBox(height: 28),
              const Text(
                'Group swipe',
                style: TextStyle(
                  fontSize: 40,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: TiniderColors.brown,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'How will you swipe?',
                style: TextStyle(fontSize: 20, color: TiniderColors.muted),
              ),
              const Spacer(),
              _GroupModeCard(
                title: 'Online',
                subtitle: 'Needs internet',
                description: 'Enter a 4-digit room code. Everyone swipes on their own phone.',
                buttonText: 'Enter room code',
                needsInternet: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RoomCodeScreen(gate: gate, budget: budget),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _GroupModeCard(
                title: 'Pass the\nphone',
                subtitle: 'Works offline',
                description: 'One phone only. Take turns swiping, then hand it to the next person.',
                buttonText: 'Start passing',
                needsInternet: false,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PassPhoneScreen(gate: gate, budget: budget),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final String buttonText;
  final bool needsInternet;
  final VoidCallback onTap;

  const _GroupModeCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.buttonText,
    required this.needsInternet,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: TiniderColors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: TiniderColors.brown, width: 2),
          boxShadow: const [
            BoxShadow(color: TiniderColors.brown, offset: Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 28,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      color: TiniderColors.brown,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: TiniderColors.muted,
                      width: needsInternet ? 0 : 2,
                      style: needsInternet
                          ? BorderStyle.solid
                          : BorderStyle.solid,
                    ),
                  ),
                  child: Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: TiniderColors.brown,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              description,
              style: const TextStyle(
                fontSize: 16,
                height: 1.35,
                color: TiniderColors.muted,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: TiniderColors.brown,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: TiniderColors.yellow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    size: 20,
                    color: TiniderColors.brown,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RoomCodeScreen extends StatefulWidget {
  final String gate;
  final String budget;

  const RoomCodeScreen({super.key, required this.gate, required this.budget});

  @override
  State<RoomCodeScreen> createState() => _RoomCodeScreenState();
}

class _RoomCodeScreenState extends State<RoomCodeScreen> {
  final List<int> code = [];
  final FirebaseGroupSessionService _roomService =
      FirebaseGroupSessionService();
  bool _isBusy = false;

  void addDigit(int digit) {
    if (code.length < 4) setState(() => code.add(digit));
  }

  Future<void> _joinRoom() async {
    if (_isBusy || code.length != 4) return;
    setState(() => _isBusy = true);
    final roomCode = code.map((digit) => digit.toString()).join();
    try {
      final session = await _roomService.joinRoom(roomCode);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OnlineGroupLobbyScreen(session: session),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _createRoom() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final expectedPlayers = await _chooseExpectedPlayers();
      if (expectedPlayers == null || !mounted) return;

      final session = await _roomService.createRoom(
        gate: widget.gate,
        budget: widget.budget,
        expectedPlayers: expectedPlayers,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OnlineGroupLobbyScreen(session: session),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<int?> _chooseExpectedPlayers() {
    var expectedPlayers = 2;
    return showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('How many players?'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PlayerCountButton(
                icon: Icons.remove,
                enabled:
                    expectedPlayers >
                    FirebaseGroupSessionService.minParticipants,
                onTap: () => setDialogState(() => expectedPlayers--),
              ),
              SizedBox(
                width: 64,
                child: Text(
                  '$expectedPlayers',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: TiniderColors.brown,
                  ),
                ),
              ),
              _PlayerCountButton(
                icon: Icons.add,
                enabled:
                    expectedPlayers <
                    FirebaseGroupSessionService.maxParticipants,
                onTap: () => setDialogState(() => expectedPlayers++),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, expectedPlayers),
              child: const Text('Create room'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const TiniderBackButton(),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: TiniderColors.brown, width: 2),
                    ),
                    child: const Text(
                      'Online',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: TiniderColors.brown,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Room code',
                style: TextStyle(
                  fontSize: 36,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: TiniderColors.brown,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Ask your friend for the 4-digit code.',
                style: TextStyle(fontSize: 20, color: TiniderColors.muted),
              ),
              const SizedBox(height: 14),
              Row(
                children: List.generate(4, (index) {
                  final filled = index < code.length;
                  return Expanded(
                    child: Container(
                      height: 56,
                      margin: const EdgeInsets.only(right: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: filled
                            ? (index == code.length - 1
                                  ? TiniderColors.yellow
                                  : TiniderColors.white)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: TiniderColors.brown,
                          width: 3,
                          style: filled ? BorderStyle.solid : BorderStyle.solid,
                        ),
                      ),
                      child: Text(
                        filled ? '${code[index]}' : '',
                        style: const TextStyle(
                          fontSize: 46,
                          fontWeight: FontWeight.w900,
                          color: TiniderColors.brown,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 2.5,
                  children: [
                    for (var i = 1; i <= 9; i++)
                      _KeypadButton(label: '$i', onTap: () => addDigit(i)),
                    _KeypadButton(
                      label: 'clear',
                      muted: true,
                      onTap: () => setState(code.clear),
                    ),
                    _KeypadButton(label: '0', onTap: () => addDigit(0)),
                    _KeypadButton(
                      label: 'erase',
                      muted: true,
                      onTap: () {
                        if (code.isNotEmpty) {
                          setState(code.removeLast);
                        }
                      },
                    ),
                  ],
                ),
              ),
              TiniderPrimaryButton(
                label: _isBusy ? 'Please wait...' : 'Join room',
                onPressed: code.length == 4 && !_isBusy ? _joinRoom : null,
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _isBusy ? null : _createRoom,
                  child: const Text(
                    'Create a new room instead',
                    style: TextStyle(
                      fontSize: 16,
                      decoration: TextDecoration.underline,
                      color: TiniderColors.brown,
                    ),
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

class OnlineGroupLobbyScreen extends StatefulWidget {
  final FirebaseGroupSession session;

  const OnlineGroupLobbyScreen({super.key, required this.session});

  @override
  State<OnlineGroupLobbyScreen> createState() => _OnlineGroupLobbyScreenState();
}

class _OnlineGroupLobbyScreenState extends State<OnlineGroupLobbyScreen> {
  final FirebaseGroupSessionService _roomService =
      FirebaseGroupSessionService();
  StreamSubscription<FirebaseGroupRoomState>? _roomSubscription;
  FirebaseGroupRoomState? _roomState;
  String? _error;
  bool _isOpeningSwipeScreen = false;

  @override
  void initState() {
    super.initState();
    _roomSubscription = _roomService
        .watchRoomState(widget.session.roomCode)
        .listen(
          _handleRoomState,
          onError: (Object error, StackTrace stackTrace) {
            if (!mounted) return;
            setState(() => _error = error.toString());
          },
        );
  }

  void _handleRoomState(FirebaseGroupRoomState roomState) {
    if (!mounted) return;
    setState(() {
      _roomState = roomState;
      _error = null;
    });

    if (roomState.status == 'swiping') {
      _openSwipeScreen();
    }
  }

  void _openSwipeScreen() {
    if (_isOpeningSwipeScreen) return;
    _isOpeningSwipeScreen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => FoodSwipeScreen(
            gate: widget.session.gate,
            budget: widget.session.budget,
            isGroup: true,
            roomCode: widget.session.roomCode,
            onlineMemberId: widget.session.memberId,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    unawaited(_roomSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomState = _roomState;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 20, 32, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TiniderBackButton(),
              const SizedBox(height: 32),
              const Text(
                'Waiting for players',
                style: TextStyle(
                  fontSize: 36,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: TiniderColors.brown,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Share this room code with everyone joining.',
                style: TextStyle(fontSize: 18, color: TiniderColors.muted),
              ),
              const SizedBox(height: 24),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: TiniderColors.yellow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: TiniderColors.brown, width: 3),
                  ),
                  child: Text(
                    widget.session.roomCode,
                    style: const TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8,
                      color: TiniderColors.brown,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  roomState == null
                      ? 'Connecting to room...'
                      : '${roomState.joinedPlayers} of ${roomState.expectedPlayers} players joined',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: TiniderColors.brown,
                  ),
                ),
              ),
              if (roomState != null &&
                  roomState.joinedPlayers < roomState.expectedPlayers) ...[
                const SizedBox(height: 16),
                const Center(
                  child: CircularProgressIndicator(color: TiniderColors.yellow),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: TiniderColors.red),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool muted;

  const _KeypadButton({
    required this.label,
    required this.onTap,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: TiniderColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: TiniderColors.brown, width: 3),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: muted ? 18 : 32,
            fontWeight: FontWeight.w800,
            color: muted ? TiniderColors.muted : TiniderColors.brown,
          ),
        ),
      ),
    );
  }
}

class _PlayerCountButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PlayerCountButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: enabled ? TiniderColors.cream : const Color(0xFFE8E0D2),
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? TiniderColors.brown : TiniderColors.muted,
            width: 3,
          ),
        ),
        child: Icon(
          icon,
          size: 28,
          color: enabled ? TiniderColors.brown : TiniderColors.muted,
        ),
      ),
    );
  }
}

class PassPhoneScreen extends StatefulWidget {
  final String gate;
  final String budget;

  const PassPhoneScreen({super.key, required this.gate, required this.budget});

  @override
  State<PassPhoneScreen> createState() => _PassPhoneScreenState();
}

class _PassPhoneScreenState extends State<PassPhoneScreen> {
  int players = 2;
  int player = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 20, 32, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const TiniderBackButton(),
                  const Spacer(),
                  const TiniderContextPill('Offline'),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                'Pass the phone',
                style: TextStyle(
                  fontSize: 40,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: TiniderColors.brown,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'One phone, take turns swiping.',
                style: TextStyle(fontSize: 20, color: TiniderColors.muted),
              ),
              const SizedBox(height: 32),
              const Text(
                'How many players?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: TiniderColors.brown,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _PlayerCountButton(
                              icon: Icons.remove,
                              enabled: players > 2,
                              onTap: () => setState(() => players--),
                            ),
                            Container(
                              width: 72,
                              alignment: Alignment.center,
                              child: Text(
                                '$players',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: TiniderColors.brown,
                                ),
                              ),
                            ),
                            _PlayerCountButton(
                              icon: Icons.add,
                              enabled: players < 8,
                              onTap: () => setState(() => players++),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
                decoration: BoxDecoration(
                  color: TiniderColors.yellow,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: TiniderColors.brown, width: 3),
                ),
                child: Column(
                  children: [
                    Text(
                      'Player $player',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: TiniderColors.brown,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You go first. Swipe what you like,\nthen pass it to the next person.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.35,
                        color: TiniderColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TiniderPrimaryButton(
                label: 'Ready, Player $player',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FoodSwipeScreen(
                      gate: widget.gate,
                      budget: widget.budget,
                      isGroup: true,
                      roomCode: 'OFFLINE',
                      memberIds: List.generate(
                        players,
                        (index) => index == 0 ? 'you' : 'player_${index + 1}',
                      ),
                    ),
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
