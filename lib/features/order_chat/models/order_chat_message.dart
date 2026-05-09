import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/order_chat_firestore_reader.dart';

class OrderChatMessage {
  const OrderChatMessage({
    required this.messageId,
    required this.text,
    required this.senderId,
    required this.senderRole,
    required this.senderName,
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
      text: readStringByPaths(data, const ['text', 'message', 'body']) ?? '',
      senderId: readStringByPaths(
            data,
            const ['senderId', 'senderUid', 'authorUid'],
          ) ??
          '',
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
      createdAt: readDateTimeByPaths(data, const ['createdAt', 'timestamp']),
      hasPendingWrites: doc.metadata.hasPendingWrites,
    );
  }

  final String messageId;
  final String text;
  final String senderId;
  final String senderRole;
  final String senderName;
  final DateTime? createdAt;
  final bool hasPendingWrites;

  bool get isSystem => senderRole == systemRole;

  bool isFromCustomer(String currentUserUid) =>
      senderRole == customerRole || senderId == currentUserUid;

  String get timestampLabel =>
      formatChatTimestamp(createdAt, isPending: hasPendingWrites);
}
