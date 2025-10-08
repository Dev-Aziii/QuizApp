import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:itsreviewer_app/theme/theme.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  bool _showDisabledOnly = false;

  final TextEditingController _searchController = TextEditingController();

  Future<void> _deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete user: $e')));
      }
    }
  }

  Future<void> _toggleUserStatus(String uid, bool isDisabled) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'disabled': !isDisabled,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isDisabled ? 'User enabled' : 'User disabled'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update user: $e')));
      }
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is! Timestamp) return 'Unknown';
    final date = timestamp.toDate();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Search by name or email...',
                      hintStyle: const TextStyle(color: Colors.black54),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.black54,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.black12,
                          width: 1,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim().toLowerCase();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),

                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showDisabledOnly = !_showDisabledOnly;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _showDisabledOnly
                          ? Colors.redAccent
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _showDisabledOnly
                            ? Colors.redAccent
                            : Colors.grey.shade400,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _showDisabledOnly
                              ? Icons.visibility_off
                              : Icons.person,
                          color: _showDisabledOnly
                              ? Colors.white
                              : Colors.black87,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _showDisabledOnly ? "Disabled" : "All",
                          style: TextStyle(
                            color: _showDisabledOnly
                                ? Colors.white
                                : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .where('role', isEqualTo: 'user')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No users found.',
                      style: TextStyle(color: Colors.black54, fontSize: 16),
                    ),
                  );
                }

                // ✅ Apply filtering in Flutter instead of Firestore
                final users = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  final disabled =
                      data['disabled'] ?? false; // Default false if missing

                  final matchesDisabled = _showDisabledOnly
                      ? disabled == true
                      : disabled == false;
                  final matchesSearch =
                      _searchQuery.isEmpty ||
                      name.contains(_searchQuery) ||
                      email.contains(_searchQuery);

                  return matchesDisabled && matchesSearch;
                }).toList();

                if (users.isEmpty) {
                  return Center(
                    child: Text(
                      _showDisabledOnly
                          ? 'No disabled users found.'
                          : 'No active users found.',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                // 🧱 Same ListView builder as before
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userDoc = users[index];
                    final data = userDoc.data() as Map<String, dynamic>? ?? {};
                    final uid = userDoc.id;

                    final name = data['name'] ?? 'Unnamed';
                    final email = data['email'] ?? 'No email';
                    final disabled = data['disabled'] ?? false;
                    final createdAt = _formatTimestamp(data['createdAt']);

                    return Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: disabled
                              ? Colors.grey
                              : AppTheme.secondaryColor.withOpacity(0.9),
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(
                          name,
                          style: TextStyle(
                            color: AppTheme.textPrimaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(email, style: const TextStyle(fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(
                              'Joined: $createdAt',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'disable') {
                              await _toggleUserStatus(uid, disabled);
                            } else if (value == 'delete') {
                              await _deleteUser(uid);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'disable',
                              child: Text(
                                disabled ? 'Enable User' : 'Disable User',
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete User'),
                            ),
                          ],
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
}
