class AppApiKeys {
  const AppApiKeys._();

  // Keep real keys out of git. Load them locally before building.
  static const String googleMapsApiKey = '';

  // Publishable keys can still be rotated and injected locally.
  static const String paymongoPublicKey = '';

  // Never commit a PayMongo secret key in a Flutter app.
  // Keep secret keys on your backend only.
  static const String paymongoSecretKey = '';
}
