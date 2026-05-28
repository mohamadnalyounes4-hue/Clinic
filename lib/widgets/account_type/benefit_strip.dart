import 'package:flutter/material.dart';
import 'package:nabad/core/theme/nabad_colors.dart';
import 'package:nabad/widgets/account_type/account_role.dart';

class BenefitStrip extends StatelessWidget {
  final AccountRole role;

  const BenefitStrip({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final benefits = role == AccountRole.patient
        ? const [
            _MiniBenefit(icon: Icons.calendar_month_rounded, label: 'مواعيد'),
            _MiniBenefit(icon: Icons.folder_rounded, label: 'ملف طبي'),
            _MiniBenefit(icon: Icons.science_rounded, label: 'تحاليل'),
          ]
        : const [
            _MiniBenefit(icon: Icons.event_available_rounded, label: 'جدولة'),
            _MiniBenefit(icon: Icons.groups_rounded, label: 'مرضى'),
            _MiniBenefit(icon: Icons.edit_note_rounded, label: 'وصفات'),
          ];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      transitionBuilder: (child, animation) {
        final offsetAnimation =
            Tween<Offset>(
              begin: const Offset(0, 0.2),
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
        key: ValueKey(role),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(220),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: NabadColors.primary.withAlpha(20)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: benefits,
        ),
      ),
    );
  }
}

class _MiniBenefit extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniBenefit({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: NabadColors.softTeal,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: NabadColors.primary, size: 18),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            color: NabadColors.deepTeal,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
