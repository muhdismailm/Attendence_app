import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final void Function(String)? onChanged;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 20, color: AppColors.textSecondary)
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppStyles.cardBorderRadius,
              borderSide: const BorderSide(color: AppColors.borderLight, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppStyles.cardBorderRadius,
              borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.8),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AppStyles.cardBorderRadius,
              borderSide: const BorderSide(color: AppColors.absentRed, width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: AppStyles.cardBorderRadius,
              borderSide: const BorderSide(color: AppColors.absentRed, width: 1.8),
            ),
          ),
        ),
      ],
    );
  }
}
