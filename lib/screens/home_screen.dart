import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import 'admin_screen.dart';
import 'topics_screen.dart';
import 'splash_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const red = Color(0xFFE8524A);
  static const teal = Color(0xFF2BBFAA);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isGuest = auth.isGuest;
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;
    final username = isGuest ? 'Guest' : (user?.username ?? 'Hero');
    final initial = username[0].toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _BackgroundPainter()),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 22),
                        onPressed: () => _confirmLogout(context),
                      ),
                      Row(
                        children: [
                          Text(username,
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(width: 10),
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            child: Center(
                              child: Text(initial,
                                  style: const TextStyle(color: teal, fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWide ? size.width * 0.3 : 48,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 130, height: 130,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 24, offset: const Offset(0, 8))],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Container(
                                decoration: const BoxDecoration(color: red, shape: BoxShape.circle),
                                child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 64),
                              ),
                            ),
                          ),
                          const SizedBox(height: 100),
                          const Text(
                            'Safe Internet Hero',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: teal, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 0.3),
                          ),
                          const SizedBox(height: 56),
                          _QuizUpActionButton(
                            label: 'PLAY',
                            color: const Color(0xFF1FA090),
                            textColor: Colors.white,
                            icon: Icons.send_rounded,
                            borderColor: const Color(0xFF168C7F),
                            shadowColor: const Color(0xFF168C7F),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TopicsScreen())),
                          ),
                          if (user?.isAdmin == true) ...[
                            const SizedBox(height: 18),
                            _QuizUpActionButton(
                              label: 'ADMIN PANEL',
                              color: const Color(0xFFE8C84A),
                              textColor: const Color(0xFF5A7A6A),
                              icon: Icons.admin_panel_settings_rounded,
                              borderColor: const Color(0xFFC8A830),
                              shadowColor: const Color(0xFFC8A830),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen())),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFFF0FEFA),
        elevation: 20,
        // ConstrainedBox fixes the stretched dialog on wide/web screens
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: teal.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: const Text(
                    'Sign out',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: teal, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Are you sure you want to sign out?',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: teal, fontSize: 16, height: 1.4),
                ),
                const SizedBox(height: 28),
                Builder(builder: (ctx) => Row(
                  children: [
                    Expanded(child: _DialogButton(label: 'BACK', onTap: () => Navigator.pop(ctx, false))),
                    const SizedBox(width: 12),
                    Expanded(child: _DialogButton(label: 'CONFIRM', onTap: () => Navigator.pop(ctx, true))),
                  ],
                )),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirm == true && context.mounted) {
      await context.read<AuthProvider>().logout();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthGate()),
              (route) => false,
        );
      }
    }
  }
}

class _DialogButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DialogButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFD97A), Color(0xFFE8C84A)],
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFC8A830), width: 2.5),
            boxShadow: [
              const BoxShadow(color: Color(0xFFC8A830), offset: Offset(0, 4), blurRadius: 0),
              BoxShadow(color: Colors.black.withOpacity(0.1), offset: const Offset(0, 6), blurRadius: 8),
            ],
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color(0xFF5A7A6A), fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1)),
        ),
      ),
    );
  }
}

class _QuizUpActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final IconData icon;
  final Color borderColor;
  final Color shadowColor;
  final VoidCallback onTap;

  const _QuizUpActionButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.icon,
    required this.borderColor,
    required this.shadowColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(32));

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: shadowColor.withOpacity(0.9), offset: const Offset(0, 5), blurRadius: 0),
            BoxShadow(color: Colors.black.withOpacity(0.12), offset: const Offset(0, 8), blurRadius: 12),
          ],
        ),
        child: Material(
          color: color,
          shape: shape,
          child: InkWell(
            onTap: onTap,
            customBorder: shape,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(left: 32, top: 14, bottom: 14, right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: borderColor, width: 2.5),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color.withOpacity(0.96), color],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: textColor, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.6)),
                  ),
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.45), width: 2),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: Icon(icon, color: textColor, size: 22),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const teal = Color(0xFF2BBFAA);
    const lightTeal = Color(0xFF4DD0C4);

    final headerPaint = Paint()..color = teal;
    final headerPath = Path();
    headerPath.moveTo(0, 0);
    headerPath.lineTo(size.width, 0);
    headerPath.lineTo(size.width, size.height * 0.42);
    headerPath.quadraticBezierTo(size.width * 0.5, size.height * 0.52, 0, size.height * 0.42);
    headerPath.close();
    canvas.drawPath(headerPath, headerPaint);

    final circlePaint = Paint()..color = Colors.white.withOpacity(0.07)..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.05), size.width * 0.28, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.08, size.height * 0.18), size.width * 0.18, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.38), size.width * 0.10, circlePaint);

    final ringPaint = Paint()..color = Colors.white.withOpacity(0.06)..style = PaintingStyle.stroke..strokeWidth = 18;
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.28), size.width * 0.22, ringPaint);
    canvas.drawCircle(Offset(size.width * 0.05, size.height * 0.08), size.width * 0.15, ringPaint);

    final dotPaint = Paint()..color = teal.withOpacity(0.15)..style = PaintingStyle.fill;
    final dotSpacingX = size.width / 10;
    final dotSpacingY = size.height / 16;
    final startY = size.height * 0.48;
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 11; col++) {
        final x = col * dotSpacingX + (row.isOdd ? dotSpacingX / 2 : 0);
        final y = startY + row * dotSpacingY;
        canvas.drawCircle(Offset(x, y), 3, dotPaint);
      }
    }

    final accentPaint = Paint()..color = lightTeal.withOpacity(0.2)..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.05, size.height * 0.85), size.width * 0.12, accentPaint);
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.75), size.width * 0.09, accentPaint);
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.92), size.width * 0.06, accentPaint);

    final ringPaint2 = Paint()..color = teal.withOpacity(0.12)..style = PaintingStyle.stroke..strokeWidth = 12;
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.9), size.width * 0.18, ringPaint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}