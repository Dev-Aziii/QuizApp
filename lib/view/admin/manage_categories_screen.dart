import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:itsreviewer_app/model/category.dart';
import 'package:itsreviewer_app/theme/theme.dart';
import 'package:itsreviewer_app/view/admin/add_category_screen.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Categories"),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddCategoryScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                fillColor: Colors.white,
                hintText: "Search Categories",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('categories')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error"));
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final categories = snapshot.data!.docs
                    .map(
                      (doc) => Category.fromMap(
                        doc.id,
                        doc.data() as Map<String, dynamic>,
                      ),
                    )
                    .where(
                      (cat) =>
                          _searchQuery.isEmpty ||
                          cat.name.toLowerCase().contains(_searchQuery),
                    )
                    .toList();

                if (categories.isEmpty) {
                  return Center(child: Text("No categories found"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final Category category = categories[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(
                          category.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(category.description),
                        trailing: PopupMenuButton(
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                leading: Icon(
                                  Icons.edit,
                                  color: AppTheme.primaryColor,
                                ),
                                title: Text("Edit"),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                                title: Text("Delete"),
                              ),
                            ),
                          ],
                          onSelected: (value) =>
                              _handleCategoryAction(context, value, category),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCategoryAction(
    BuildContext context,
    String value,
    Category category,
  ) async {
    if (value == "edit") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddCategoryScreen(category: category),
        ),
      );
    } else if (value == "delete") {
      final TextEditingController confirmController = TextEditingController();
      bool isDeleteEnabled = false;

      await showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Delete Category"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Type the category name to confirm deletion."),
                  SizedBox(height: 8),
                  TextField(
                    controller: confirmController,
                    decoration: InputDecoration(
                      hintText: "Category name",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (text) {
                      setDialogState(() {
                        isDeleteEnabled = text.trim() == category.name;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: isDeleteEnabled
                      ? () async {
                          // Delete all quizzes under this category
                          final quizzes = await _firestore
                              .collection('quizzes')
                              .where('categoryId', isEqualTo: category.id)
                              .get();

                          for (var quizDoc in quizzes.docs) {
                            await _firestore
                                .collection('quizzes')
                                .doc(quizDoc.id)
                                .delete();
                          }

                          // Delete the category itself
                          await _firestore
                              .collection('categories')
                              .doc(category.id)
                              .delete();

                          Navigator.pop(context);
                        }
                      : null,
                  child: Text(
                    "Delete",
                    style: TextStyle(
                      color: isDeleteEnabled ? Colors.redAccent : Colors.grey,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }
  }
}
