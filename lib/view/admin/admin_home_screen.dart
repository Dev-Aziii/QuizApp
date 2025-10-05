import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:itsreviewer_app/theme/theme.dart';
import 'package:itsreviewer_app/view/admin/manage_categories_screen.dart';
import 'package:itsreviewer_app/view/admin/manage_quizes_screen.dart';
import 'package:itsreviewer_app/auth/auth.dart';
import 'package:itsreviewer_app/view/widgets/confirm_dialog.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _expandCategoryStats = false;
  bool _expandRecentActivity = false;

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 25),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondayColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 30),
              ),
              const SizedBox(height: 16),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryStats(List<Map<String, dynamic>> categoryData) {
    final totalQuizzes = categoryData.fold<int>(
      0,
      (sum, item) => sum + (item['count'] as int),
    );

    final displayData = _expandCategoryStats
        ? categoryData
        : categoryData.take(3).toList();

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayData.length,
          itemBuilder: (context, index) {
            final category = displayData[index];
            final count = category['count'] as int;
            final percentage = totalQuizzes > 0
                ? (count / totalQuizzes) * 100
                : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category['name'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "$count ${count == 1 ? 'quiz' : 'quizzes'}",
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondayColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        if (categoryData.length > 3)
          TextButton(
            onPressed: () {
              setState(() => _expandCategoryStats = !_expandCategoryStats);
            },
            child: Text(
              _expandCategoryStats ? "Show Less" : "Show More",
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              color: Colors.transparent,
              padding: const EdgeInsets.only(
                top: 50,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/feedback.png',
                    fit: BoxFit.contain,
                    height: 80,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'ITS Reviewer App',
                    style: TextStyle(
                      fontSize: 20,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => const ConfirmDialog(
                    title: "Logout",
                    message: "Are you sure you want to log out?",
                    confirmText: "Logout",
                    cancelText: "Cancel",
                    confirmColor: Colors.red,
                  ),
                );

                if (shouldLogout == true) {
                  final _authService = AuthService();
                  await _authService.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed('/login');
                  }
                }
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('categories').snapshots(),
        builder: (context, categorySnapshot) {
          if (!categorySnapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }
          final categories = categorySnapshot.data!.docs;

          return StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('quizzes').snapshots(),
            builder: (context, quizSnapshot) {
              if (!quizSnapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                  ),
                );
              }
              final quizzes = quizSnapshot.data!.docs;

              // Category statistics
              final categoryData = categories.map((categoryDoc) {
                final quizCount = quizzes
                    .where((quizDoc) => quizDoc['categoryId'] == categoryDoc.id)
                    .length;
                return {'name': categoryDoc['name'], 'count': quizCount};
              }).toList();

              final totalCategories = categories.length;
              final totalQuizzes = quizzes.length;
              final latestQuizzes = quizzes.map((doc) => doc).toList()
                ..sort((a, b) => b['createdAt'].compareTo(a['createdAt']));

              return SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome Admin",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Here's your quiz application overview",
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondayColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Total Categories',
                              totalCategories.toString(),
                              Icons.category_rounded,
                              AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'Total Quizzes',
                              totalQuizzes.toString(),
                              Icons.quiz_rounded,
                              AppTheme.secondaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.pie_chart_rounded,
                                    color: AppTheme.primaryColor,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Category Statistics',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _buildCategoryStats(categoryData),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Recent Activity
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.history_outlined,
                                    color: AppTheme.primaryColor,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Recent Activity',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _expandRecentActivity
                                    ? latestQuizzes.length
                                    : latestQuizzes.take(3).length,
                                itemBuilder: (context, index) {
                                  final quiz =
                                      latestQuizzes[index].data()
                                          as Map<String, dynamic>;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.quiz_rounded,
                                            color: AppTheme.primaryColor,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                quiz['title'],
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      AppTheme.textPrimaryColor,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Created on ${_formatDate(quiz['createdAt'].toDate())}',
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              if (latestQuizzes.length > 3)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton(
                                    onPressed: () {
                                      setState(
                                        () => _expandRecentActivity =
                                            !_expandRecentActivity,
                                      );
                                    },
                                    child: Text(
                                      _expandRecentActivity
                                          ? "Show Less"
                                          : "Show More",
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Quiz Actions
                      Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.speed_rounded,
                                    color: AppTheme.primaryColor,
                                    size: 26,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Quiz Actions',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 0.85,
                                children: [
                                  _buildDashboardCard(
                                    context,
                                    'Quizzes',
                                    Icons.quiz_rounded,
                                    () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const ManageQuizesScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildDashboardCard(
                                    context,
                                    'Categories',
                                    Icons.category_rounded,
                                    () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const ManageCategoriesScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
