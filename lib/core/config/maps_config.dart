import 'package:pharmacy_marketplace_app/core/config/app_api_keys.dart';

class MapsConfig {
  const MapsConfig._();

  static const googleMapsApiKey = AppApiKeys.googleMapsApiKey;

  static bool get isConfigured => googleMapsApiKey.trim().isNotEmpty;
}
