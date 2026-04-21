import 'package:flutter/material.dart';
import '../core/theme.dart';

// AdminColors delegates to AppColors so all admin screens keep working
// without modification while color values live in one place.
class AdminColors {
  static const teal = AppColors.teal;
  static const darkTeal = AppColors.darkTeal;
  static const red = AppColors.hero;
  static const yellow = AppColors.gold;
  static const yellowDark = AppColors.goldDark;
  static const cream = AppColors.cream;
}

// ─────────────────────────────────────────────────────────────
// LAYOUT
// ─────────────────────────────────────────────────────────────

/// White card with title and shadow — used everywhere in forms
class AdminCard extends StatelessWidget {
  final String title;
  final Widget child;
  const AdminCard({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF111827))),
      const SizedBox(height: 14),
      child,
    ]),
  );
}

/// Yellow banner shown when editing an existing item
class AdminEditBanner extends StatelessWidget {
  final String title;
  final VoidCallback onClear;
  const AdminEditBanner({super.key, required this.title, required this.onClear});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF8E1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFFFB300)),
    ),
    child: Row(children: [
      const Icon(Icons.edit_rounded, color: Color(0xFFFFB300), size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text('Editing: $title',
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFF8A6B12), fontWeight: FontWeight.bold, fontSize: 13))),
      GestureDetector(onTap: onClear,
          child: const Icon(Icons.close_rounded, color: Color(0xFF8A6B12), size: 18)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────
// FORM ELEMENTS
// ─────────────────────────────────────────────────────────────

/// Small bold label above a field
class AdminLabel extends StatelessWidget {
  final String text;
  const AdminLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF374151), fontSize: 13));
}

/// Standard text field with teal focus border
class AdminField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  const AdminField({
    super.key,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    maxLines: maxLines,
    keyboardType: keyboardType,
    decoration: _dec(hint),
  );

  static InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
    filled: true, fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AdminColors.teal, width: 2)),
  );

  /// Also used by TextFormField via static method
  static InputDecoration decoration(String hint) => _dec(hint);
}

/// Dropdown with teal focus border
class AdminDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final String hint;
  final ValueChanged<T?> onChanged;
  const AdminDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    value: value, items: items, onChanged: onChanged,
    decoration: AdminField._dec(hint),
  );
}

/// Toggle card (New / Updated badges)
class AdminToggle extends StatelessWidget {
  final String label;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;
  const AdminToggle({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => onChanged(!value),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: value ? color.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: value ? color : const Color(0xFFE5E7EB), width: value ? 2 : 1),
      ),
      child: Row(children: [
        Icon(value ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: value ? color : const Color(0xFF9CA3AF), size: 20),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontWeight: FontWeight.bold,
            color: value ? color : const Color(0xFF6B7280))),
      ]),
    ),
  );
}

/// Selectable pill (question type, true/false answer)
class AdminSelectTile extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;
  const AdminSelectTile({
    super.key,
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AdminColors.teal;
    return GestureDetector(onTap: onTap,
      child: AnimatedContainer(duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? c.withOpacity(0.12) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? c : const Color(0xFFE5E7EB), width: selected ? 2 : 1),
        ),
        child: Text(label, textAlign: TextAlign.center,
            style: TextStyle(color: selected ? c : const Color(0xFF6B7280),
                fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }
}

/// Difficulty tile (Beginner / Intermediate / Advanced)
class AdminDifficultyTile extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const AdminDifficultyTile({
    super.key,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: AnimatedContainer(duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: selected ? color.withOpacity(0.12) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? color : const Color(0xFFE5E7EB), width: selected ? 2 : 1),
      ),
      child: Text(label, textAlign: TextAlign.center,
          style: TextStyle(color: selected ? color : const Color(0xFF6B7280),
              fontWeight: FontWeight.bold, fontSize: 12)),
    ),
  );
}

/// Content type button (Article / Video / Image) — with icon
class AdminTypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const AdminTypeButton({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: AnimatedContainer(duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: selected ? AdminColors.teal.withOpacity(0.12) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? AdminColors.teal : const Color(0xFFE5E7EB), width: selected ? 2 : 1),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: selected ? AdminColors.teal : const Color(0xFF9CA3AF), size: 20),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center,
            style: TextStyle(color: selected ? AdminColors.darkTeal : const Color(0xFF6B7280),
                fontWeight: FontWeight.bold, fontSize: 12)),
      ]),
    ),
  );
}

/// Option field for MCQ — tap left side to mark as correct
class AdminOptionField extends StatelessWidget {
  final TextEditingController controller;
  final String letter;
  final int index;
  final int correctIndex;
  final VoidCallback onTap;
  const AdminOptionField({
    super.key,
    required this.controller,
    required this.letter,
    required this.index,
    required this.correctIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCorrect = correctIndex == index;
    return GestureDetector(onTap: onTap,
      child: AnimatedContainer(duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isCorrect ? Colors.green : const Color(0xFFE5E7EB), width: isCorrect ? 2 : 1),
        ),
        child: Row(children: [
          Container(width: 42, height: 50,
            decoration: BoxDecoration(
              color: isCorrect ? Colors.green.withOpacity(0.12) : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
            ),
            child: Center(child: Text(isCorrect ? '✓' : letter,
                style: TextStyle(color: isCorrect ? Colors.green : const Color(0xFF9CA3AF),
                    fontWeight: FontWeight.bold))),
          ),
          Expanded(child: TextField(controller: controller,
              decoration: InputDecoration(
                  hintText: 'Option $letter',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12)))),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BUTTONS
// ─────────────────────────────────────────────────────────────

/// Primary teal button with 3D shadow
class AdminPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const AdminPrimaryButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: Container(height: 52,
      decoration: BoxDecoration(
        color: AdminColors.teal,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.darkTeal, width: 2),
        boxShadow: const [BoxShadow(color: AdminColors.darkTeal, offset: Offset(0, 4), blurRadius: 0)],
      ),
      child: Center(child: Text(label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
    ),
  );
}

/// Secondary white outline button
class AdminSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const AdminSecondaryButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: Container(height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: Center(child: Text(label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF374151)))),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// BOTTOM SHEET WRAPPER
// ─────────────────────────────────────────────────────────────

/// Consistent bottom sheet container used in add/edit sheets
class AdminBottomSheet extends StatelessWidget {
  final String title;
  final Widget child;
  const AdminBottomSheet({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24),
    child: Container(
      decoration: BoxDecoration(
        color: AdminColors.cream,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 44, height: 5,
              decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(20)))),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF111827))),
          const SizedBox(height: 16),
          child,
          const SizedBox(height: 8),
        ]),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// MISC
// ─────────────────────────────────────────────────────────────

/// Small colored badge (NEW / UPDATED / MCQ / etc.)
class AdminBadge extends StatelessWidget {
  final String text;
  final Color color;
  const AdminBadge({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(left: 4),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
    child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 9)),
  );
}

/// Empty state placeholder for lists
class AdminEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const AdminEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: const Color(0xFFD1D5DB), size: 56),
      const SizedBox(height: 12),
      Text(title, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 16)),
      const SizedBox(height: 6),
      Text(subtitle, style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 13)),
    ]),
  );
}

/// Dashboard card — navigates to a manage screen
class AdminDashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  const AdminDashboardCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(children: [
          Container(
            width: 58, height: 58,
            decoration: BoxDecoration(
              color: AdminColors.yellow.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AdminColors.yellowDark.withOpacity(0.35)),
            ),
            child: Icon(icon, color: AdminColors.darkTeal, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13, height: 1.35)),
          ])),
          const SizedBox(width: 12),
          const Icon(Icons.arrow_forward_ios_rounded, color: AdminColors.teal, size: 18),
        ]),
      ),
    );
  }
}