import 'package:flutter/material.dart';
import '../../../models/learning_content_model.dart';
import 'admin_content_ui.dart';

class ContentTypeSelector extends StatelessWidget {
  final ContentType selectedType;
  final ValueChanged<ContentType> onChanged;

  const ContentTypeSelector({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      title: 'Content type',
      child: Row(
        children: [
          Expanded(
            child: _TypeButton(
              label: 'Article',
              selected: selectedType == ContentType.article,
              onTap: () => onChanged(ContentType.article),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TypeButton(
              label: 'Video',
              selected: selectedType == ContentType.video,
              onTap: () => onChanged(ContentType.video),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TypeButton(
              label: 'Image',
              selected: selectedType == ContentType.infographic,
              onTap: () => onChanged(ContentType.infographic),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AdminContentUi.teal.withOpacity(0.15)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AdminContentUi.teal
                : const Color(0xFFE5E7EB),
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected
                ? AdminContentUi.tealDark
                : const Color(0xFF6B7280),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}