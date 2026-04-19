class AppApiKeys {
  const AppApiKeys._();

  // Paste your Google Maps API key here.
  static const String googleMapsApiKey =
      'AIzaSyAtD6wqsUyg1Fg_450U2geEf-iTS_I0ZRs';

  // Paste your PayMongo public key here only for local testing if needed.
  static const String paymongoPublicKey = 'pk_test_xCFPEEYusK7eCzoqUVvXKFad';

  // Point this to your ASP.NET backend endpoint that creates a PayMongo Checkout
  // Session and returns JSON like:
  // { "checkout_url": "https://checkout.paymongo.com/..." }
  static const String paymongoCheckoutSessionEndpoint =
      'PUT_MY_CSHARP_BACKEND_URL_HERE';

  // Keep secret keys on your backend only. Never use them in the Flutter app.
  static const String paymongoSecretKey = '';
}
