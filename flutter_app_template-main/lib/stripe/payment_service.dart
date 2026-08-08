import '../core/typedefs.dart';
import 'payment_intent.dart';

/// Payments, with no provider named in the signature.
///
/// View models depend on this. Swapping Stripe for another processor — or
/// adding one alongside — means writing a second implementation, not editing a
/// checkout screen.
abstract interface class PaymentService {
  /// Prepares the SDK. Safe to call more than once.
  Future<void> initialize();

  /// Whether payments are usable in this build (keys present, SDK ready).
  bool get isAvailable;

  /// Asks the backend to create an intent. Returns the client secret the app
  /// needs to confirm it.
  AsyncResult<PaymentIntentModel> createPaymentIntent(PaymentRequest request);

  /// Presents the payment sheet and completes the charge.
  ///
  /// A success here means the *charge* was authorised. Do not unlock paid
  /// features on this alone — wait for your backend to confirm via webhook.
  /// See `docs/integrations/stripe.md`.
  AsyncResult<PaymentIntentModel> confirmPayment(PaymentIntentModel intent);

  /// Convenience: create then confirm, the usual one-tap checkout.
  AsyncResult<PaymentIntentModel> checkout(PaymentRequest request);

  /// Re-reads status from the backend. Use it after returning from a 3-D Secure
  /// redirect, or when resuming the app mid-payment.
  AsyncResult<PaymentIntentModel> refreshStatus(String paymentIntentId);
}
