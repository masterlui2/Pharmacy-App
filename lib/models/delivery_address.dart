enum PaymentMethod {
  gcash('GCash', 'PayMongo e-wallet'),
  maya('Maya', 'PayMongo e-wallet'),
  card('Card', 'Visa / Mastercard via PayMongo'),
  cod('Cash on Delivery', 'Pay when the rider arrives');

  const PaymentMethod(this.label, this.caption);

  final String label;
  final String caption;
}

class DeliveryAddress {
  const DeliveryAddress({
    required this.recipientName,
    required this.phoneNumber,
    required this.addressLabel,
    required this.streetAddress,
    required this.barangay,
    required this.city,
    required this.notes,
    this.latitude,
    this.longitude,
  });

  final String recipientName;
  final String phoneNumber;
  final String addressLabel;
  final String streetAddress;
  final String barangay;
  final String city;
  final String notes;
  final double? latitude;
  final double? longitude;

  String get shortAddress {
    final parts = [
      streetAddress,
      barangay,
      city,
    ].where((part) => part.trim().isNotEmpty).toList();
    return parts.isEmpty ? 'Add your delivery address' : parts.join(', ');
  }

  DeliveryAddress copyWith({
    String? recipientName,
    String? phoneNumber,
    String? addressLabel,
    String? streetAddress,
    String? barangay,
    String? city,
    String? notes,
    double? latitude,
    double? longitude,
    bool clearCoordinates = false,
  }) {
    return DeliveryAddress(
      recipientName: recipientName ?? this.recipientName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      addressLabel: addressLabel ?? this.addressLabel,
      streetAddress: streetAddress ?? this.streetAddress,
      barangay: barangay ?? this.barangay,
      city: city ?? this.city,
      notes: notes ?? this.notes,
      latitude: clearCoordinates ? null : latitude ?? this.latitude,
      longitude: clearCoordinates ? null : longitude ?? this.longitude,
    );
  }
}
