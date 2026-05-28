import 'package:flutter/material.dart';
import 'package:nabad/core/theme/nabad_colors.dart';
import 'package:nabad/widgets/account_type/account_role.dart';

class RolePreview extends StatelessWidget {
  final AccountRoleContent content;

  const RolePreview({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 340),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        final offsetAnimation =
            Tween<Offset>(
              begin: const Offset(0.08, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offsetAnimation, child: child),
        );
      },
      child: Container(
        key: ValueKey(content.title),
        height: 250,
        decoration: BoxDecoration(
          color: NabadColors.deepTeal,
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: NabadColors.primary.withAlpha(42),
              blurRadius: 34,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Image.asset(content.image, fit: BoxFit.cover),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    NabadColors.deepTeal.withAlpha(238),
                    NabadColors.deepTeal.withAlpha(135),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Positioned(
              right: 22,
              left: 22,
              bottom: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(232),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          content.icon,
                          color: NabadColors.primary,
                          size: 17,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          content.title,
                          style: const TextStyle(
                            color: NabadColors.deepTeal,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    content.headline,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      height: 1.18,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    content.subtitle,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white.withAlpha(225),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
