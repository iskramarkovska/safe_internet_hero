import 'package:flutter/material.dart';
import '../../../models/category_model.dart';
import '../../../models/topic_model.dart';
import 'admin_content_ui.dart';

class ContentCategoryTopicSection extends StatelessWidget {
  final List<CategoryModel> categories;
  final List<TopicModel> topics;
  final String? selectedCategoryId;
  final String? selectedTopicId;
  final ValueChanged<String?> onTopicChanged;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onAddTopic;

  const ContentCategoryTopicSection({
    super.key,
    required this.categories,
    required this.topics,
    required this.selectedCategoryId,
    required this.selectedTopicId,
    required this.onTopicChanged,
    required this.onCategoryChanged,
    required this.onAddTopic,
  });

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      title: 'Where does this content belong?',
      child: Column(
        children: [
          const AdminSectionLabel('Category'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _safeCategoryValue(),
            decoration: AdminContentUi.inputDecoration('Select category'),
            items: categories
                .map(
                  (cat) => DropdownMenuItem<String>(
                value: cat.id,
                child: Text(cat.title),
              ),
            )
                .toList(),
            onChanged: onCategoryChanged,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: AdminStaticLabel(text: 'Topic'),
              ),
              TextButton.icon(
                onPressed: onAddTopic,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Topic'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _safeTopicValue(),
            decoration: AdminContentUi.inputDecoration('Select topic'),
            items: topics
                .map(
                  (topic) => DropdownMenuItem<String>(
                value: topic.id,
                child: Text(topic.name),
              ),
            )
                .toList(),
            onChanged: onTopicChanged,
          ),
        ],
      ),
    );
  }

  String? _safeCategoryValue() {
    final matches =
        categories.where((cat) => cat.id == selectedCategoryId).length;
    return matches == 1 ? selectedCategoryId : null;
  }

  String? _safeTopicValue() {
    final matches = topics.where((topic) => topic.id == selectedTopicId).length;
    return matches == 1 ? selectedTopicId : null;
  }
}