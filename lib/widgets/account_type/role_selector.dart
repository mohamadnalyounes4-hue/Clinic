import 'package:flutter/material.dart';
import 'package:nabad/core/theme/nabad_colors.dart';

class RoleSelector extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const RoleSelector({
    super.key,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color foreground = isSelected ? Colors.white : NabadColors.deepTeal;

    return AnimatedScale(
      scale: isSelected ? 1.03 : 1,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          height: 112,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? NabadColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? NabadColors.primary
                  : NabadColors.primary.withAlpha(28),
            ),
            boxShadow: [
              BoxShadow(
                color: NabadColors.primary.withAlpha(isSelected ? 42 : 14),
                blurRadius: isSelected ? 30 : 16,
                offset: Offset(0, isSelected ? 14 : 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedScale(
                    scale: isSelected ? 1.1 : 1,
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutBack,
                    child: Icon(icon, color: foreground, size: 27),
                  ),
                  const Spacer(),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? Colors.white
                            : NabadColors.primary.withAlpha(90),
                        width: 1.5,
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutBack,
                          ),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              key: ValueKey('selected'),
                              size: 16,
                              color: NabadColors.primary,
                            )
                          : const SizedBox(key: ValueKey('empty')),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  color: foreground,
                  fontSize: isSelected ? 20 : 19,
                  fontWeight: FontWeight.w900,
                ),
                child: Text(title),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
