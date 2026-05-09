import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/order_chat_message.dart';
import '../models/order_summary.dart';

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
        .limitToLast(150)
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

    await _orders.doc(order.orderId).collection('messages').add({
      'senderId': user.uid,
      'senderRole': OrderChatMessage.customerRole,
      'text': normalizedText,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
