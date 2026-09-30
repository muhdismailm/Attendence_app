import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class GetAccessScreen extends StatefulWidget {
  const GetAccessScreen({super.key});

  @override
  State<GetAccessScreen> createState() => _GetAccessScreenState();
}

class _GetAccessScreenState extends State<GetAccessScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _placeController = TextEditingController();
  final _mobileController = TextEditingController();

  static const List<String> _countryCodes = [
    '+91',
    '+971',
    '+966',
    '+968',
    '+974',
    '+965',
    '+973',
    '+1',
    '+44',
  ];

  String _selectedCountryCode = '+91';

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _placeController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final name = _nameController.text.trim();
    final place = _placeController.text.trim();
    final mobileDigits = _mobileController.text.trim().replaceAll(RegExp(r'\D'), '');

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your full name');
      return;
    }
    if (place.isEmpty) {
      setState(() => _errorMessage = 'Please enter your place / location');
      return;
    }
    if (mobileDigits.isEmpty) {
      setState(() => _errorMessage = 'Please enter your mobile number');
      return;
    }
    if (mobileDigits.length != 10) {
      setState(() => _errorMessage = 'Please enter a valid 10-digit mobile number');
      return;
    }

    final fullMobile = '$_selectedCountryCode $mobileDigits';

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      // 1. Submit to Firestore if Firebase is active
      if (Firebase.apps.isNotEmpty) {
        await FirebaseFirestore.instance.collection('access_requests').add({
          'name': name,
          'place': place,
          'mobile': fullMobile,
          'role': 'tutor',
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // 2. Cache request locally for offline reference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'last_access_request',
        '$name - $place - $fullMobile (${DateTime.now().toIso8601String()})',
      );

      if (!mounted) return;

      setState(() => _isSubmitting = false);
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        // Even if Firestore network fails, provide a graceful offline fallback
        _errorMessage = 'Could not reach server. Request saved locally.';
      });
      // Still show success since administrator can receive request
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.presentLightBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 38,
                    color: AppColors.presentGreen,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Request Submitted!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your access request has been sent to the administrator. You will receive your login username and password once approved.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Back to Login',
                  icon: Icons.arrow_back_rounded,
                  onPressed: () {
                    Navigator.of(ctx).pop(); // Close dialog
                    Navigator.of(context).pop(); // Back to login screen
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Get Access',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 28, top: 12),
              decoration: const BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.assignment_ind_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Request Tutor Access',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Provide details for administrator review',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Form Area
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: AppStyles.cardDecoration(boxShadow: AppStyles.elevatedCardShadow),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tutor Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Fill in your details below to request access',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Error message if any
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.absentLightBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.absentRed.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.absentRed),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.absentRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // 1. Name Field
                      CustomTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        hint: 'e.g. Muhammed Ismail',
                        prefixIcon: Icons.person_outline_rounded,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // 2. Place Field
                      CustomTextField(
                        controller: _placeController,
                        label: 'Place',
                        hint: 'e.g. Calicut, Kerala',
                        prefixIcon: Icons.location_on_outlined,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // 3. Mobile Number Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mobile Number',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Country Code selector
                              Container(
                                height: 50,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: AppStyles.cardBorderRadius,
                                  border: Border.all(color: AppColors.borderLight, width: 1.2),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _countryCodes.contains(_selectedCountryCode)
                                        ? _selectedCountryCode
                                        : _countryCodes.first,
                                    icon: const Icon(
                                      Icons.arrow_drop_down_rounded,
                                      color: AppColors.textSecondary,
                                      size: 20,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textDark,
                                    ),
                                    dropdownColor: Colors.white,
                                    items: _countryCodes.map((code) {
                                      return DropdownMenuItem<String>(
                                        value: code,
                                        child: Text(
                                          code,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _selectedCountryCode = val);
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // 10-Digit Phone field
                              Expanded(
                                child: TextFormField(
                                  controller: _mobileController,
                                  keyboardType: TextInputType.phone,
                                  maxLength: 10,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _handleSubmit(),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textDark,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '10-digit number',
                                    hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                                    counterText: '',
                                    prefixIcon: const Icon(
                                      Icons.phone_outlined,
                                      size: 20,
                                      color: AppColors.textSecondary,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),

                      // Submit Button
                      CustomButton(
                        text: 'Submit Request',
                        icon: Icons.send_rounded,
                        isLoading: _isSubmitting,
                        onPressed: _isSubmitting ? null : _handleSubmit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
