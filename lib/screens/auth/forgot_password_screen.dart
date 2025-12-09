import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _useEmail = true;
  String _contact = '';

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
              // Back button (top-left)
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
                            _buildMethodToggle(theme),
                            const SizedBox(height: 12),
                            _buildForm(theme),
                            const SizedBox(height: 18),
                            _buildFooter(context, theme),
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
                Icons.lock_reset_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Reset password',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Forgot your password?',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose how you want to receive your OTP.',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            color: const Color(0xFF7A8A9C),
          ),
        ),
      ],
    );
  }

  Widget _buildMethodToggle(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            selected: _useEmail,
            onSelected: (selected) {
              if (!selected) return;
              setState(() {
                _useEmail = true;
                _contact = '';
              });
            },
            label: const Text('Email'),
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _useEmail ? Colors.white : const Color(0xFF4C5D73),
            ),
            selectedColor: const Color(0xFF3AA8F7),
            backgroundColor: const Color(0xFFF4F7FB),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ChoiceChip(
            selected: !_useEmail,
            onSelected: (selected) {
              if (!selected) return;
              setState(() {
                _useEmail = false;
                _contact = '';
              });
            },
            label: const Text('Phone number'),
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: !_useEmail ? Colors.white : const Color(0xFF4C5D73),
            ),
            selectedColor: const Color(0xFF47D6C4),
            backgroundColor: const Color(0xFFF4F7FB),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const SizedBox(height: 10),
          TextFormField(
            decoration: _inputDecoration(
              label: _useEmail ? 'Registered email' : 'Registered phone number',
              icon: _useEmail ? Icons.email_rounded : Icons.phone_rounded,
            ),
            keyboardType:
                _useEmail ? TextInputType.emailAddress : TextInputType.phone,
            onChanged: (value) => _contact = value.trim(),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
                backgroundColor: const Color(0xFF3AA8F7),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                // Later: validate + trigger backend
                Navigator.pushNamed(context, '/otp');
              },
              child: const Text(
                'Send OTP',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        const Divider(height: 24, thickness: 0.7),
        const SizedBox(height: 4),
        Text(
          'Remembered your password?',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 12,
            color: const Color(0xFF7A8A9C),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/login');
          },
          child: const Text(
            'Back to sign in',
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
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    );
  }
}