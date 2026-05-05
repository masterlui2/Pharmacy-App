import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/order_chat_message.dart';
import '../models/order_summary.dart';
import '../utils/order_chat_firestore_reader.dart';

class OrderChatRepository {
  OrderChatRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');

  Stream<List<OrderSummary>> streamCustomerOrders({String? customerUid}) {
    final resolvedCustomerUid = customerUid?.trim().isNotEmpty == true
        ? customerUid!.trim()
        : _auth.currentUser?.uid;

    if (resolvedCustomerUid == null || resolvedCustomerUid.isEmpty) {
      return Stream.value(const <OrderSummary>[]);
    }

    return _orders
        .where('customerUid', isEqualTo: resolvedCustomerUid)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map(OrderSummary.fromDocument)
              .toList(growable: false);
          orders.sort((a, b) => b.sortDate.compareTo(a.sortDate));
          return orders;
        });
  }

  Stream<List<OrderChatMessage>> streamMessages(String orderId) {
    return _orders
        .doc(orderId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(OrderChatMessage.fromDocument)
              .toList(growable: false);
        });
  }

  Future<void> sendCustomerMessage({
    required OrderSummary order,
    required String text,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Please sign in to message the pharmacist.');
    }

    final normalizedText = text.trim();
    if (normalizedText.isEmpty) {
      return;
    }

    final senderName = await _resolveCustomerDisplayName(user);
    final orderReference = order.orderReference.trim().isEmpty
        ? order.orderId
        : order.orderReference.trim();
    final orderDoc = _orders.doc(order.orderId);

    await orderDoc.collection('messages').add({
      'type': 'text',
      'text': normalizedText,
      'orderId': order.orderId,
      'orderReference': orderReference,
      'senderUid': user.uid,
      'senderRole': OrderChatMessage.customerRole,
      'senderName': senderName,
      'recipientRole': OrderChatMessage.pharmacistRole,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await orderDoc.update({
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> _resolveCustomerDisplayName(User user) async {
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();
    if (userData != null) {
      final profileName = readStringByPaths(
        userData,
        const ['fullName', 'name', 'displayName'],
      );
      if (profileName != null) {
        return profileName;
      }
    }

    final email = user.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email;
    }

    return 'Customer';
  }
}
