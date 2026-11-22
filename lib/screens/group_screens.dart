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
  final FirebaseGroupSessionService _groupSessionService =
      FirebaseGroupSessionService();
  bool isWorking = false;

  void addDigit(int digit) {
    if (code.length < 4) setState(() => code.add(digit));
  }

  Future<void> _joinRoom() async {
    setState(() => isWorking = true);
    try {
      final session = await _groupSessionService.joinRoom(
        code.map((digit) => digit.toString()).join(),
      );
      if (!mounted) return;
      await _openRoom(session);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not join room: $error')));
    } finally {
      if (mounted) setState(() => isWorking = false);
    }
  }

  Future<void> _createRoom() async {
    setState(() => isWorking = true);
    try {
      final session = await _groupSessionService.createRoom(
        gate: widget.gate,
        budget: widget.budget,
      );
      if (!mounted) return;
      await _openRoom(session);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not create room: $error')));
    } finally {
      if (mounted) setState(() => isWorking = false);
    }
  }

  Future<void> _openRoom(FirebaseGroupSession session) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FoodSwipeScreen(
          gate: session.gate,
          budget: session.budget,
          isGroup: true,
          roomCode: session.roomCode,
          memberIds: [session.memberId],
          onlineMemberId: session.memberId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 20, 32, 24),
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
              const SizedBox(height: 28),
              const Text(
                'Room code',
                style: TextStyle(
                  fontSize: 40,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: TiniderColors.brown,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ask your friend for the 4-digit code.',
                style: TextStyle(fontSize: 20, color: TiniderColors.muted),
              ),
              const SizedBox(height: 22),
              Row(
                children: List.generate(4, (index) {
                  final filled = index < code.length;
                  return Expanded(
                    child: Container(
                      height: 86,
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
              const SizedBox(height: 24),
              Expanded(
                child: GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.72,
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
                      label: 'del',
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
                label: 'Join room',
                onPressed: code.length == 4 && !isWorking ? _joinRoom : null,
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: isWorking ? null : _createRoom,
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
