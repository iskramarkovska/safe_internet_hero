import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showForm = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.errorMessage ?? 'Login failed'),
        backgroundColor: AppColors.wrong,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? size.width * 0.25 : 32,
              vertical: 24,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                // Logo
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8524A),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE8524A).withOpacity(0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.bolt_rounded,
                      color: Colors.white, size: 60),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Safe Internet Hero',
                  style: TextStyle(
                    color: Color(0xFF2BBFAA),
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 48),

                if (!_showForm) ...[
                  // Sign in with email button
                  _QuizUpButton(
                    label: 'Sign in with email',
                    icon: Icons.email_outlined,
                    color: const Color(0xFFE8524A),
                    onTap: () => setState(() => _showForm = true),
                  ),
                  const SizedBox(height: 14),
                  const Divider(thickness: 1, color: Color(0xFFCCE8E4)),
                  const SizedBox(height: 14),
                  // Continue as guest
                  _QuizUpButton(
                    label: 'Continue as Guest',
                    icon: Icons.person_outline_rounded,
                    color: const Color(0xFF2BBFAA),
                    onTap: () => context.read<AuthProvider>().continueAsGuest(),
                  ),
                ] else ...[
                  // Email form
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined,
                          color: Color(0xFF2BBFAA)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outlined,
                          color: Color(0xFF2BBFAA)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textLight,
                        ),
                        onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _QuizUpButton(
                    label: auth.isLoading ? 'Signing in...' : 'Log In',
                    icon: Icons.login_rounded,
                    color: const Color(0xFFE8524A),
                    onTap: auth.isLoading ? null : _login,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => setState(() => _showForm = false),
                    child: const Text('← Back',
                        style: TextStyle(color: Color(0xFF2BBFAA))),
                  ),
                ],

                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen())),
                  child: const Text(
                    "Don't have an account? Register",
                    style: TextStyle(color: Color(0xFF2BBFAA)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuizUpButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _QuizUpButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}