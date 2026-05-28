import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nabad/core/theme/nabad_colors.dart';

class RegisterHeader extends StatelessWidget {
  final VoidCallback onBack;
  final Uint8List? imageBytes;
  final VoidCallback onPickImage;

  const RegisterHeader({
    super.key,
    required this.onBack,
    required this.imageBytes,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            height: 132,
            margin: const EdgeInsets.fromLTRB(22, 16, 22, 0),
            decoration: BoxDecoration(
              color: NabadColors.primary,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: NabadColors.primary.withAlpha(36),
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/2.jpg',
                    fit: BoxFit.cover,
                    alignment: const Alignment(0.2, -0.4),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: NabadColors.primary.withAlpha(175),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  top: 14,
                  child: IconButton(
                    onPressed: onBack,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withAlpha(225),
                      foregroundColor: NabadColors.primary,
                      fixedSize: const Size(42, 42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: -42,
                  child: Center(
                    child: Container(
                      width: 116,
                      height: 86,
                      decoration: const BoxDecoration(
                        color: NabadColors.background,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(58),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: _FloatingProfilePhotoButton(
                imageBytes: imageBytes,
                onTap: onPickImage,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingProfilePhotoButton extends StatelessWidget {
  final Uint8List? imageBytes;
  final VoidCallback onTap;

  const _FloatingProfilePhotoButton({
    required this.imageBytes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 55),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Ink(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: NabadColors.background, width: 8),
                  boxShadow: [
                    BoxShadow(
                      color: NabadColors.primary.withAlpha(3),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: imageBytes == null
                      ? const Icon(
                          Icons.add_a_photo_rounded,
                          color: NabadColors.primary,
                          size: 34,
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(imageBytes!, fit: BoxFit.cover),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                height: 28,
                                color: Colors.black.withAlpha(75),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(235),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: NabadColors.primary.withAlpha(22)),
            ),
            child: const Text(
              'ضع صورة شخصية',
              style: TextStyle(
                color: NabadColors.deepTeal,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
