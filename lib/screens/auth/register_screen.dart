import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_widgets.dart';
import 'login_screen.dart';
import 'splash_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _obscurePassword = true;
  AgeGroup? _selectedAgeGroup;
  int _step = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_selectedAgeGroup == null) {
      _snack('Please select your age group');
      return;
    }
    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      username: _usernameController.text.trim(),
      ageGroup: _selectedAgeGroup!,
    );
    if (!mounted) return;
    if (success) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const PostLoginSplash()));
    } else {
      _snack(auth.errorMessage ?? 'Registration failed');
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppColors.red,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _nextStep() {
    if (_usernameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _snack('Please fill in all fields');
      return;
    }
    setState(() => _step = 1);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final headerTitle =
        _step == 0 ? 'Create account' : 'How old are you?';
    final headerSub = _step == 0
        ? 'Join thousands of internet heroes'
        : 'Pick your age group to get started';

    return Scaffold(
      backgroundColor: AppColors.blue,
      body: Column(
        children: [
          // ── Blue header ────────────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_rounded,
                            color: Colors.white, size: 22),
                        onPressed: () {
                          if (_step == 1) {
                            setState(() => _step = 0);
                          } else {
                            Navigator.pop(context);
                          }
                        },
                      ),
                      const Spacer(),
                      // Step indicator
                      Row(
                        children: List.generate(2, (i) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: i == _step ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _step
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            headerTitle,
                            key: ValueKey(headerTitle),
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          headerSub,
                          style: GoogleFonts.nunito(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── White form body ────────────────────────────────────────────────
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(36)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _step == 0
                      ? _buildStep1(auth)
                      : _buildStep2(auth),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1(AuthProvider auth) {
    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: _usernameController,
          hint: 'Username',
          icon: Icons.person_outline_rounded,
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),

        const SizedBox(height: 14),

        AppTextField(
          controller: _emailController,
          hint: 'Email address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        )
            .animate(delay: 80.ms)
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.1, end: 0),

        const SizedBox(height: 14),

        AppTextField(
          controller: _passwordController,
          hint: 'Password',
          icon: Icons.lock_outline_rounded,
          obscure: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppColors.textLight,
              size: 20,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        )
            .animate(delay: 160.ms)
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.1, end: 0),

        const SizedBox(height: 32),

        AppButton(
          label: 'CONTINUE',
          variant: AppButtonVariant.primary,
          icon: Icons.arrow_forward_rounded,
          onTap: _nextStep,
        )
            .animate(delay: 240.ms)
            .fadeIn(duration: 300.ms),

        const SizedBox(height: 28),

        Center(
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen())),
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.nunito(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                  children: [
                    const TextSpan(text: 'Already have an account? '),
                    TextSpan(
                      text: 'Log in',
                      style: GoogleFonts.nunito(
                        color: AppColors.blue,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2(AuthProvider auth) {
    final groups = [
      (
        age: AgeGroup.kids,
        icon: Icons.child_care_rounded,
        color: AppColors.green,
        bg: AppColors.greenLight,
      ),
      (
        age: AgeGroup.tweens,
        icon: Icons.sports_esports_rounded,
        color: AppColors.blue,
        bg: AppColors.blueLight,
      ),
      (
        age: AgeGroup.teens,
        icon: Icons.school_rounded,
        color: AppColors.categoryPrivacy,
        bg: const Color(0xFFEDE7FF),
      ),
    ];

    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...groups.asMap().entries.map((e) {
          final g = e.value;
          final isSelected = _selectedAgeGroup == g.age;

          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => setState(() => _selectedAgeGroup = g.age),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: isSelected ? g.color : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? g.color : AppColors.border,
                    width: isSelected ? 0 : 2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: g.color.withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.25)
                            : g.bg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        g.icon,
                        color: isSelected ? Colors.white : g.color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            g.age.label,
                            style: GoogleFonts.nunito(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 24),
                  ],
                ),
              ),
            ),
          )
              .animate(delay: Duration(milliseconds: e.key * 80))
              .fadeIn(duration: const Duration(milliseconds: 300))
              .slideX(begin: 0.05, end: 0);
        }),

        const SizedBox(height: 24),

        AppButton(
          label: auth.isLoading ? 'Creating…' : 'CREATE ACCOUNT',
          variant: AppButtonVariant.success,
          icon: Icons.check_rounded,
          onTap: auth.isLoading ? null : _register,
        ).animate(delay: 300.ms).fadeIn(duration: 300.ms),
      ],
    );
  }
}
