import 'package:flutter/foundation.dart';

class AppApiKeys {
  const AppApiKeys._();

  // Paste your Google Maps API key here.
  static const String googleMapsApiKey =
      'AIzaSyAtD6wqsUyg1Fg_450U2geEf-iTS_I0ZRs';

  // Paste your PayMongo public key here only for local testing if needed.
  static const String paymongoPublicKey = 'pk_test_xCFPEEYusK7eCzoqUVvXKFad';

  static String get paymongoCheckoutSessionEndpoint {
    if (kIsWeb) {
      return 'http://localhost:5066/api/paymongo/create-checkout-session';
    }
    return 'http://10.0.2.2:5066/api/paymongo/create-checkout-session';
  }

  // Keep secret keys on your backend only. Never use them in the Flutter app.
  static const String paymongoSecretKey = '';
}
