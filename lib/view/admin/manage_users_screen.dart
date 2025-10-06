import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:itsreviewer_app/theme/theme.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _deleteUser(String uid) async {
    try {
      // Delete from Firestore
      await _firestore.collection('users').doc(uid).delete();

      // Note: Client apps can only delete the current logged-in user from Auth.
      // For real admin deletion of any user, use Firebase Admin SDK in Cloud Functions.

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete user: $e')));
    }
  }

  Future<void> _toggleUserStatus(String uid, bool isDisabled) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'disabled': !isDisabled,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isDisabled ? 'User enabled' : 'User disabled')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update user: $e')));
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown';
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
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No users found.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userDoc = users[index];
              final data = userDoc.data() as Map<String, dynamic>;
              final uid = userDoc.id;

              final name = data['name'] ?? 'Unnamed';
              final email = data['email'] ?? 'No email';
              final role = data['role'] ?? 'N/A';
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
                        'Role: $role • Joined: $createdAt',
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
                        child: Text(disabled ? 'Enable User' : 'Disable User'),
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
    );
  }
}
