import 'package:flutter/material.dart';
import '../../../models/learning_content_model.dart';
import 'admin_content_ui.dart';

class ContentDetailsSection extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController contentController;
  final TextEditingController thumbnailController;
  final TextEditingController readTimeController;
  final ContentType type;

  const ContentDetailsSection({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.contentController,
    required this.thumbnailController,
    required this.readTimeController,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      title: 'Main content',
      child: Column(
        children: [
          const AdminSectionLabel('Title'),
          const SizedBox(height: 8),
          TextField(
            controller: titleController,
            decoration: AdminContentUi.inputDecoration('Content title'),
          ),
          const SizedBox(height: 16),
          const AdminSectionLabel('Short description'),
          const SizedBox(height: 8),
          TextField(
            controller: descriptionController,
            maxLines: 2,
            decoration: AdminContentUi.inputDecoration(
              'Brief description shown on card',
            ),
          ),
          const SizedBox(height: 16),
          AdminSectionLabel(
            type == ContentType.video
                ? 'YouTube Video ID'
                : type == ContentType.infographic
                ? 'Image URL'
                : 'Article text',
          ),
          const SizedBox(height: 8),
          TextField(
            controller: contentController,
            maxLines: type == ContentType.article ? 10 : 1,
            decoration: AdminContentUi.inputDecoration(
              type == ContentType.video
                  ? 'e.g. dQw4w9WgXcQ'
                  : type == ContentType.infographic
                  ? 'https://example.com/image.jpg'
                  : 'Write your article here...',
            ),
          ),
          const SizedBox(height: 16),
          const AdminSectionLabel('Thumbnail URL (optional)'),
          const SizedBox(height: 8),
          TextField(
            controller: thumbnailController,
            decoration: AdminContentUi.inputDecoration(
              'https://example.com/thumbnail.jpg',
            ),
          ),
          if (type == ContentType.article) ...[
            const SizedBox(height: 16),
            const AdminSectionLabel('Read time (minutes)'),
            const SizedBox(height: 8),
            TextField(
              controller: readTimeController,
              keyboardType: TextInputType.number,
              decoration: AdminContentUi.inputDecoration('e.g. 3'),
            ),
          ],
        ],
      ),
    );
  }
}