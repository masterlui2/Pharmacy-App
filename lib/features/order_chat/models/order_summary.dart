import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/order_chat_firestore_reader.dart';

class OrderSummary {
  const OrderSummary({
    required this.orderId,
    required this.customerUid,
    required this.orderReference,
    required this.status,
    required this.pharmacyName,
    required this.pharmacistUid,
    required this.pharmacistName,
    required this.requiresPrescription,
    required this.createdAt,
    required this.updatedAt,
    required this.lastMessageAt,
  });

  factory OrderSummary.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    return OrderSummary(
      orderId: doc.id,
      customerUid: readStringByPaths(data, const ['customerUid']) ?? '',
      orderReference: readStringByPaths(
            data,
            const [
              'referenceNumber',
              'reference_number',
              'orderReference',
              'order_reference',
            ],
          ) ??
          doc.id,
      status: readStringByPaths(
            data,
            const [
              'status',
              'orderStatus',
              'order_status',
              'paymentStatus',
              'payment_status',
            ],
          ) ??
          'Processing',
      pharmacyName: readStringByPaths(
            data,
            const ['pharmacyName', 'pharmacy.name', 'storeName', 'branchName'],
          ) ??
          'Your pharmacy',
      pharmacistUid: readStringByPaths(
        data,
        const ['pharmacistUid', 'pharmacist.uid'],
      ),
      pharmacistName: readStringByPaths(
            data,
            const [
              'pharmacistName',
              'pharmacist.name',
              'pharmacist.displayName',
            ],
          ) ??
          '',
      requiresPrescription: readBoolByPaths(
            data,
            const [
              'requiresPrescription',
              'prescriptionRequired',
              'prescription.required',
            ],
          ) ??
          false,
      createdAt: readDateTimeByPaths(data, const ['createdAt']),
      updatedAt: readDateTimeByPaths(data, const ['updatedAt']),
      lastMessageAt: readDateTimeByPaths(data, const ['lastMessageAt']),
    );
  }

  final String orderId;
  final String customerUid;
  final String orderReference;
  final String status;
  final String pharmacyName;
  final String? pharmacistUid;
  final String pharmacistName;
  final bool requiresPrescription;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastMessageAt;

  DateTime get sortDate =>
      lastMessageAt ??
      updatedAt ??
      createdAt ??
      DateTime.fromMillisecondsSinceEpoch(0);

  bool get isAssigned =>
      pharmacistName.trim().isNotEmpty ||
      (pharmacistUid != null && pharmacistUid!.trim().isNotEmpty);

  bool get isClosed {
    final normalized = status.toLowerCase();
    return normalized.contains('cancel') ||
        normalized.contains('failed') ||
        normalized.contains('declined');
  }

  bool get isActive {
    final normalized = status.toLowerCase();
    return normalized.contains('deliver') ||
        normalized.contains('paid') ||
        normalized.contains('complete');
  }

  String get statusLabel => formatStatusLabel(status);

  String get displayPharmacistName {
    final normalizedName = pharmacistName.trim();
    if (normalizedName.isNotEmpty) {
      return normalizedName;
    }

    return isAssigned ? 'Assigned pharmacist' : 'Pharmacy support';
  }

  String get subtitle {
    if (!isAssigned) {
      return 'Order #$orderReference - $statusLabel - awaiting assignment';
    }

    return 'Order #$orderReference - $pharmacyName - $statusLabel';
  }
}
