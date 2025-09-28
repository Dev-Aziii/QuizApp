import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:itsreviewer_app/model/category.dart';
import 'package:itsreviewer_app/theme/theme.dart';
import 'dart:developer';

class AddCategoryScreen extends StatefulWidget {
  final Category? category;
  const AddCategoryScreen({super.key, this.category});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill controllers if editing existing category
    _nameController = TextEditingController(text: widget.category?.name);
    _descriptionController = TextEditingController(
      text: widget.category?.description,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Save or update category in Firestore
  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) {
      return; // Stop if form is invalid
    }
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.category != null) {
        // ✅ Update existing category
        final updatedCategory = widget.category!.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
        );

        await _firestore
            .collection("categories")
            .doc(widget.category!.id)
            .update(updatedCategory.toMap());

        if (!mounted) return; // prevent context issues
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Category updated successfully")),
        );
      } else {
        // ✅ Add new category
        final newId = _firestore.collection("categories").doc().id;

        await _firestore
            .collection("categories")
            .doc(newId)
            .set(
              Category(
                id: newId,
                name: _nameController.text.trim(),
                description: _descriptionController.text.trim(),
                createdAt: DateTime.now(),
              ).toMap(),
            );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Category added successfully")),
        );
      }

      Navigator.pop(context);
    } catch (e, stack) {
      log("Error adding/updating category", error: e, stackTrace: stack);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Ask confirmation before discarding changes
  Future<bool> _onWillPop() async {
    if (_nameController.text.isNotEmpty ||
        _descriptionController.text.isNotEmpty) {
      // Show discard confirmation dialog
      final discard =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Discard Changes"),
              content: const Text("Are you sure you want to discard changes?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    'Discard',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          ) ??
          false;
      return discard;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop = await _onWillPop();
        if (context.mounted && shouldPop) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.backgroundColor,
          title: Text(
            widget.category != null ? "Edit Category" : "Add Category",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Category Details",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Create a new category for organizing your quizzes",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondayColor,
                    ),
                  ),
                  const SizedBox(height: 24),

                  /// Category name input
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(vertical: 20),
                      fillColor: Colors.white,
                      labelText: "Category Name",
                      hintText: "Enter Category Name",
                      prefixIcon: Icon(
                        Icons.category_outlined,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? "Enter Category Name" : null,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 20),

                  /// Description input
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      fillColor: Colors.white,
                      labelText: "Description",
                      hintText: "Enter Description",
                      prefixIcon: Icon(
                        Icons.description_outlined,
                        color: AppTheme.primaryColor,
                      ),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                    validator: (value) =>
                        value!.isEmpty ? "Enter Description" : null,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 32),

                  /// Save button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveCategory,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              widget.category != null
                                  ? "Update Category"
                                  : "Add Category",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
