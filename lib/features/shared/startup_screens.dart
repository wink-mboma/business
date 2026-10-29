import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';

/// Shown on every cold launch. First-launch routing happens after the splash.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _continueAfterSplash();
  }

  Future<void> _continueAfterSplash() async {
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding =
        prefs.getBool('mono_store_onboarding_complete') ?? false;
    if (!mounted) return;
    context.go(hasSeenOnboarding ? '/' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Image.asset("assets/light-logo.png"),
                ),
              ),
              const SizedBox(height: 22),
              Image.asset("assets/dark-logo2.png"),
              const SizedBox(height: 8),
              const Text(
                'SIMPLE. MODERN. YOURS.',
                style: TextStyle(
                  color: AppColors.grey300,
                  fontSize: 10,
                  letterSpacing: 2.1,
                ),
              ),
              const SizedBox(height: 42),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.kicker,
    required this.title,
    required this.description,
    required this.icon,
  });
  final String kicker;
  final String title;
  final String description;
  final IconData icon;
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;
  bool _saving = false;

  static const _pages = [
    _OnboardingPage(
      kicker: 'WELCOME TO Sound Mafioso',
      title: 'Good finds.\nBeautifully simple.',
      description:
          'Discover everyday essentials and products picked to fit your style.',
      icon: Icons.shopping_bag_outlined,
    ),
    _OnboardingPage(
      kicker: 'MADE FOR YOUR ROUTINE',
      title: 'Find your next\nfavourite thing.',
      description:
          'Explore collections, search with ease and choose the options that suit you.',
      icon: Icons.grid_view_rounded,
    ),
    _OnboardingPage(
      kicker: 'SHOP WITH CONFIDENCE',
      title: 'From cart to\nyour doorstep.',
      description:
          'Keep your cart close, follow your orders and reach our support team when you need help.',
      icon: Icons.local_shipping_outlined,
    ),
  ];

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mono_store_onboarding_complete', true);
    if (!mounted) return;
    context.go('/');
  }

  void _next() {
    if (_index == _pages.length - 1) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_index];
    final wide = MediaQuery.sizeOf(context).width >= 700;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                wide ? 36 : 24,
                14,
                wide ? 36 : 24,
                20,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(width: 0,),
                      const Spacer(),
                      TextButton(
                        onPressed: _saving ? null : _finish,
                        child: const Text(
                          'Skip',
                          style: TextStyle(color: AppColors.grey700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _pages.length,
                      onPageChanged: (value) => setState(() => _index = value),
                      itemBuilder: (context, index) {
                        final item = _pages[index];
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(maxHeight: 330),
                              height: wide
                                  ? 320
                                  : MediaQuery.sizeOf(context).height * 0.36,
                              decoration: BoxDecoration(
                                color: AppColors.grey100,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Positioned(
                                    top: 24,
                                    left: 24,
                                    child: _decorDot(12),
                                  ),
                                  Positioned(
                                    bottom: 28,
                                    right: 28,
                                    child: _decorDot(20),
                                  ),
                                  Container(
                                    width: 164,
                                    height: 184,
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(28),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.black.withOpacity(
                                            0.07,
                                          ),
                                          blurRadius: 30,
                                          offset: const Offset(0, 14),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      item.icon,
                                      size: 76,
                                      color: AppColors.black,
                                    ),
                                  ),
                                  Positioned(
                                    top: 30,
                                    right: 26,
                                    child: Transform.rotate(
                                      angle: .12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.black,
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                        child: const Text(
                                          'LESS, BUT BETTER',
                                          style: TextStyle(
                                            color: AppColors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.1,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 34),
                            Text(
                              item.kicker,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2.2,
                                color: AppColors.grey600,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              item.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: wide ? 38 : 34,
                                height: 1.12,
                                letterSpacing: -1.2,
                                fontWeight: FontWeight.w800,
                                color: AppColors.black,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 360),
                              child: Text(
                                item.description,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.6,
                                  color: AppColors.grey700,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _index == i ? 26 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: _index == i
                              ? AppColors.black
                              : AppColors.grey300,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.black,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _index == _pages.length - 1
                                      ? 'Get started'
                                      : 'Continue',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${_index + 1} OF ${_pages.length}',
                    style: const TextStyle(
                      fontSize: 9,
                      letterSpacing: 1.8,
                      color: AppColors.grey500,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _decorDot(double size) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      color: AppColors.grey300,
      shape: BoxShape.circle,
    ),
  );
}
