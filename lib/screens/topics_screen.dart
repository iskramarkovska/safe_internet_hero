import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/color_mapper.dart';
import '../core/icon_mapper.dart';
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
  static const teal = Color(0xFF38C6C6);
  static const tealDark = Color(0xFF1CA7A7);
  static const cream = Color(0xFFF5FAF7);
  static const pink = Color(0xFFF45B8C);

  final TopicsService _topicsService = TopicsService();
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  String? expandedCategoryId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<bool> _isTopicCompleted(UserModel? user, String categoryId, String topicId) async {
    if (user == null) return false;
    final service = QuestionService();
    final total = await service.getTotalQuestionsCount(
      categoryId: categoryId,
      topicId: topicId,
    );
    if (total == 0) return false;
    final all = await service.getQuestions(
      categoryId: categoryId,
      topicId: topicId,
      limit: 1000,
    );
    return all.where((q) => user.answeredQuestions.contains(q.id)).length >= total;
  }

  Future<double> _topicProgress(UserModel? user, String categoryId, String topicId) async {
    if (user == null) return 0;
    final service = QuestionService();
    final total = await service.getTotalQuestionsCount(
      categoryId: categoryId,
      topicId: topicId,
    );
    if (total == 0) return 0;
    final all = await service.getQuestions(
      categoryId: categoryId,
      topicId: topicId,
      limit: 1000,
    );
    final answered = all.where((q) => user.answeredQuestions.contains(q.id)).length;
    return answered / total;
  }

  Future<int> _completedCountForCategory(UserModel? user, CategoryModel category, List<TopicModel> topics) async {
    int count = 0;
    for (final topic in topics) {
      final isDone = await _isTopicCompleted(user, category.id, topic.id);
      if (isDone) {
        count++;
      }
    }
    return count;
  }

  void _openQuiz(BuildContext context, {required CategoryModel category, required TopicModel topic}) async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    final isGuest = auth.isGuest;

    if (!isGuest && user != null) {
      final service = QuestionService();
      final total = await service.getTotalQuestionsCount(
        categoryId: category.id,
        topicId: topic.id,
      );
      final all = await service.getQuestions(
        categoryId: category.id,
        topicId: topic.id,
        limit: 1000,
      );
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
                const Text(
                  'Topic Completed!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'All questions in ${topic.name} answered!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Back to Topics'),
                  ),
                ),
              ],
            ),
          ),
        );
        return;
      }
    }

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          categoryId: category.id,
          categoryName: category.title,
          topicId: topic.id,
          topicName: topic.name,
          color: ColorMapper.fromHex(category.accentColorHex),
        ),
      ),
    );
  }

  List<_CategoryWithTopics> _applySearch(List<CategoryModel> categories, List<TopicModel> topics) {
    final query = _searchText.trim().toLowerCase();

    final grouped = categories.map((category) {
      final categoryTopics = topics
          .where((topic) => topic.categoryId == category.id)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));

      return _CategoryWithTopics(
        category: category,
        topics: categoryTopics,
      );
    }).toList();

    if (query.isEmpty) {
      return grouped.where((item) => item.topics.isNotEmpty).toList();
    }

    final filtered = <_CategoryWithTopics>[];

    for (final item in grouped) {
      final categoryMatches = item.category.title.toLowerCase().contains(query);

      final topicMatches = item.topics.where((topic) {
        return topic.name.toLowerCase().contains(query) ||
            topic.desc.toLowerCase().contains(query);
      }).toList();

      if (categoryMatches) {
        filtered.add(item);
      } else if (topicMatches.isNotEmpty) {
        filtered.add(
          _CategoryWithTopics(
            category: item.category,
            topics: topicMatches,
          ),
        );
      }
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isGuest = auth.isGuest;

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: StreamBuilder<List<CategoryModel>>(
                stream: _topicsService.watchCategories(),
                builder: (context, categoriesSnapshot) {
                  if (categoriesSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (categoriesSnapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Failed to load categories',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }

                  final categories = categoriesSnapshot.data ?? [];

                  return StreamBuilder<List<TopicModel>>(
                    stream: _topicsService.watchAllTopics(),
                    builder: (context, topicsSnapshot) {
                      if (topicsSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (topicsSnapshot.hasError) {
                        return const Center(
                          child: Text(
                            'Failed to load topics',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        );
                      }

                      final topics = topicsSnapshot.data ?? [];
                      final items = _applySearch(categories, topics);

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        children: [
                          _buildTopText(),
                          const SizedBox(height: 16),
                          _buildSearchBar(),
                          const SizedBox(height: 20),
                          ...items.map(
                                (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _CategoryCard(
                                category: item.category,
                                topics: item.topics,
                                isExpanded: expandedCategoryId == item.category.id,
                                user: user,
                                isGuest: isGuest,
                                onExpandToggle: () {
                                  setState(() {
                                    expandedCategoryId =
                                    expandedCategoryId == item.category.id ? null : item.category.id;
                                  });
                                },
                                onOpenQuiz: (topic) => _openQuiz(
                                  context,
                                  category: item.category,
                                  topic: topic,
                                ),
                                isTopicCompleted: _isTopicCompleted,
                                topicProgress: _topicProgress,
                                completedCountForCategory: _completedCountForCategory,
                              ),
                            ),
                          ),
                          if (items.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.only(top: 40),
                                child: Text(
                                  'No topics found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: teal,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFF0C2), width: 2),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: tealDark,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Expanded(
            child: Text(
              'Topics List',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildTopText() {
    return const Column(
      children: [
        Text(
          'Select a topic',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Choose a category and start learning',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E4E4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchText = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search topics...',
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.search_rounded, color: tealDark),
          suffixIcon: _searchText.isNotEmpty
              ? IconButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchText = '';
              });
            },
            icon: const Icon(Icons.close_rounded),
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class _CategoryWithTopics {
  final CategoryModel category;
  final List<TopicModel> topics;

  const _CategoryWithTopics({
    required this.category,
    required this.topics,
  });
}

class _CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final List<TopicModel> topics;
  final bool isExpanded;
  final UserModel? user;
  final bool isGuest;
  final VoidCallback onExpandToggle;
  final void Function(TopicModel topic) onOpenQuiz;
  final Future<bool> Function(UserModel?, String, String) isTopicCompleted;
  final Future<double> Function(UserModel?, String, String) topicProgress;
  final Future<int> Function(UserModel?, CategoryModel, List<TopicModel>) completedCountForCategory;

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
    required this.completedCountForCategory,
  });

  static const tealCard = Color(0xFF41C7C7);
  static const pink = Color(0xFFF45B8C);

  @override
  Widget build(BuildContext context) {
    final accentColor = ColorMapper.fromHex(category.accentColorHex);
    final categoryIcon = IconMapper.fromString(category.iconName);

    return FutureBuilder<int>(
      future: isGuest ? Future.value(0) : completedCountForCategory(user, category, topics),
      builder: (context, snapshot) {
        final completedCount = snapshot.data ?? 0;
        final total = topics.length;
        final ratio = total == 0 ? 0.0 : completedCount / total;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: tealCard,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  InkWell(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(22),
                      bottom: Radius.circular(22),
                    ),
                    onTap: onExpandToggle,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                      child: Row(
                        children: [
                          Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: Icon(
                              categoryIcon,
                              color: accentColor,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _GoldenLabel(text: category.title),
                                const SizedBox(height: 10),
                                Text(
                                  '${topics.length} topics in this category',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: LinearProgressIndicator(
                                    value: ratio,
                                    minHeight: 8,
                                    backgroundColor: Colors.white24,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      completedCount == total && total > 0 ? Colors.amber : Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$completedCount / $total completed',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 250),
                            child: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_hasAnyBadge(topics))
                    Positioned(
                      top: 0,
                      right: 0,
                      child: _RibbonBadge(
                        text: _badgeText(topics),
                        color: pink,
                      ),
                    ),
                ],
              ),
              if (isExpanded)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: Column(
                    children: topics
                        .map(
                          (topic) => Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: isGuest
                            ? _TopicTile(
                          topic: topic,
                          accentColor: accentColor,
                          isDone: false,
                          progress: 0,
                          onTap: () => onOpenQuiz(topic),
                        )
                            : FutureBuilder<List<dynamic>>(
                          future: Future.wait([
                            isTopicCompleted(user, category.id, topic.id),
                            topicProgress(user, category.id, topic.id),
                          ]),
                          builder: (context, snap) {
                            final isDone = snap.hasData ? snap.data![0] as bool : false;
                            final progress = snap.hasData ? snap.data![1] as double : 0.0;

                            return _TopicTile(
                              topic: topic,
                              accentColor: accentColor,
                              isDone: isDone,
                              progress: progress,
                              onTap: () => onOpenQuiz(topic),
                            );
                          },
                        ),
                      ),
                    )
                        .toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  bool _hasAnyBadge(List<TopicModel> topics) {
    return topics.any((t) => t.isNew || t.isUpdated);
  }

  String _badgeText(List<TopicModel> topics) {
    if (topics.any((t) => t.isNew)) return 'NEW';
    if (topics.any((t) => t.isUpdated)) return 'UPDATED';
    return '';
  }
}

class _TopicTile extends StatelessWidget {
  final TopicModel topic;
  final Color accentColor;
  final bool isDone;
  final double progress;
  final VoidCallback onTap;

  const _TopicTile({
    required this.topic,
    required this.accentColor,
    required this.isDone,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDone ? const Color(0xFFFFF9E7) : Colors.white;
    final topicIcon = IconMapper.fromString(topic.iconName);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDone ? const Color(0xFFC6A94F) : const Color(0xFFE7E7E7),
              width: isDone ? 1.8 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  topicIcon,
                  color: accentColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            topic.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDone ? const Color(0xFF8A6B12) : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (topic.isNew)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: _MiniBadge(
                              text: 'NEW',
                              color: Color(0xFFF45B8C),
                            ),
                          ),
                        if (topic.isUpdated)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: _MiniBadge(
                              text: 'UPDATED',
                              color: Color(0xFFFFA726),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      topic.desc,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFEEEEEE),
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              isDone
                  ? const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFFC6A94F),
                size: 24,
              )
                  : const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey,
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoldenLabel extends StatelessWidget {
  final String text;

  const _GoldenLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8D07A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC6A94F), width: 1.5),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF7A621D),
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RibbonBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _RibbonBadge({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _RibbonClipper(),
      child: Container(
        width: 90,
        height: 90,
        color: color,
        alignment: Alignment.topRight,
        padding: const EdgeInsets.only(top: 14, right: 8),
        child: Transform.rotate(
          angle: 0.78,
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _MiniBadge({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
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