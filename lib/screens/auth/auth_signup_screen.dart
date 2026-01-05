import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/signup_controller.dart';

class AuthSignupScreen extends StatefulWidget {
  const AuthSignupScreen({super.key});

  @override
  State<AuthSignupScreen> createState() => _AuthSignupScreenState();
}

class _AuthSignupScreenState extends State<AuthSignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final SignUpController controller = Get.find<SignUpController>();

  bool _obscurePassword = true;

  // 🔐 GUARANTEED strong password generator
  String _generatePassword() {
    const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lower = 'abcdefghijklmnopqrstuvwxyz';
    const digits = '0123456789';
    const special = '!@#\$%^&*';
    const all = upper + lower + digits + special;

    final rand = Random.secure();

    // Ensure required characters
    final chars = <String>[
      upper[rand.nextInt(upper.length)],
      lower[rand.nextInt(lower.length)],
      digits[rand.nextInt(digits.length)],
      special[rand.nextInt(special.length)],
    ];

    // Fill remaining length (total 12 chars)
    for (int i = 0; i < 8; i++) {
      chars.add(all[rand.nextInt(all.length)]);
    }

    // Shuffle to avoid predictable order
    chars.shuffle(rand);

    return chars.join();
  }

  @override
  Widget build(BuildContext context) {
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: FractionallySizedBox(
                widthFactor: 0.88,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(36),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(22, 24, 22, 26),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(36),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 30,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildHero(),
                            const SizedBox(height: 22),
                            _buildForm(),
                            const SizedBox(height: 20),
                            _buildFooter(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 Hero header
  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF3AA8F7),
            Color(0xFF47D6C4),
          ],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Account',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Join CampusApp and manage campus life smarter.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Full Name
          TextFormField(
            controller: controller.fullName,
            decoration: _inputDecoration(
              label: 'Full Name',
              icon: Icons.person_rounded,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Full name is required';
              }
              if (value.trim().length < 3) {
                return 'Name must be at least 3 characters';
              }
              if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value.trim())) {
                return 'Only letters and spaces allowed';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Email
          TextFormField(
            controller: controller.email,
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDecoration(
              label: 'Email',
              icon: Icons.alternate_email_rounded,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email is required';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Password
          TextFormField(
            controller: controller.password,
            obscureText: _obscurePassword,
            decoration: _inputDecoration(
              label: 'Password',
              icon: Icons.lock_rounded,
            ).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  size: 20,
                  color: const Color(0xFF7A8A9C),
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              if (value.length < 8) {
                return 'Minimum 8 characters required';
              }
              if (!RegExp(r'[A-Z]').hasMatch(value)) {
                return 'Add at least one uppercase letter';
              }
              if (!RegExp(r'[a-z]').hasMatch(value)) {
                return 'Add at least one lowercase letter';
              }
              if (!RegExp(r'\d').hasMatch(value)) {
                return 'Add at least one number';
              }
              if (!RegExp(r'[!@#\$%^&*]').hasMatch(value)) {
                return 'Add at least one special character';
              }
              return null;
            },
          ),

          const SizedBox(height: 8),

          // Suggest password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                controller.password.text = _generatePassword();
                setState(() => _obscurePassword = true);
                Get.snackbar(
                  'Password suggested',
                  'This password meets all security requirements.',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              child: const Text(
                'Suggest strong password',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Obx(
            () => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  elevation: 0,
                  backgroundColor: const Color(0xFF3AA8F7),
                  foregroundColor: Colors.white,
                ),
                onPressed: controller.isLoading.value
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          controller.signUp();
                        }
                      },
                child: controller.isLoading.value
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 15,
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

  Widget _buildFooter() {
    return Column(
      children: [
        const Divider(height: 28, thickness: 0.7),
        TextButton(
          onPressed: () {
            Get.offAllNamed('/login');
          },
          child: const Text(
            'Already have an account? Sign in',
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

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF7A8A9C)),
      labelStyle: const TextStyle(
        fontSize: 13,
        color: Color(0xFF7A8A9C),
      ),
      filled: true,
      fillColor: const Color(0xFFF4F7FB),
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
    );
  }
}