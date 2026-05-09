import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pharmacy_marketplace_app/features/order_chat/models/order_summary.dart';
import 'package:pharmacy_marketplace_app/features/order_chat/repositories/order_chat_repository.dart';
import 'package:pharmacy_marketplace_app/features/order_chat/widgets/order_chat_header.dart';
import 'package:pharmacy_marketplace_app/features/order_chat/widgets/order_chat_placeholder.dart';
import 'package:pharmacy_marketplace_app/features/order_chat/widgets/order_message_composer.dart';
import 'package:pharmacy_marketplace_app/features/order_chat/widgets/order_messages_pane.dart';
import 'package:pharmacy_marketplace_app/features/order_chat/widgets/order_threads_sidebar.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final OrderChatRepository _repository = OrderChatRepository();
  final TextEditingController _composerController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _messageScrollController = ScrollController();
  final Map<String, int> _messageCountsByOrder = <String, int>{};

  String? _selectedOrderId;
  String _searchText = '';
  bool _isSending = false;

  @override
  void dispose() {
    _composerController.dispose();
    _searchController.dispose();
    _messageScrollController.dispose();
    super.dispose();
  }

  void _selectOrder(String orderId) {
    if (orderId == _selectedOrderId) {
      return;
    }

    setState(() => _selectedOrderId = orderId);
    _scrollMessagesToBottom(animated: false);
  }

  void _syncSelectedOrder(List<OrderSummary> orders) {
    final nextSelectedId = orders.isEmpty
        ? null
        : orders.any((order) => order.orderId == _selectedOrderId)
        ? _selectedOrderId
        : orders.first.orderId;

    if (nextSelectedId == _selectedOrderId) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || nextSelectedId == _selectedOrderId) {
        return;
      }

      setState(() => _selectedOrderId = nextSelectedId);
      _scrollMessagesToBottom(animated: false);
    });
  }

  void _syncMessageViewport(String orderId, int messageCount) {
    final previousCount = _messageCountsByOrder[orderId];
    if (previousCount == messageCount) {
      return;
    }

    _messageCountsByOrder[orderId] = messageCount;
    _scrollMessagesToBottom(animated: previousCount != null);
  }

  Future<void> _sendMessage(OrderSummary order) async {
    final text = _composerController.text.trim();
    if (text.isEmpty || _isSending) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSending = true);

    try {
      await _repository.sendCustomerMessage(order: order, text: text);
      _composerController.clear();
      _scrollMessagesToBottom();
    } on StateError catch (error) {
      _showMessage(error.message);
    } on FirebaseException catch (error) {
      _showMessage(
        error.message ?? 'Unable to send your message to the pharmacist.',
      );
    } catch (_) {
      _showMessage('Unable to send your message right now.');
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _showPrescriptionInfo(OrderSummary order) {
    final message = order.requiresPrescription
        ? 'This order requires a prescription. Upload and approval still need to be handled by the POS workflow for order ${order.orderReference}.'
        : 'Prescription upload is not connected for this order yet.';
    _showMessage(message);
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _scrollMessagesToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_messageScrollController.hasClients) {
        return;
      }

      final target = _messageScrollController.position.maxScrollExtent;
      if (animated) {
        _messageScrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
        return;
      }

      _messageScrollController.jumpTo(target);
    });
  }

  int _messageCountFor(String orderId) => _messageCountsByOrder[orderId] ?? 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ColoredBox(
        color: const Color(0xFFF1F4F8),
        child: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          initialData: FirebaseAuth.instance.currentUser,
          builder: (context, authSnapshot) {
            final currentUser = authSnapshot.data;
            if (currentUser == null) {
              return const OrderChatPlaceholder(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Sign in to chat with your pharmacist',
                message:
                    'Your order-linked conversations appear here after checkout.',
              );
            }

            return StreamBuilder<List<OrderSummary>>(
              stream: _repository.streamCustomerOrders(
                customerUid: currentUser.uid,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const OrderChatPlaceholder(
                    icon: Icons.error_outline_rounded,
                    title: 'Unable to load pharmacist chats',
                    message:
                        'Check your Firestore order documents and confirm this customer can read them.',
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final orders = snapshot.data ?? const <OrderSummary>[];
                if (orders.isEmpty) {
                  return const OrderChatPlaceholder(
                    icon: Icons.local_shipping_outlined,
                    title: 'No pharmacist chats yet',
                    message:
                        'Once the POS publishes an order for this customer, the linked order conversation appears here automatically.',
                  );
                }

                _syncSelectedOrder(orders);

                final selectedOrder = orders.firstWhere(
                  (order) => order.orderId == _selectedOrderId,
                  orElse: () => orders.first,
                );

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isWideLayout = constraints.maxWidth >= 980;
                    return isWideLayout
                        ? _buildWideLayout(
                            currentUserUid: currentUser.uid,
                            orders: orders,
                            selectedOrder: selectedOrder,
                          )
                        : _buildCompactLayout(
                            currentUserUid: currentUser.uid,
                            orders: orders,
                            selectedOrder: selectedOrder,
                          );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildWideLayout({
    required String currentUserUid,
    required List<OrderSummary> orders,
    required OrderSummary selectedOrder,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFCFCFE),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF101828).withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Row(
            children: [
              SizedBox(
                width: 360,
                child: OrderThreadsSidebar(
                  orders: orders,
                  selectedOrderId: _selectedOrderId,
                  searchController: _searchController,
                  searchText: _searchText,
                  onOrderSelected: _selectOrder,
                  onSearchChanged: (value) =>
                      setState(() => _searchText = value),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    OrderChatHeader(
                      order: selectedOrder,
                      messageCount: _messageCountFor(selectedOrder.orderId),
                      isWideLayout: true,
                    ),
                    Expanded(
                      child: OrderMessagesPane(
                        repository: _repository,
                        order: selectedOrder,
                        currentUserUid: currentUserUid,
                        scrollController: _messageScrollController,
                        onMessageCountChanged: _syncMessageViewport,
                      ),
                    ),
                    OrderMessageComposer(
                      controller: _composerController,
                      enabled: !_isSending,
                      isSending: _isSending,
                      isWideLayout: true,
                      onChanged: (_) => setState(() {}),
                      onPrescriptionInfo: () =>
                          _showPrescriptionInfo(selectedOrder),
                      onSend: () => _sendMessage(selectedOrder),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactLayout({
    required String currentUserUid,
    required List<OrderSummary> orders,
    required OrderSummary selectedOrder,
  }) {
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFCFCFE),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF101828).withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              OrderChatHeader(
                order: selectedOrder,
                messageCount: _messageCountFor(selectedOrder.orderId),
              ),
              const SizedBox(height: 12),
              OrderThreadStrip(
                orders: orders,
                selectedOrderId: _selectedOrderId,
                onOrderSelected: _selectOrder,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        Expanded(
          child: OrderMessagesPane(
            repository: _repository,
            order: selectedOrder,
            currentUserUid: currentUserUid,
            scrollController: _messageScrollController,
            onMessageCountChanged: _syncMessageViewport,
          ),
        ),
        OrderMessageComposer(
          controller: _composerController,
          enabled: !_isSending,
          isSending: _isSending,
          onChanged: (_) => setState(() {}),
          onPrescriptionInfo: () => _showPrescriptionInfo(selectedOrder),
          onSend: () => _sendMessage(selectedOrder),
        ),
      ],
    );
  }
}
