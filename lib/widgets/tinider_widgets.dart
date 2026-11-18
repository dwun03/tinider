import 'package:flutter/material.dart';

import '../theme/tinider_theme.dart';

class TiniderBackButton extends StatelessWidget {
  const TiniderBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back',
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: () => Navigator.maybePop(context),
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: TiniderColors.cream,
            shape: BoxShape.circle,
            border: Border.all(color: TiniderColors.brown, width: 3),
            boxShadow: const [
              BoxShadow(color: TiniderColors.brown, offset: Offset(0, 5)),
            ],
          ),
          child: const Icon(
            Icons.arrow_back,
            size: 30,
            color: TiniderColors.brown,
          ),
        ),
      ),
    );
  }
}

class TiniderPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const TiniderPrimaryButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return SizedBox(
      width: double.infinity,
      height: 66,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled
              ? TiniderColors.yellow
              : const Color(0xFFFFE6A8),
          foregroundColor: enabled
              ? TiniderColors.brown
              : const Color(0xFF8A8068),
          disabledBackgroundColor: const Color(0xFFFFE6A8),
          disabledForegroundColor: const Color(0xFF8A8068),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          side: BorderSide(
            color: enabled ? TiniderColors.cream : const Color(0xFFBEB79E),
            width: 3,
          ),
        ),
        child: Stack(
          children: [
            if (enabled)
              const Positioned(
                left: 0,
                right: 0,
                bottom: -7,
                child: SizedBox(
                  height: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: TiniderColors.brown,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(18),
                      ),
                    ),
                  ),
                ),
              ),
            Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TiniderContextPill extends StatelessWidget {
  final String label;
  const TiniderContextPill(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: TiniderColors.cream,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: TiniderColors.brown, width: 2),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: TiniderColors.brown,
        ),
      ),
    );
  }
}
