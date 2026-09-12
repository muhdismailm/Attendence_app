import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

class PinInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscurePin;
  final VoidCallback? onToggleObscure;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;

  const PinInputField({
    super.key,
    required this.controller,
    this.label = '4-Digit Password / PIN',
    this.obscurePin = true,
    this.onToggleObscure,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            if (onToggleObscure != null)
              GestureDetector(
                onTap: onToggleObscure,
                child: Text(
                  obscurePin ? 'Show PIN' : 'Hide PIN',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscurePin,
          keyboardType: TextInputType.number,
          maxLength: 4,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          style: const TextStyle(
            fontSize: 20,
            letterSpacing: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            counterText: '',
            hintText: '••••',
            hintStyle: const TextStyle(
              letterSpacing: 12,
              fontSize: 20,
              color: AppColors.textMuted,
            ),
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.textSecondary),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.borderLight, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.8),
            ),
          ),
        ),
      ],
    );
  }
}
