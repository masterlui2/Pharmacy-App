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
    this.isWideLayout = false,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool isSending;
  final ValueChanged<String> onChanged;
  final VoidCallback onPrescriptionInfo;
  final VoidCallback onSend;
  final bool isWideLayout;

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.trim().isNotEmpty;
    final canSend = enabled && hasText;

    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE8ECF3))),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isWideLayout ? 24 : 16,
            16,
            isWideLayout ? 24 : 16,
            16,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _ActionButton(
                tooltip: 'Prescription details',
                onPressed: onPrescriptionInfo,
                icon: Icons.description_outlined,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  minLines: isWideLayout ? 3 : 1,
                  maxLines: isWideLayout ? 5 : 4,
                  textInputAction: TextInputAction.send,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: onChanged,
                  onSubmitted: (_) => onSend(),
                  decoration: InputDecoration(
                    hintText: isWideLayout
                        ? 'Type your reply about this order'
                        : 'Type a message',
                    hintStyle: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFD),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        isWideLayout ? 18 : 22,
                      ),
                      borderSide: const BorderSide(color: Color(0xFFE3E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        isWideLayout ? 18 : 22,
                      ),
                      borderSide: const BorderSide(color: Color(0xFFE3E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        isWideLayout ? 18 : 22,
                      ),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: isWideLayout ? 16 : 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              isWideLayout
                  ? FilledButton.icon(
                      onPressed: canSend ? onSend : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: const Color(0xFFDDE3EC),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: isSending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                      label: const Text('Send'),
                    )
                  : FilledButton(
                      onPressed: canSend ? onSend : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: const Color(0xFFDDE3EC),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(48, 48),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: isSending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8FB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE3E8F0)),
            ),
            child: Icon(icon, color: AppColors.primaryDark, size: 20),
          ),
        ),
      ),
    );
  }
}
