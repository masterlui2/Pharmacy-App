import 'package:flutter/foundation.dart';

class AppApiKeys {
  const AppApiKeys._();

  static const String _backendBaseUrlOverride = String.fromEnvironment(
    'BACKEND_BASE_URL',
  );
  static const String _checkoutEndpointOverride = String.fromEnvironment(
    'PAYMONGO_CHECKOUT_SESSION_ENDPOINT',
  );

  // Paste your Google Maps API key here.
  static const String googleMapsApiKey =
      'AIzaSyAtD6wqsUyg1Fg_450U2geEf-iTS_I0ZRs';

  // Paste your PayMongo public key here only for local testing if needed.
  static const String paymongoPublicKey = 'pk_test_xCFPEEYusK7eCzoqUVvXKFad';

  static String get backendBaseUrl {
    final override = _normalizeConfiguredUrl(_backendBaseUrlOverride);
    if (override != null) {
      return override;
    }

    if (kIsWeb) {
      final currentUri = Uri.base;
      final scheme = currentUri.scheme.isEmpty ? 'http' : currentUri.scheme;
      final host = currentUri.host.isEmpty ? 'localhost' : currentUri.host;
      return Uri(scheme: scheme, host: host, port: 5066).toString();
    }

    return 'http://10.0.2.2:5066';
  }

  static String get paymongoCheckoutSessionEndpoint {
    final override = _normalizeConfiguredUrl(_checkoutEndpointOverride);
    if (override != null) {
      return override;
    }

    return '$backendBaseUrl/api/paymongo/create-checkout-session';
  }

  // Keep secret keys on your backend only. Never use them in the Flutter app.
  static const String paymongoSecretKey = '';

  static String? _normalizeConfiguredUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    return trimmed.replaceFirst(RegExp(r'/+$'), '');
  }
}
