import 'package:flutter/material.dart';
import '../models/learning_content_model.dart';
import '../services/learning_service.dart';

class AdminContentScreen extends StatefulWidget {
  const AdminContentScreen({super.key});

  @override
  State<AdminContentScreen> createState() => _AdminContentScreenState();
}

class _AdminContentScreenState extends State<AdminContentScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();
  final _thumbnailController = TextEditingController();
  final _readTimeController = TextEditingController();
  final LearningService _service = LearningService();

  String _categoryId = 'privacy';
  String _topicId = 'personal_info';
  ContentType _type = ContentType.article;
  bool _isSaving = false;

  final Map<String, List<String>> _categoryTopics = {
    'privacy': ['personal_info', 'sharing_online', 'digital_footprint', 'app_permissions'],
    'passwords': ['strong_passwords', 'two_factor_auth', 'password_safety', 'password_manager'],
    'cyberbullying': ['spot_bullying', 'be_an_upstander', 'report_block', 'cyber_law'],
    'social_media': ['privacy_settings', 'strangers_online', 'geo_tagging', 'screen_time'],
    'phishing': ['spot_scams', 'fake_links', 'email_safety', 'spear_phishing'],
  };

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    _thumbnailController.dispose();
    _readTimeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Title and content are required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final content = LearningContentModel(
        id: '',
        categoryId: _categoryId,
        topicId: _topicId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _type,
        content: _contentController.text.trim(),
        thumbnailUrl: _thumbnailController.text.trim(),
        readTimeMinutes: int.tryParse(_readTimeController.text) ?? 0,
        createdAt: DateTime.now(),
      );
      await _service.saveContent(content);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Content saved!'),
          backgroundColor: Colors.green,
        ),
      );
      _titleController.clear();
      _descriptionController.clear();
      _contentController.clear();
      _thumbnailController.clear();
      _readTimeController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
    setState(() => _isSaving = false);
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.white38),
    filled: true,
    fillColor: Colors.white.withOpacity(0.08),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF00D4FF)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Add Learning Content',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Content type
          const Text('Content type',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _typeButton('📄 Article', ContentType.article)),
              const SizedBox(width: 8),
              Expanded(child: _typeButton('▶️ Video', ContentType.video)),
              const SizedBox(width: 8),
              Expanded(child: _typeButton('🖼️ Image', ContentType.infographic)),
            ],
          ),
          const SizedBox(height: 16),

          // Category
          const Text('Category',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _categoryId,
            dropdownColor: const Color(0xFF16213E),
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Select category'),
            items: _categoryTopics.keys.map((cat) => DropdownMenuItem(
              value: cat,
              child: Text(cat),
            )).toList(),
            onChanged: (val) => setState(() {
              _categoryId = val!;
              _topicId = _categoryTopics[val]!.first;
            }),
          ),
          const SizedBox(height: 16),

          // Topic
          const Text('Topic',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _topicId,
            dropdownColor: const Color(0xFF16213E),
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Select topic'),
            items: (_categoryTopics[_categoryId] ?? []).map((topic) =>
                DropdownMenuItem(value: topic, child: Text(topic))).toList(),
            onChanged: (val) => setState(() => _topicId = val!),
          ),
          const SizedBox(height: 16),

          // Title
          const Text('Title',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Content title'),
          ),
          const SizedBox(height: 16),

          // Description
          const Text('Short description',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            style: const TextStyle(color: Colors.white),
            maxLines: 2,
            decoration: _inputDecoration('Brief description shown on card'),
          ),
          const SizedBox(height: 16),

          // Content
          Text(
            _type == ContentType.video
                ? 'YouTube Video ID'
                : _type == ContentType.infographic
                ? 'Image URL'
                : 'Article text',
            style: const TextStyle(
                color: Colors.white70, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _contentController,
            style: const TextStyle(color: Colors.white),
            maxLines: _type == ContentType.article ? 10 : 1,
            decoration: _inputDecoration(
              _type == ContentType.video
                  ? 'e.g. dQw4w9WgXcQ (from youtube.com/watch?v=XXXXX)'
                  : _type == ContentType.infographic
                  ? 'https://example.com/image.jpg'
                  : 'Write your article here...',
            ),
          ),
          const SizedBox(height: 16),

          // Thumbnail URL
          const Text('Thumbnail URL (optional)',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _thumbnailController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('https://example.com/thumbnail.jpg'),
          ),
          const SizedBox(height: 16),

          // Read time (articles only)
          if (_type == ContentType.article) ...[
            const Text('Read time (minutes)',
                style: TextStyle(
                    color: Colors.white70, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _readTimeController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('e.g. 3'),
            ),
            const SizedBox(height: 16),
          ],

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4FF),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator()
                  : const Text(
                'Save Content',
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _typeButton(String label, ContentType type) => GestureDetector(
    onTap: () => setState(() => _type = type),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: _type == type
            ? const Color(0xFF00D4FF).withOpacity(0.2)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _type == type ? const Color(0xFF00D4FF) : Colors.white24,
          width: 1.5,
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _type == type ? const Color(0xFF00D4FF) : Colors.white54,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    ),
  );
}