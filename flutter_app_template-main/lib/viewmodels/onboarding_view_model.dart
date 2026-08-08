import '../onboarding/onboarding_repository.dart';
import '../services/analytics_service.dart';
import '../utils/logger.dart';
import 'base_view_model.dart';

/// Drives the onboarding carousel.
///
/// Page index lives here rather than in the widget's `State` so "am I on the
/// last page?" — the rule that decides whether the button says Next or Get
/// Started — is testable without pumping a widget.
class OnboardingViewModel extends BaseViewModel {
  OnboardingViewModel({
    required OnboardingRepository repository,
    required AnalyticsService analytics,
    required AppLogger logger,
    required int pageCount,
  }) : _repository = repository,
       _analytics = analytics,
       _logger = logger,
       _pageCount = pageCount;

  final OnboardingRepository _repository;
  final AnalyticsService _analytics;
  final AppLogger _logger;
  final int _pageCount;

  int _currentPage = 0;

  int get currentPage => _currentPage;

  int get pageCount => _pageCount;

  bool get isLastPage => _currentPage >= _pageCount - 1;

  bool get isFirstPage => _currentPage == 0;

  void onPageChanged(int index) {
    if (index == _currentPage) return;
    _currentPage = index;
    notify();
  }

  /// The next index to animate to, or `null` when finished.
  int? nextPageIndex() => isLastPage ? null : _currentPage + 1;

  /// Marks onboarding done. Returns `true` when the app should navigate on.
  ///
  /// Deliberately returns `true` even if persistence fails: blocking a user at
  /// the door because a preference write failed is worse than showing
  /// onboarding again next launch.
  Future<bool> complete({bool skipped = false}) async {
    setBusy(value: true);
    final result = await _repository.markCompleted();
    await _analytics.logEvent(
      AnalyticsEvent.onboardingCompleted,
      parameters: {'skipped': skipped, 'exit_page': _currentPage},
    );
    setBusy(value: false);
    result.when(
      success: (_) {},
      failure: (exception) => _logger.warning(
        'Could not persist onboarding flag: '
        '${exception.message}',
      ),
    );
    return true;
  }
}
