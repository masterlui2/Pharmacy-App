import 'package:flutter/material.dart';
import 'package:pharmacy_marketplace_app/core/constants/app_colors.dart';

class OrderMessageComposer extends StatelessWidget {
  const OrderMessageComposer({
    super.key,
    required this.controller,
    required this.enabled,
    required this.isSending,
    required this.onChanged,
    required this.onPrescriptionInfo,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool isSending;
  final ValueChanged<String> onChanged;
  final VoidCallback onPrescriptionInfo;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.trim().isNotEmpty;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFECEEF3))),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              tooltip: 'Prescription details',
              visualDensity: VisualDensity.compact,
              onPressed: onPrescriptionInfo,
              icon: const Icon(Icons.description_outlined),
              color: AppColors.primary,
            ),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F2F6),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.send,
                  onChanged: onChanged,
                  onSubmitted: (_) => onSend(),
                  decoration: const InputDecoration(
                    hintText: 'Message your pharmacist',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Send',
              visualDensity: VisualDensity.compact,
              onPressed: enabled && hasText ? onSend : null,
              icon: isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
