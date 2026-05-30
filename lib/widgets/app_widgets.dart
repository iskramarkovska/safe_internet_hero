import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import 'app_avatar.dart';

// ─── AppButton ─────────────────────────────────────────────────────────────────
// Duolingo-style 3D press button.
// FIX: uses onTap (not onTapUp) so mouse-click on web always fires the callback.

enum AppButtonVariant { primary, secondary, danger, success }

class AppButton extends StatefulWidget {
  final String label;
  final AppButtonVariant variant;
  final IconData? icon;
  final VoidCallback? onTap;

  const AppButton({
    super.key,
    required this.label,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.onTap,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  static const _depth = 4.0;

  Color get _bg => switch (widget.variant) {
        AppButtonVariant.primary => AppColors.blue,
        AppButtonVariant.secondary => Colors.white,
        AppButtonVariant.danger => AppColors.red,
        AppButtonVariant.success => AppColors.green,
      };

  Color get _shadow => switch (widget.variant) {
        AppButtonVariant.primary => AppColors.blueDark,
        AppButtonVariant.secondary => AppColors.borderDark,
        AppButtonVariant.danger => AppColors.redDark,
        AppButtonVariant.success => AppColors.greenDark,
      };

  Color get _fg => widget.variant == AppButtonVariant.secondary
      ? AppColors.blue
      : Colors.white;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, color: _fg, size: 20),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: _fg,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );

    return MouseRegion(
      cursor:
          disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        // onTap fires reliably on both web mouse-click and mobile touch.
        onTap: disabled ? null : widget.onTap,
        onTapDown:
            disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp:
            disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: Opacity(
          opacity: disabled ? 0.55 : 1.0,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              // Shadow layer — always offset _depth below
              Padding(
                padding: const EdgeInsets.only(top: _depth),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 15, horizontal: 24),
                  decoration: BoxDecoration(
                    color: _shadow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Opacity(opacity: 0, child: content),
                ),
              ),
              // Button body — slides down on press, covering shadow
              AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                width: double.infinity,
                margin: EdgeInsets.only(top: _pressed ? _depth : 0),
                padding: const EdgeInsets.symmetric(
                    vertical: 15, horizontal: 24),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(16),
                  border: widget.variant == AppButtonVariant.secondary
                      ? Border.all(color: AppColors.borderDark, width: 2)
                      : null,
                ),
                child: content,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── AppCard ───────────────────────────────────────────────────────────────────

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(20);
    return MouseRegion(
      cursor:
          onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: padding ?? const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: color ?? AppColors.card,
            borderRadius: br,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─── AppTopBar ─────────────────────────────────────────────────────────────────

class AppTopBar extends StatelessWidget {
  final int stars;
  final int streak;
  final int coins;
  final String? username;
  final VoidCallback? onAvatarTap;

  const AppTopBar({
    super.key,
    required this.stars,
    required this.streak,
    this.coins = 0,
    this.username,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          _Chip(
              icon: Icons.local_fire_department_rounded,
              value: '$streak',
              color: streak > 0 ? AppColors.orange : AppColors.textLight),
          const Spacer(),
          _Chip(
              icon: Icons.star_rounded,
              value: '$stars',
              color: AppColors.gold),
          const SizedBox(width: AppSpacing.sm),
          _Chip(
              icon: Icons.monetization_on_rounded,
              value: '$coins',
              color: AppColors.orangeDark),
          if (username != null) ...[
            const SizedBox(width: 12),
            MouseRegion(
              cursor: onAvatarTap != null
                  ? SystemMouseCursors.click
                  : MouseCursor.defer,
              child: GestureDetector(
                onTap: onAvatarTap,
                child: AppAvatar(name: username!, size: 34),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _Chip(
      {required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 5),
          Text(
            value,
            style: GoogleFonts.nunito(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── GuestLockedState ──────────────────────────────────────────────────────────
// Full-area locked placeholder shown to guests on social screens.

class GuestLockedState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  /// Navigate to the landing/auth screen. Caller decides the exact route.
  final VoidCallback onGetStarted;

  const GuestLockedState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.blueLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.blue, size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            AppButton(
              label: 'Get Started — It\'s Free',
              variant: AppButtonVariant.success,
              icon: Icons.person_add_rounded,
              onTap: onGetStarted,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Legacy widgets — kept for auth screens ────────────────────────────────────

class AppSolidButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final VoidCallback? onTap;

  const AppSolidButton({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(32)),
    );
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: color,
        shape: shape,
        shadowColor: color,
        elevation: 4,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                ],
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
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

class AppOutlineButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final VoidCallback? onTap;

  const AppOutlineButton({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: const BorderRadius.all(Radius.circular(32)),
      side: BorderSide(color: color, width: 2),
    );
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.white,
        shape: shape,
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 10),
                ],
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
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

// ─── AppTextField ──────────────────────────────────────────────────────────────
// Duolingo-style: visible gray border, blue on focus, radius 14.

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscure;
  final Widget? suffixIcon;

  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: GoogleFonts.nunito(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.nunito(
          color: AppColors.textLight,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.border, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.border, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.blue, width: 2.5),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 16),
      ),
    );
  }
}
