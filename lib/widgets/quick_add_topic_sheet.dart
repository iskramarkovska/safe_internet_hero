import 'package:flutter/material.dart';
import 'admin_content_ui.dart';

class QuickAddTopicSheet extends StatefulWidget {
  final String categoryTitle;
  final int initialOrder;
  final Future<void> Function(
      String name,
      String desc,
      bool isNew,
      bool isUpdated,
      int order,
      ) onSave;

  const QuickAddTopicSheet({
    super.key,
    required this.categoryTitle,
    required this.initialOrder,
    required this.onSave,
  });

  @override
  State<QuickAddTopicSheet> createState() => _QuickAddTopicSheetState();
}

class _QuickAddTopicSheetState extends State<QuickAddTopicSheet> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  bool _isNew = true;
  bool _isUpdated = false;
  bool _saving = false;
  late int _order;

  @override
  void initState() {
    super.initState();
    _order = widget.initialOrder;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final desc = _descController.text.trim();

    if (name.isEmpty || desc.isEmpty) return;

    setState(() => _saving = true);

    try {
      await widget.onSave(name, desc, _isNew, _isUpdated, _order);
      if (!mounted) return;
      Navigator.pop(context);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AdminContentUi.cream,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Add Topic to ${widget.categoryTitle}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            const AdminSectionLabel('Topic Name'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: AdminContentUi.inputDecoration('Enter topic name'),
            ),
            const SizedBox(height: 16),
            const AdminSectionLabel('Description'),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: AdminContentUi.inputDecoration('Short description'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AdminToggleCard(
                    label: 'New',
                    value: _isNew,
                    color: const Color(0xFFF45B8C),
                    onTap: () => setState(() => _isNew = !_isNew),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AdminToggleCard(
                    label: 'Updated',
                    value: _isUpdated,
                    color: const Color(0xFFFFA726),
                    onTap: () => setState(() => _isUpdated = !_isUpdated),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const AdminSectionLabel('Order'),
            const SizedBox(height: 8),
            AdminOrderStepper(
              value: _order,
              onChanged: (value) => setState(() => _order = value),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: AdminSecondaryButton(
                    label: 'Cancel',
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AdminPrimaryButton(
                    label: _saving ? 'Saving...' : 'Save Topic',
                    onTap: _saving ? () {} : _handleSave,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}