import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/otp_controller.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _formKey = GlobalKey<FormState>();

  // Bind GetX controller
  final OtpController otpController = Get.put(OtpController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE7F2FF),
              Color(0xFFD8F7F8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                left: 8,
                top: 8,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: FractionallySizedBox(
                    widthFactor: 0.85,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.98),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 26,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildHeader(theme),
                            const SizedBox(height: 20),
                            _buildForm(theme),
                            const SizedBox(height: 16),
                            _buildFooter(theme),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- HEADER ----------------

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 32,
              width: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF3AA8F7),
                    Color(0xFF47D6C4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.verified_user_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Verify OTP',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Enter the 6-digit code',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'We\'ve sent a verification code to your registered email / phone.',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            color: const Color(0xFF7A8A9C),
          ),
        ),
      ],
    );
  }

  // ---------------- FORM ----------------

  Widget _buildForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const SizedBox(height: 10),

          // OTP FIELD
          TextFormField(
            controller: otpController.otp,
            maxLength: 6,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'OTP',
              counterText: '',
              prefixIcon: const Icon(
                Icons.pin_rounded,
                size: 20,
                color: Color(0xFF7A8A9C),
              ),
              labelStyle: const TextStyle(
                fontSize: 13,
                color: Color(0xFF7A8A9C),
              ),
              filled: true,
              fillColor: const Color(0xFFF4F7FB),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              otpController.otp.text = value;
            },
          ),

          const SizedBox(height: 18),

          // VERIFY BUTTON
          Obx(
            () => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                  backgroundColor: const Color(0xFF47D6C4),
                  foregroundColor: Colors.white,
                ),
                onPressed: otpController.isLoading.value
                    ? null
                    : () async {
                        final otp = otpController.otp.text.trim();

                        final success =
                            await otpController.verifyOtp(otp);

                        if (success && mounted) {
                          Navigator.pushReplacementNamed(
                              context, '/home');
                        }
                      },
                child: otpController.isLoading.value
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Verify & Continue',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- FOOTER ----------------

  Widget _buildFooter(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Text(
          'Didn\'t receive the code?',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 12,
            color: const Color(0xFF7A8A9C),
          ),
        ),
        TextButton(
          onPressed: () {
            // TODO: trigger OTP resend in future
            Get.snackbar('Resent', 'A new OTP will be sent shortly.');
          },
          child: const Text(
            'Resend OTP',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2877E0),
            ),
          ),
        ),
      ],
    );
  }
}