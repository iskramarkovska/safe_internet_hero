import 'package:flutter/material.dart';
import '../../widgets/admin_widgets.dart';
import 'manage_categories_topics_screen.dart';
import 'manage_learning_content_screen.dart';
import 'manage_questions_screen.dart';


class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  static const Color teal = Color(0xFF2BBFAA);
  static const Color tealDark = Color(0xFF1A9E8F);
  static const Color cream = Color(0xFFF5FAF7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Column(
          children: [
            Container(
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
                      border: Border.all(
                        color: const Color(0xFFFFF0C2),
                        width: 2,
                      ),
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
                      'Admin Dashboard',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                children: [
                  AdminDashboardCard(
                    title: 'Manage Questions',
                    subtitle:
                    'Create quiz questions, choose difficulty, and set correct answers.',
                    icon: Icons.quiz_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ManageQuestionsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  AdminDashboardCard(
                    title: 'Manage Learning Content',
                    subtitle:
                    'Create and edit articles, videos, images, and learning resources.',
                    icon: Icons.library_books_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const ManageLearningContentScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  AdminDashboardCard(
                    title: 'Manage Categories & Topics',
                    subtitle:
                    'Create, edit, organize, and delete categories and topics.',
                    icon: Icons.category_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const CategoryTopicManagerScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}