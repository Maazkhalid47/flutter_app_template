import '../core/typedefs.dart';
import '../enums/payment_status.dart';

/// A payment in progress, as the app sees it.
///
/// Created by **your backend**, never by the app: creating an intent requires
/// the Stripe secret key, and a secret key shipped in a mobile binary is a
/// secret key published to the world. The app only ever receives the client
/// secret needed to confirm it.
class PaymentIntentModel {
  const PaymentIntentModel({
    required this.id,
    required this.clientSecret,
    required this.amountMinorUnits,
    required this.currency,
    required this.status,
    this.customerId,
    this.ephemeralKey,
    this.metadata = const {},
  });

  factory PaymentIntentModel.fromJson(Json json) => PaymentIntentModel(
    id: json['id'] as String,
    clientSecret: json['client_secret'] as String,
    amountMinorUnits: (json['amount'] as num).toInt(),
    currency: (json['currency'] as String? ?? 'usd').toUpperCase(),
    status: parseStatus(json['status'] as String?),
    customerId: json['customer'] as String?,
    ephemeralKey: json['ephemeral_key'] as String?,
    metadata: switch (json['metadata']) {
      final Map<String, dynamic> value => value,
      _ => const {},
    },
  );

  final String id;

  /// Single-use secret that authorises confirming this one payment. Safe to
  /// hold client-side; still never log it.
  final String clientSecret;

  /// Amount in the currency's smallest unit (cents). Stripe's convention, kept
  /// end to end so no rounding happens in transit.
  final int amountMinorUnits;

  final String currency;
  final PaymentStatus status;
  final String? customerId;

  /// Required by Stripe's saved-payment-method sheet, when you enable it.
  final String? ephemeralKey;

  final Map<String, dynamic> metadata;

  /// Maps Stripe's status vocabulary onto the app's own enum, so no other file
  /// has to know these strings.
  static PaymentStatus parseStatus(String? raw) => switch (raw) {
    'succeeded' => PaymentStatus.succeeded,
    'processing' => PaymentStatus.processing,
    'requires_action' ||
    'requires_confirmation' ||
    'requires_payment_method' => PaymentStatus.requiresAction,
    'canceled' => PaymentStatus.canceled,
    null => PaymentStatus.idle,
    _ => PaymentStatus.failed,
  };

  Json toJson() => {
    'id': id,
    'client_secret': clientSecret,
    'amount': amountMinorUnits,
    'currency': currency,
    'status': status.name,
    'customer': customerId,
    'metadata': metadata,
  };

  @override
  String toString() =>
      'PaymentIntentModel(id: $id, amount: $amountMinorUnits $currency, '
      'status: ${status.name})';
}

/// What the app asks the backend to charge for.
///
/// The amount is included for display and client-side sanity checks only —
/// the backend must recompute the real price from its own data. A client that
/// can name its own price will eventually be asked to pay one cent.
class PaymentRequest {
  const PaymentRequest({
    required this.amountMinorUnits,
    required this.currency,
    this.productId,
    this.description,
    this.metadata = const {},
  });

  final int amountMinorUnits;
  final String currency;
  final String? productId;
  final String? description;
  final Map<String, dynamic> metadata;

  Json toJson() => {
    'amount': amountMinorUnits,
    'currency': currency.toLowerCase(),
    if (productId != null) 'product_id': productId,
    if (description != null) 'description': description,
    if (metadata.isNotEmpty) 'metadata': metadata,
  };
}
