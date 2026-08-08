import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/ui_constants.dart';
import '../dependency_injection/service_locator.dart';
import '../extensions/context_extensions.dart';
import '../onboarding/onboarding_page_data.dart';
import '../onboarding/onboarding_repository.dart';
import '../services/analytics_service.dart';
import '../utils/logger.dart';
import '../viewmodels/onboarding_view_model.dart';
import '../widgets/app_button.dart';

/// The first-run carousel.
///
/// Owns its view model locally (created in [initState], disposed with the
/// screen) because nothing else in the app needs it — the opposite of
/// `AuthViewModel`, which lives at the root.
///
/// It does not navigate on completion: it flips the persisted flag, and
/// `RouteGuard` moves the user along. One source of truth for routing.
class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  late final OnboardingViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = OnboardingViewModel(
      repository: getIt<OnboardingRepository>(),
      analytics: getIt<AnalyticsService>(),
      logger: getIt<AppLogger>(),
      // Page count comes from the same list the UI renders, so adding a slide
      // cannot desynchronise the "is this the last page?" logic.
      pageCount: 3,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    final nextIndex = _viewModel.nextPageIndex();
    if (nextIndex == null) {
      await _viewModel.complete();
      return;
    }
    await _pageController.animateToPage(
      nextIndex,
      duration: UiConstants.durationNormal,
      curve: UiConstants.defaultCurve,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = OnboardingPageData.pagesFor(context.l10n);

    return ChangeNotifierProvider<OnboardingViewModel>.value(
      value: _viewModel,
      child: Consumer<OnboardingViewModel>(
        builder: (context, viewModel, _) => Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: AppButton.text(
                    label: context.l10n.onboardingSkip,
                    onPressed: viewModel.isBusy
                        ? null
                        : () => viewModel.complete(skipped: true),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: viewModel.onPageChanged,
                    itemCount: pages.length,
                    itemBuilder: (context, index) =>
                        _OnboardingPage(data: pages[index]),
                  ),
                ),
                _PageIndicator(
                  count: pages.length,
                  currentIndex: viewModel.currentPage,
                ),
                Padding(
                  padding: const EdgeInsets.all(UiConstants.spaceLg),
                  child: AppButton(
                    label: viewModel.isLastPage
                        ? context.l10n.onboardingStart
                        : context.l10n.onboardingNext,
                    isLoading: viewModel.isBusy,
                    onPressed: _next,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});

  final OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(UiConstants.spaceLg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Image.asset(
              data.imageAsset,
              fit: BoxFit.contain,
              // The illustrations are placeholders in a fresh template; an
              // icon keeps the flow presentable until real art lands.
              errorBuilder: (context, error, stackTrace) => Icon(
                data.icon ?? Icons.image_outlined,
                size: 96,
                color: context.colors.primary,
              ),
            ),
          ),
          const SizedBox(height: UiConstants.spaceXl),
          Text(
            data.title,
            style: context.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: UiConstants.spaceSm),
          Text(
            data.description,
            style: context.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.count, required this.currentIndex});

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: UiConstants.durationFast,
          margin: const EdgeInsets.symmetric(horizontal: UiConstants.spaceXs),
          height: UiConstants.spaceSm,
          width: isActive ? UiConstants.spaceLg : UiConstants.spaceSm,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(UiConstants.radiusPill),
            color: isActive
                ? context.colors.primary
                : context.colors.outlineVariant,
          ),
        );
      }),
    );
  }
}
