import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/auth_provider.dart';
import '../theme/app_colors.dart';

class PinConfirmationDialog extends StatefulWidget {
  final String title;
  final String message;
  final String confirmButtonText;
  final Color confirmButtonColor;
  final bool isDestructive;

  const PinConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmButtonText = 'Confirm',
    this.confirmButtonColor = AppColors.primaryBlue,
    this.isDestructive = false,
  });

  /// Static helper to quickly show the PIN confirmation dialog and get boolean result
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmButtonText = 'Confirm',
    Color confirmButtonColor = AppColors.primaryBlue,
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PinConfirmationDialog(
        title: title,
        message: message,
        confirmButtonText: confirmButtonText,
        confirmButtonColor: confirmButtonColor,
        isDestructive: isDestructive,
      ),
    );
    return result ?? false;
  }

  @override
  State<PinConfirmationDialog> createState() => _PinConfirmationDialogState();
}

class _PinConfirmationDialogState extends State<PinConfirmationDialog> {
  final TextEditingController _pinController = TextEditingController();
  bool _obscurePin = true;
  String? _errorMessage;
  bool _isVerifying = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    final enteredPin = _pinController.text.trim();
    if (enteredPin.isEmpty) {
      setState(() => _errorMessage = 'Please enter your 4-digit PIN');
      return;
    }

    if (enteredPin.length != 4) {
      setState(() => _errorMessage = 'PIN must be exactly 4 digits');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();
    final isValid = auth.verifyPin(enteredPin);

    if (!isValid) {
      setState(() {
        _isVerifying = false;
        _errorMessage = 'Incorrect PIN. Action denied for security.';
      });
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 16,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Icon & Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.isDestructive
                        ? AppColors.absentRed.withValues(alpha: 0.12)
                        : AppColors.primaryBlue.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.isDestructive ? Icons.warning_amber_rounded : Icons.lock_outline_rounded,
                    color: widget.isDestructive ? AppColors.absentRed : AppColors.primaryBlue,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Security PIN Required',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Message Body
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.isDestructive
                    ? AppColors.absentRed.withValues(alpha: 0.06)
                    : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.isDestructive
                      ? AppColors.absentRed.withValues(alpha: 0.2)
                      : AppColors.borderLight,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    widget.isDestructive ? Icons.info_rounded : Icons.shield_outlined,
                    size: 18,
                    color: widget.isDestructive ? AppColors.absentRed : AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: widget.isDestructive ? AppColors.absentRed : AppColors.textDark,
                        fontWeight: widget.isDestructive ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 4-Digit PIN Input Field
            const Text(
              'Enter your 4-digit login PIN',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: _obscurePin,
              autofocus: true,
              style: const TextStyle(
                fontSize: 20,
                letterSpacing: 8,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: '••••',
                hintStyle: const TextStyle(
                  letterSpacing: 8,
                  fontSize: 18,
                  color: AppColors.textMuted,
                ),
                filled: true,
                fillColor: AppColors.surfaceMuted,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                prefixIcon: const Icon(Icons.pin_rounded, size: 20, color: AppColors.textSecondary),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePin ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => setState(() => _obscurePin = !_obscurePin),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: widget.isDestructive ? AppColors.absentRed : AppColors.primaryBlue,
                    width: 1.8,
                  ),
                ),
              ),
              onSubmitted: (_) => _handleConfirm(),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 14, color: AppColors.absentRed),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.absentRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 22),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: AppColors.borderLight),
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Center(
                      child: Text(
                        'Cancel',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.confirmButtonColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: _isVerifying ? null : _handleConfirm,
                    child: _isVerifying
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Center(
                            child: Text(
                              widget.confirmButtonText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
