import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/pin_input_field.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _pinController = TextEditingController();
  bool _obscurePin = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      username: _usernameController.text,
      pin: _pinController.text,
    );

    if (!mounted) return;

    if (!success && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AppColors.absentRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _fillQuickDemo(String username, String pin) {
    _usernameController.text = username;
    _pinController.text = pin;
    _handleLogin();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Blue Header Area
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 32,
                bottom: 36,
                left: 24,
                right: 24,
              ),
              decoration: AppStyles.headerGradientDecoration,
              child: Column(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.how_to_reg_rounded,
                      size: 38,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Attendance',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Manage student attendance easily',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            // Form Content Area
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card Container for Form
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: AppStyles.cardDecoration(boxShadow: AppStyles.elevatedCardShadow),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Enter your username and 4-digit PIN',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Username field
                        CustomTextField(
                          controller: _usernameController,
                          label: 'Username',
                          hint: 'e.g. tutor or parent_rahul',
                          prefixIcon: Icons.person_outline_rounded,
                          keyboardType: TextInputType.text,
                        ),
                        const SizedBox(height: 16),

                        // 4-Digit PIN field
                        PinInputField(
                          controller: _pinController,
                          label: '4-Digit PIN / Password',
                          obscurePin: _obscurePin,
                          onToggleObscure: () {
                            setState(() {
                              _obscurePin = !_obscurePin;
                            });
                          },
                          onSubmitted: (_) => _handleLogin(),
                        ),
                        const SizedBox(height: 24),

                        // Login Button
                        CustomButton(
                          text: 'Sign In',
                          isLoading: auth.isLoading,
                          icon: Icons.login_rounded,
                          onPressed: _handleLogin,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Register Link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            );
                          },
                          child: const Text(
                            'Register Now',
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Quick Demo Logins Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.6),
                      borderRadius: AppStyles.cardBorderRadius,
                      border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.touch_app_rounded, size: 16, color: AppColors.primaryBlue),
                            SizedBox(width: 6),
                            Text(
                              'Quick Demo Accounts (1-Tap Test)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ActionChip(
                              avatar: const Icon(Icons.school_rounded, size: 16, color: AppColors.primaryBlue),
                              label: const Text('Tutor', style: TextStyle(fontSize: 12)),
                              backgroundColor: Colors.white,
                              onPressed: () => _fillQuickDemo('tutor', '1234'),
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.family_restroom_rounded, size: 16, color: AppColors.primaryBlue),
                              label: const Text("Parent (Ismail)", style: TextStyle(fontSize: 12)),
                              backgroundColor: Colors.white,
                              onPressed: () => _fillQuickDemo('parent_ismail', '1234'),
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.family_restroom_rounded, size: 16, color: AppColors.primaryBlue),
                              label: const Text("Parent (Ihsan)", style: TextStyle(fontSize: 12)),
                              backgroundColor: Colors.white,
                              onPressed: () => _fillQuickDemo('parent_ihsan', '1234'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
