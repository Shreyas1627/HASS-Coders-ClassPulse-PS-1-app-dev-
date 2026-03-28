import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PinDisplay extends StatelessWidget {
  final String pin;

  const PinDisplay({super.key, required this.pin});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isFilled = index < pin.length;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 60,
          height: 68,
          decoration: BoxDecoration(
            color: AppColors.pinBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isFilled ? AppColors.pinActiveBorder : AppColors.pinBorder,
              width: isFilled ? 2 : 1.5,
            ),
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 120),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: isFilled
                  ? Text(
                      pin[index],
                      key: ValueKey('pin_${index}_${pin[index]}'),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        );
      }),
    );
  }
}
