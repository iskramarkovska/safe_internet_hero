import 'package:flutter/material.dart';
import 'admin_content_ui.dart';

class AdminContentHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onManage;

  const AdminContentHeader({
    super.key,
    required this.onBack,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AdminContentUi.teal,
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
                color: AdminContentUi.tealDark,
                size: 20,
              ),
              onPressed: onBack,
            ),
          ),
          const Expanded(
            child: Text(
              'Add Learning Content',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
          PopupMenuButton<String>(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) async {
              if (value == 'manage') {
                onManage();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'manage',
                child: Text('Manage Categories & Topics'),
              ),
            ],
            child: Container(
              decoration: BoxDecoration(
                color: AdminContentUi.gold,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AdminContentUi.goldDark,
                  width: 2,
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(
                  Icons.more_horiz_rounded,
                  color: Color(0xFF5A7A6A),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}