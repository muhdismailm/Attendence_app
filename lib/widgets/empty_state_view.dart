import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_button.dart';

class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionButtonText;
  final VoidCallback? onActionPressed;

  const EmptyStateView({
    super.key,
    this.icon = Icons.inbox_rounded,
    required this.title,
    required this.message,
    this.actionButtonText,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionButtonText != null && onActionPressed != null) ...[
              const SizedBox(height: 20),
              CustomButton(
                text: actionButtonText!,
                onPressed: onActionPressed,
                isFullWidth: false,
                height: 44,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
