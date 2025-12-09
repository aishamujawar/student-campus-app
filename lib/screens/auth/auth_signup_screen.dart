import 'package:flutter/material.dart';

class AuthSignupScreen extends StatefulWidget {
  const AuthSignupScreen({super.key});

  @override
  State<AuthSignupScreen> createState() => _AuthSignupScreenState();
}

class _AuthSignupScreenState extends State<AuthSignupScreen> {
  final _formKey = GlobalKey<FormState>();

  String _name = '';
  String _uid = '';
  String _email = '';
  String _phone = '';
  String _password = '';

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
          child: Center(
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
                        const SizedBox(height: 18),
                        _buildFooter(context, theme),
                      ],
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
                Icons.grid_view_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'CampusApp',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Create an account',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Set up your campus companion profile.',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            color: const Color(0xFF7A8A9C),
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
          const SizedBox(height: 8),
          TextFormField(
            decoration: _inputDecoration(
              label: 'Full name',
              icon: Icons.person_rounded,
            ),
            onChanged: (value) => _name = value.trim(),
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: _inputDecoration(
              label: 'UID',
              icon: Icons.badge_rounded,
            ),
            onChanged: (value) => _uid = value.trim(),
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: _inputDecoration(
              label: 'Email',
              icon: Icons.email_rounded,
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) => _email = value.trim(),
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: _inputDecoration(
              label: 'Phone number',
              icon: Icons.phone_rounded,
            ),
            keyboardType: TextInputType.phone,
            onChanged: (value) => _phone = value.trim(),
          ),
          const SizedBox(height: 12),
          TextFormField(
            obscureText: true,
            decoration: _inputDecoration(
              label: 'Password',
              icon: Icons.lock_rounded,
            ),
            onChanged: (value) => _password = value.trim(),
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
                backgroundColor: const Color(0xFF47D6C4),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                // In future: validate & send to backend
                Navigator.pushReplacementNamed(context, '/home');
              },
              child: const Text(
                'Create account',
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
          'Already have an account?',
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
            'Sign in',
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