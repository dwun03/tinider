import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/tinider_theme.dart';
import '../widgets/tinider_widgets.dart';
import 'group_screens.dart';
import 'saved_spots_screen.dart';
import 'swipe_screens.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TiniderColors.yellow,
      body: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WhereAtScreen()),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final circleSize = constraints.maxWidth * 1.34;
            final logoNameWidth = (constraints.maxWidth - 24).clamp(0.0, 380.0);
            return Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: (constraints.maxWidth - circleSize) / 2,
                  top: (constraints.maxHeight - circleSize) / 2,
                  child: Container(
                    width: circleSize,
                    height: circleSize,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF0B3),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  left: constraints.maxWidth * 0.14,
                  top: constraints.maxHeight * 0.30,
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 24,
                    color: TiniderColors.brown,
                  ),
                ),
                Positioned(
                  right: constraints.maxWidth * 0.14,
                  top: constraints.maxHeight * 0.27,
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 17,
                    color: TiniderColors.brown,
                  ),
                ),
                Positioned(
                  left: constraints.maxWidth * 0.30,
                  top: constraints.maxHeight * 0.65,
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color: TiniderColors.brown,
                  ),
                ),
                Positioned(
                  left: constraints.maxWidth * 0.22,
                  top: constraints.maxHeight * 0.75,
                  child: const _SplashDot(color: TiniderColors.mint, size: 13),
                ),
                Positioned(
                  right: constraints.maxWidth * 0.11,
                  top: constraints.maxHeight * 0.69,
                  child: const _SplashDot(color: TiniderColors.red, size: 11),
                ),
                Positioned(
                  right: constraints.maxWidth * 0.09,
                  top: constraints.maxHeight * 0.38,
                  child: const _SplashDot(color: TiniderColors.white, size: 8),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 82,
                        height: 82,
                        child: SvgPicture.asset(
                          'assets/images/Logo/tinider_icon.svg',
                          width: 82,
                          height: 82,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: logoNameWidth,
                        child: const Text(
                          'Tinider',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 52,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -2,
                            color: TiniderColors.brown,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Let's eat!",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: TiniderColors.brown,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 24,
                  child: Center(
                    child: Text(
                      'Tap to continue',
                      style: const TextStyle(
                        fontSize: 14,
                        color: TiniderColors.brown,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SplashDot extends StatelessWidget {
  final Color color;
  final double size;

  const _SplashDot({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: TiniderColors.brown, width: 1.5),
      ),
    );
  }
}

class WhereAtScreen extends StatefulWidget {
  const WhereAtScreen({super.key});

  @override
  State<WhereAtScreen> createState() => _WhereAtScreenState();
}

class _WhereAtScreenState extends State<WhereAtScreen> {
  String gate = 'P. Noval';
  String budget = 'Regular';
  String mode = 'Solo';

  void _continue() {
    if (mode == 'Group') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GroupChoiceScreen(gate: gate, budget: budget),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              FoodSwipeScreen(gate: gate, budget: budget, isGroup: false),
        ),
      );
    }
  }

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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(
                    child: Text(
                      'Where at?',
                      style: TextStyle(
                        fontSize: 40,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        color: TiniderColors.brown,
                      ),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SavedSpotsScreen(),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: TiniderColors.yellow,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: TiniderColors.brown,
                          width: 2.5,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bookmark_border,
                            size: 18,
                            color: TiniderColors.brown,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Saved',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: TiniderColors.brown,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Set your gate and budget',
                style: TextStyle(fontSize: 20, color: TiniderColors.muted),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nearest gate',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: TiniderColors.brown,
                        ),
                      ),
                      const SizedBox(height: 14),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.15,
                        children: ['Dapitan', 'P. Noval', 'Lacson', 'España']
                            .map(
                              (value) => _OutlineChoice(
                                label: value,
                                selected: gate == value,
                                onTap: () => setState(() => gate = value),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 26),
                      const Text(
                        'Budget',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: TiniderColors.brown,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          for (final item in const [
                            ('₱', 'Tipid'),
                            ('₱₱', 'Regular'),
                            ('₱₱₱', "Deserve 'Ko To"),
                          ])
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: _BudgetChoice(
                                  price: item.$1,
                                  label: item.$2,
                                  selected: budget == item.$2,
                                  onTap: () => setState(() => budget = item.$2),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Mode',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: TiniderColors.brown,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final value in const ['Solo', 'Group'])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: _OutlineChoice(
                          label: value,
                          selected: mode == value,
                          onTap: () => setState(() => mode = value),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TiniderPrimaryButton(label: 'Continue', onPressed: _continue),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlineChoice extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OutlineChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? TiniderColors.yellow : TiniderColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? TiniderColors.brown : TiniderColors.white,
            width: selected ? 3 : 2,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(color: TiniderColors.brown, offset: Offset(0, 4)),
                ]
              : null,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: TiniderColors.brown,
          ),
        ),
      ),
    );
  }
}

class _BudgetChoice extends StatelessWidget {
  final String price;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BudgetChoice({
    required this.price,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? TiniderColors.yellow : TiniderColors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? TiniderColors.brown : TiniderColors.cream,
                width: selected ? 3 : 2,
              ),
            ),
            child: Text(
              price,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: TiniderColors.brown,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: TiniderColors.brown,
            ),
          ),
        ],
      ),
    );
  }
}
