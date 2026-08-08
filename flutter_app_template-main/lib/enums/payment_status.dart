/// Provider-agnostic outcome of a payment attempt.
///
/// Stripe-specific status strings are mapped onto this enum inside
/// `stripe/`, so view models never depend on Stripe's vocabulary.
enum PaymentStatus {
  idle,
  requiresAction,
  processing,
  succeeded,
  failed,
  canceled;

  bool get isTerminal =>
      this == PaymentStatus.succeeded ||
      this == PaymentStatus.failed ||
      this == PaymentStatus.canceled;
}
