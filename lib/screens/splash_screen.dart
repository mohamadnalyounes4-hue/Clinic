import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Splash Screen with blurred background image and animated logo
/// Inherits from BaseScreen for consistent scaffold structure
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoAnimation;
  late AnimationController _arrowController;
  late Animation<Offset> _arrowAnimation;
  bool _showButton = false;

  // Swipe gesture variables
  double _dragOffset = 0.0;
  final double _dragThreshold =
      320.0; // المسافة المطلوبة للسحب (مساوية لعرض الزر)

  // Fixed background image
  static const String _backgroundImage = 'assets/images/5.jpg';

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    );

    // Arrow animation controller
    _arrowController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();

    _arrowAnimation =
        Tween<Offset>(
          begin: const Offset(-0.5, 0),
          end: const Offset(0.5, 0),
        ).animate(
          CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut),
        );

    _logoController.forward().then((_) {
      setState(() {
        _showButton = true;
      });
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _arrowController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    Navigator.pushNamed(context, '/login');
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dx;
      if (_dragOffset < 0) {
        _dragOffset = 0;
      }
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_dragOffset >= _dragThreshold) {
      _navigateToLogin();
    } else {
      setState(() {
        _dragOffset = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image with blur
          Positioned.fill(
            child: Image.asset(_backgroundImage, fit: BoxFit.cover),
          ),
          // Blur overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.3)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(),
              ),
            ),
          ),
          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with animation (no frame)
                FadeTransition(
                  opacity: _logoAnimation,
                  child: ScaleTransition(
                    scale: _logoAnimation,
                    child: Image.asset(
                      'assets/images/logo1.png',
                      width: 300,
                      height: 300,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Text "نهتم بصحتك"
                FadeTransition(opacity: _logoAnimation),
                const SizedBox(height: 60),
                // Swipe to start indicator with animation
                AnimatedOpacity(
                  opacity: _showButton ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: Column(
                    children: [
                      // Swipe container
                      GestureDetector(
                        onPanUpdate: _handlePanUpdate,
                        onPanEnd: _handlePanEnd,
                        child: Container(
                          width: 320,
                          height: 70,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(35),
                            color: AppColors.primary.withOpacity(0.2),
                            border: Border.all(
                              color: AppColors.white.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(35),
                            child: Stack(
                              children: [
                                // Progress indicator
                                Positioned.fill(
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: (_dragOffset / _dragThreshold)
                                        .clamp(0.0, 1.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(35),
                                        color: AppColors.primary.withOpacity(
                                          0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Text
                                Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'اسحب للبدء',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.white,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Row(
                                        children: [
                                          SlideTransition(
                                            position: _arrowAnimation,
                                            child: Icon(
                                              Icons.arrow_forward,
                                              color: AppColors.white,
                                              size: 20,
                                            ),
                                          ),
                                          SlideTransition(
                                            position: _arrowAnimation,
                                            child: Icon(
                                              Icons.arrow_forward,
                                              color: AppColors.white
                                                  .withOpacity(0.7),
                                              size: 20,
                                            ),
                                          ),
                                          SlideTransition(
                                            position: _arrowAnimation,
                                            child: Icon(
                                              Icons.arrow_forward,
                                              color: AppColors.white
                                                  .withOpacity(0.4),
                                              size: 20,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      // Progress text
                      Text(
                        '${(_dragOffset / _dragThreshold * 100).toInt()}%',
                        style: TextStyle(fontSize: 14, color: AppColors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
