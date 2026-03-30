import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/category_model.dart';
import '../models/topic_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/questions_service.dart';
import '../services/topics_service.dart';
import 'quiz_screen.dart';

class TopicsScreen extends StatefulWidget {
  const TopicsScreen({super.key});

  @override
  State<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  static const teal = Color(0xFF2BBFAA);
  static const darkTeal = Color(0xFF1A9E8F);

  final TopicsService _topicsService = TopicsService();
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  String? _expandedCategoryId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<bool> _isTopicCompleted(UserModel? user, String categoryId, String topicId) async {
    if (user == null) return false;
    final service = QuestionService();
    final total = await service.getTotalQuestionsCount(categoryId: categoryId, topicId: topicId);
    if (total == 0) return false;
    final all = await service.getQuestions(categoryId: categoryId, topicId: topicId, limit: 1000);
    return all.where((q) => user.answeredQuestions.contains(q.id)).length >= total;
  }

  Future<double> _topicProgress(UserModel? user, String categoryId, String topicId) async {
    if (user == null) return 0;
    final service = QuestionService();
    final total = await service.getTotalQuestionsCount(categoryId: categoryId, topicId: topicId);
    if (total == 0) return 0;
    final all = await service.getQuestions(categoryId: categoryId, topicId: topicId, limit: 1000);
    final answered = all.where((q) => user.answeredQuestions.contains(q.id)).length;
    return answered / total;
  }

  Future<int> _completedCount(UserModel? user, String categoryId, List<TopicModel> topics) async {
    int count = 0;
    for (final t in topics) {
      if (await _isTopicCompleted(user, categoryId, t.id)) count++;
    }
    return count;
  }

  void _openQuiz(BuildContext context, {required CategoryModel category, required TopicModel topic}) async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    final isGuest = auth.isGuest;

    if (!isGuest && user != null) {
      final service = QuestionService();
      final total = await service.getTotalQuestionsCount(categoryId: category.id, topicId: topic.id);
      final all = await service.getQuestions(categoryId: category.id, topicId: topic.id, limit: 1000);
      final answered = all.where((q) => user.answeredQuestions.contains(q.id)).length;

      if (total > 0 && answered >= total) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🏆', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 12),
                const Text('Topic Completed!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Text('All questions in ${topic.name} answered!', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 20),
                SizedBox(width: double.infinity, child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('Back to Topics'),
                )),
              ],
            ),
          ),
        );
        return;
      }
    }

    if (!context.mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => QuizScreen(
      categoryId: category.id,
      categoryName: category.title,
      topicId: topic.id,
      topicName: topic.name,
      color: teal,
    )));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isGuest = auth.isGuest;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: teal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text('Topics List', textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: StreamBuilder<List<CategoryModel>>(
                stream: _topicsService.watchCategories(),
                builder: (context, catSnap) {
                  if (!catSnap.hasData) return const Center(child: CircularProgressIndicator());

                  return StreamBuilder<List<TopicModel>>(
                    stream: _topicsService.watchAllTopics(),
                    builder: (context, topicSnap) {
                      if (!topicSnap.hasData) return const Center(child: CircularProgressIndicator());

                      final categories = catSnap.data!;
                      final allTopics = topicSnap.data!;

                      // Apply search filter
                      final query = _searchText.trim().toLowerCase();
                      final filtered = categories.map((cat) {
                        final topics = allTopics
                            .where((t) => t.categoryId == cat.id)
                            .toList()
                          ..sort((a, b) => a.order.compareTo(b.order));

                        if (query.isEmpty) return (cat: cat, topics: topics);
                        if (cat.title.toLowerCase().contains(query)) return (cat: cat, topics: topics);

                        final matched = topics.where((t) =>
                        t.name.toLowerCase().contains(query) ||
                            t.desc.toLowerCase().contains(query)).toList();
                        if (matched.isEmpty) return null;
                        return (cat: cat, topics: matched);
                      }).whereType<({CategoryModel cat, List<TopicModel> topics})>()
                          .where((g) => g.topics.isNotEmpty)
                          .toList();

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        children: [
                          // Search bar
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE0E0E0)),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 3))],
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (v) => setState(() => _searchText = v),
                              decoration: InputDecoration(
                                hintText: 'Search topics...',
                                hintStyle: const TextStyle(color: AppColors.textLight),
                                prefixIcon: const Icon(Icons.search_rounded, color: teal),
                                suffixIcon: _searchText.isNotEmpty
                                    ? IconButton(icon: const Icon(Icons.close_rounded), onPressed: () { _searchController.clear(); setState(() => _searchText = ''); })
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          if (filtered.isEmpty)
                            const Center(child: Padding(
                              padding: EdgeInsets.only(top: 40),
                              child: Text('No topics found', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                            )),

                          for (final item in filtered)
                            _CategoryCard(
                              category: item.cat,
                              topics: item.topics,
                              isExpanded: _expandedCategoryId == item.cat.id,
                              user: user,
                              isGuest: isGuest,
                              onExpandToggle: () => setState(() {
                                _expandedCategoryId = _expandedCategoryId == item.cat.id ? null : item.cat.id;
                              }),
                              onOpenQuiz: (t) => _openQuiz(context, category: item.cat, topic: t),
                              isTopicCompleted: _isTopicCompleted,
                              topicProgress: _topicProgress,
                              completedCount: _completedCount,
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final List<TopicModel> topics;
  final bool isExpanded;
  final UserModel? user;
  final bool isGuest;
  final VoidCallback onExpandToggle;
  final void Function(TopicModel) onOpenQuiz;
  final Future<bool> Function(UserModel?, String, String) isTopicCompleted;
  final Future<double> Function(UserModel?, String, String) topicProgress;
  final Future<int> Function(UserModel?, String, List<TopicModel>) completedCount;

  const _CategoryCard({
    required this.category,
    required this.topics,
    required this.isExpanded,
    required this.user,
    required this.isGuest,
    required this.onExpandToggle,
    required this.onOpenQuiz,
    required this.isTopicCompleted,
    required this.topicProgress,
    required this.completedCount,
  });

  static const teal = Color(0xFF2BBFAA);
  static const darkTeal = Color(0xFF1A9E8F);

  @override
  Widget build(BuildContext context) {
    final hasNew = topics.any((t) => t.isNew);
    final hasUpdated = topics.any((t) => t.isUpdated);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: teal,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: darkTeal, width: 2),
        boxShadow: const [
          BoxShadow(color: darkTeal, offset: Offset(0, 5), blurRadius: 0),
          BoxShadow(color: Colors.black12, offset: Offset(0, 8), blurRadius: 8),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            // Header row
            Stack(
              children: [
                GestureDetector(
                  onTap: onExpandToggle,
                  child: Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Row(
                      children: [
                        // Icon in white circle
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: darkTeal.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: const Icon(Icons.lock_rounded, color: teal, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Yellow label
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8C84A),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFC8A830), width: 1.5),
                                ),
                                child: Text(category.title,
                                    style: const TextStyle(color: Color(0xFF5A4A1A), fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                              const SizedBox(height: 6),
                              Text('${topics.length} topics',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12)),

                              if (!isGuest && user != null) ...[
                                const SizedBox(height: 6),
                                FutureBuilder<int>(
                                  future: completedCount(user, category.id, topics),
                                  builder: (context, snap) {
                                    final done = snap.data ?? 0;
                                    final total = topics.length;
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(20),
                                          child: LinearProgressIndicator(
                                            value: total == 0 ? 0 : done / total,
                                            minHeight: 6,
                                            backgroundColor: Colors.white24,
                                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE8C84A)),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text('$done / $total completed',
                                            style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 250),
                          child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 30),
                        ),
                      ],
                    ),
                  ),
                ),

                // Ribbon badge
                if (hasNew || hasUpdated)
                  Positioned(
                    top: 0, right: 0,
                    child: ClipPath(
                      clipper: _RibbonClipper(),
                      child: Container(
                        width: 68, height: 68,
                        color: hasNew ? const Color(0xFFF45B8C) : const Color(0xFFFFA726),
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(top: 9, right: 5),
                        child: Transform.rotate(
                          angle: 0.78,
                          child: Text(hasNew ? 'NEW' : 'UPD',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Expanded topics — cream bg
            if (isExpanded)
              Container(
                color: const Color(0xFFF5FAF7),
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Column(
                  children: topics.map((topic) => isGuest
                      ? _TopicRow(topic: topic, isDone: false, progress: 0, onTap: () => onOpenQuiz(topic))
                      : FutureBuilder<List<dynamic>>(
                    future: Future.wait([
                      isTopicCompleted(user, category.id, topic.id),
                      topicProgress(user, category.id, topic.id),
                    ]),
                    builder: (context, snap) => _TopicRow(
                      topic: topic,
                      isDone: snap.data?[0] as bool? ?? false,
                      progress: snap.data?[1] as double? ?? 0,
                      onTap: () => onOpenQuiz(topic),
                    ),
                  )).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  final TopicModel topic;
  final bool isDone;
  final double progress;
  final VoidCallback onTap;

  const _TopicRow({required this.topic, required this.isDone, required this.progress, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDone ? const Color(0xFFFFF9E7) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDone ? const Color(0xFFC8A830) : const Color(0xFFE0E0E0),
            width: isDone ? 1.5 : 1,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(topic.name,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                        color: isDone ? const Color(0xFF8A6B12) : AppColors.textPrimary))),
                if (topic.isNew)
                  Container(margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFF45B8C), borderRadius: BorderRadius.circular(8)),
                      child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
                if (topic.isUpdated)
                  Container(margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFFFA726), borderRadius: BorderRadius.circular(8)),
                      child: const Text('UPD', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
                const SizedBox(width: 8),
                isDone
                    ? const Icon(Icons.check_circle_rounded, color: Color(0xFFC8A830), size: 20)
                    : Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade400, size: 13),
              ],
            ),
            const SizedBox(height: 3),
            Text(topic.desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: const Color(0xFFEEEEEE),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2BBFAA)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RibbonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}