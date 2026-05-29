import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nabad/const/onboarding_model.dart';
import 'package:nabad/core/router/app_router.dart';

class WelcomeInterface extends StatefulWidget {
  const WelcomeInterface({super.key});

  @override
  State<WelcomeInterface> createState() => _WelcomeInterfaceState();
}

class _WelcomeInterfaceState extends State<WelcomeInterface> {
  static const Color primaryColor = Color(0xFF005157);
  static const Color lightTeal = Color(0xFF91C8C8);
  static const Color backgroundColor = Color(0xFFF4F8FB);
  static const Color textColor = Color(0xFF6E7A81);

  int currentIndex = 0;
  final PageController pageController = PageController();
  Timer? autoScrollTimer;

  final List<OnboardingModel> screens = [
    OnboardingModel(
      image: 'assets/images/ddd.jpg',
      title: 'استشر أفضل الأطباء',
      body:
          'تواصل مع نخبة من الأطباء المتخصصين في كافة\nالمجالات الطبية بكل سهولة ويسر من هاتفك.',
    ),
    OnboardingModel(
      image: 'assets/images/ترحيب 2.jpg',
      title: 'احجز موعدك بضغطة زر',
      body:
          'وداعاً للانتظار، اختر الوقت والتاريخ المناسبين لك\nواحجز موعدك فوراً.',
    ),
    OnboardingModel(
      image: 'assets/images/ترحيب 3.jpg',
      title: 'ملفك الطبي في جيبك',
      body:
          'تابع نتائج تحاليلك، وصفاتك الطبية، وتاريخك المرضي\nفي أي وقت ومن أي مكان.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    startAutoScroll();
  }

  void startAutoScroll() {
    autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !pageController.hasClients) return;

      final int nextIndex = currentIndex == screens.length - 1
          ? 0
          : currentIndex + 1;

      pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void changePage(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  void nextOrFinish(int screensLength, BuildContext context) {
    if (currentIndex < screensLength - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    } else {
      finishOnboarding(context);
    }
  }

  void finishOnboarding(BuildContext context) {
    Navigator.pushReplacementNamed(context, AppRoutes.accountType);
  }

  @override
  void dispose() {
    autoScrollTimer?.cancel();
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.08,
                    child: Image.asset(
                      'assets/images/background.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -42,
                top: 120,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.06,
                    child: Image.asset(
                      'assets/images/logoIcon.png',
                      width: 170,
                      height: 170,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -36,
                bottom: 90,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.045,
                    child: Image.asset(
                      'assets/images/logoIcon.png',
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Expanded(
                      child: PageView.builder(
                        controller: pageController,
                        onPageChanged: changePage,
                        itemCount: screens.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Image.asset(
                                  screens[index].image,
                                  height: 300,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 40),
                              Text(
                                screens[index].title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                screens[index].body,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.5,
                                  color: textColor,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        screens.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: currentIndex == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color: currentIndex == index
                                ? primaryColor
                                : lightTeal.withAlpha(128),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => nextOrFinish(screens.length, context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          currentIndex == screens.length - 1
                              ? 'ابدأ الآن'
                              : 'التالي',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
