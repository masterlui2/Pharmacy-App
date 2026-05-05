import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/order_chat_firestore_reader.dart';

class OrderChatMessage {
  const OrderChatMessage({
    required this.messageId,
    required this.type,
    required this.text,
    required this.orderId,
    required this.orderReference,
    required this.senderUid,
    required this.senderRole,
    required this.senderName,
    required this.recipientRole,
    required this.createdAt,
    required this.hasPendingWrites,
  });

  static const String customerRole = 'customer';
  static const String pharmacistRole = 'pharmacist';
  static const String systemRole = 'system';

  factory OrderChatMessage.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    return OrderChatMessage(
      messageId: doc.id,
      type: readStringByPaths(data, const ['type']) ?? 'text',
      text: readStringByPaths(data, const ['text', 'message', 'body']) ?? '',
      orderId: readStringByPaths(data, const ['orderId']) ?? '',
      orderReference: readStringByPaths(
            data,
            const ['orderReference', 'referenceNumber', 'reference_number'],
          ) ??
          '',
      senderUid: readStringByPaths(data, const ['senderUid', 'authorUid']) ?? '',
      senderRole:
          (readStringByPaths(data, const ['senderRole', 'role']) ??
                  pharmacistRole)
              .toLowerCase(),
      senderName:
          readStringByPaths(
            data,
            const ['senderName', 'authorName', 'displayName'],
          ) ??
          '',
      recipientRole:
          readStringByPaths(data, const ['recipientRole'])?.toLowerCase(),
      createdAt: readDateTimeByPaths(data, const ['createdAt', 'timestamp']),
      hasPendingWrites: doc.metadata.hasPendingWrites,
    );
  }

  final String messageId;
  final String type;
  final String text;
  final String orderId;
  final String orderReference;
  final String senderUid;
  final String senderRole;
  final String senderName;
  final String? recipientRole;
  final DateTime? createdAt;
  final bool hasPendingWrites;

  bool get isSystem => senderRole == systemRole;

  bool isFromCustomer(String currentUserUid) =>
      senderRole == customerRole || senderUid == currentUserUid;

  String get timestampLabel =>
      formatChatTimestamp(createdAt, isPending: hasPendingWrites);
}
