import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isFullWidth;
  final bool isOutlined;
  final double height;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.isFullWidth = true,
    this.isOutlined = false,
    this.height = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? AppColors.primaryBlue;
    final effectiveTextColor = textColor ?? (isOutlined ? AppColors.primaryBlue : Colors.white);

    Widget child = isLoading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(effectiveTextColor),
            ),
          )
        : Row(
            mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: effectiveTextColor),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: TextStyle(
                  color: effectiveTextColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          );

    final buttonWidget = isOutlined
        ? OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              minimumSize: Size(isFullWidth ? double.infinity : 0, height),
              side: BorderSide(color: effectiveBg, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: AppStyles.buttonBorderRadius),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: child,
          )
        : Container(
            decoration: BoxDecoration(
              borderRadius: AppStyles.buttonBorderRadius,
              boxShadow: onPressed != null && !isLoading ? AppStyles.primaryButtonShadow : null,
            ),
            child: ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(isFullWidth ? double.infinity : 0, height),
                backgroundColor: effectiveBg,
                foregroundColor: effectiveTextColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: AppStyles.buttonBorderRadius),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: child,
            ),
          );

    return isFullWidth ? SizedBox(width: double.infinity, child: buttonWidget) : buttonWidget;
  }
}
