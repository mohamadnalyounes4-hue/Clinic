import 'package:flutter/material.dart';
import 'package:nabad/core/theme/nabad_colors.dart';

class PatientLoginHero extends StatelessWidget {
  const PatientLoginHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NabadColors.primary,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: NabadColors.primary.withAlpha(38),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أهلاً بعودتك',
                  style: TextStyle(
                    color: Colors.white.withAlpha(220),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'تسجيل دخول المريض',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ادخل إلى مواعيدك وملفك الطبي بأمان.',
                  style: TextStyle(
                    color: Colors.white.withAlpha(215),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(235),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              color: NabadColors.primary,
              size: 38,
            ),
          ),
        ],
      ),
    );
  }
}
