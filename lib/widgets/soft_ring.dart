import 'package:flutter/material.dart';
import 'package:nabad/core/theme/nabad_colors.dart';

class SoftRing extends StatelessWidget {
  final double size;

  const SoftRing({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: NabadColors.primary.withAlpha(10),
            width: 32,
          ),
        ),
      ),
    );
  }
}
