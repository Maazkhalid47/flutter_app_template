import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../cache/onboarding_prefs.dart';
import '../../constant/app_color/app_colors.dart';
import '../../constant/app_radius/app_radius.dart';
import '../../constant/app_spacing/app_spacing.dart';
import '../../constant/app_text_styles/app_text_styles.dart';
import '../../onboarding/onboarding_item.dart';
import '../../routes/app_routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  bool get _isLastPage => _currentPage == onboardingItems.length - 1;

  Future<void> _finishOnboarding() async {
    await OnboardingPrefs.markOnboardingSeen();
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  void _advance() {
    if (_isLastPage) {
      _finishOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: onboardingItems.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) => GestureDetector(
              onTap: _advance,
              child: _OnboardingPage(item: onboardingItems[index]),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: TextButton(
                  onPressed: _finishOnboarding,
                  style: TextButton.styleFrom(foregroundColor: AppColors.white),
                  child: Text(
                    'Skip',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
                  ),
                ),
              ),
            ),
          ),
          // ---- Bottom bar: small dot indicator (left) + small Next button (right) ----
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // small dot indicator
                  Row(
                    children: List.generate(
                      onboardingItems.length,
                          (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 6),
                        height: 6,
                        width: index == _currentPage ? 18 : 6,
                        decoration: BoxDecoration(
                          color: index <= _currentPage
                              ? AppColors.white
                              : AppColors.white.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                      ),
                    ),
                  ),
                  // small next button
                  _NextButton(isLastPage: _isLastPage, onTap: _advance),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  final bool isLastPage;
  final VoidCallback onTap;

  const _NextButton({required this.isLastPage, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: AppColors.white.withValues(alpha: 0.9),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(
                isLastPage ? Icons.check_rounded : Icons.arrow_forward_rounded,
                size: 18,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingItem item;

  const _OnboardingPage({required this.item});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          item.imageAsset,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            color: AppColors.gray900,
            alignment: Alignment.center,
            child: const Icon(Icons.image_outlined, size: 96, color: AppColors.gray500),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
              stops: const [0.5, 1.0],
            ),
          ),
        ),
        Positioned(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: AppSpacing.xxxl,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: BackdropFilter(
              // thora sa aur blurness badha diya (12 -> 18)
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Text(
                  item.text,
                  style: AppTextStyles.h2.copyWith(color: AppColors.white),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}