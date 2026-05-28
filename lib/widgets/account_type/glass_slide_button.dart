import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:nabad/core/theme/nabad_colors.dart';

class GlassSlideButton extends StatefulWidget {
  final String label;
  final VoidCallback onComplete;

  const GlassSlideButton({
    super.key,
    required this.label,
    required this.onComplete,
  });

  @override
  State<GlassSlideButton> createState() => _GlassSlideButtonState();
}

class _GlassSlideButtonState extends State<GlassSlideButton> {
  static const double _height = 62;
  static const double _thumbSize = 52;

  double _progress = 0;
  bool _isDragging = false;
  bool _isCompleted = false;

  void _updateProgress(DragUpdateDetails details, double trackWidth) {
    if (_isCompleted) return;

    final double travelDistance = trackWidth - _thumbSize - 10;
    final double nextProgress = _progress + (details.delta.dx / travelDistance);

    setState(() {
      _isDragging = true;
      _progress = nextProgress.clamp(0.0, 1.0);
    });
  }

  Future<void> _finishDrag() async {
    if (_isCompleted) return;

    if (_progress >= 0.82) {
      setState(() {
        _progress = 1;
        _isDragging = false;
        _isCompleted = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 260));
      if (mounted) {
        widget.onComplete();
      }
      return;
    }

    setState(() {
      _progress = 0;
      _isDragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double trackWidth = constraints.maxWidth;
        final double maxLeft = trackWidth - _thumbSize - 5;
        final double thumbLeft = 5 + (maxLeft - 5) * _progress;

        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: _height,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(130),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withAlpha(210),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: NabadColors.primary.withAlpha(28),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedContainer(
                    duration: Duration(milliseconds: _isDragging ? 0 : 240),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: (_progress * 0.92).clamp(0.0, 0.92),
                      child: Container(
                        height: _height,
                        decoration: BoxDecoration(
                          color: NabadColors.primary.withAlpha(92),
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 160),
                    opacity: _isCompleted ? 0 : (1 - (_progress * 0.55)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 66),
                      child: Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: NabadColors.deepTeal,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: thumbLeft,
                    top: 5,
                    child: GestureDetector(
                      onHorizontalDragUpdate: (details) =>
                          _updateProgress(details, trackWidth),
                      onHorizontalDragEnd: (_) => _finishDrag(),
                      onHorizontalDragCancel: _finishDrag,
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: _isDragging ? 0 : 240),
                        curve: Curves.easeOutCubic,
                        width: _thumbSize,
                        height: _thumbSize,
                        decoration: BoxDecoration(
                          color: NabadColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withAlpha(170),
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: NabadColors.primary.withAlpha(80),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: Icon(
                            _isCompleted
                                ? Icons.check_rounded
                                : Icons.arrow_back_rounded,
                            key: ValueKey(_isCompleted),
                            color: Colors.white,
                            size: 25,
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
      },
    );
  }
}
