// lib/features/admin_flow/manage_users/manage_users_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doanmobile/data/services/firestore_service.dart';
import 'package:flutter/material.dart';

class ManageUsersScreen extends StatelessWidget {
  ManageUsersScreen({super.key});
  
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý người dùng'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getAllUsersStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Đã xảy ra lỗi'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var users = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: users.length,
            itemBuilder: (context, index) {
              var userData = users[index].data() as Map<String, dynamic>;
              String userId = users[index].id;
              String currentRole = userData['role'] ?? 'user';
              String currentStatus = userData['status'] ?? 'active';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userData['displayName'] ?? 'N/A', 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                      Text(userData['email'] ?? 'N/A'),
                      const Divider(height: 15, thickness: 1),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                    
                          DropdownButton<String>(
                            value: currentRole,
                            items: ['user', 'seller', 'admin']
                                .map((v) => DropdownMenuItem(
                                      value: v,
                                      child: Text(v.toUpperCase()),
                                    ))
                                .toList(),
                            onChanged: (newRole) {
                              if (newRole != null && newRole != currentRole) {
                                _firestoreService.updateUserRole(userId, newRole);
                              }
                            },
                          ),
                 
                          DropdownButton<String>(
                            value: currentStatus,
                            items: ['active', 'restricted', 'banned']
                                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                                .toList(),
                            onChanged: (newStatus) {
                              if (newStatus != null) {
                                _firestoreService.updateUserStatus(userId, newStatus);
                              }
                            },
                          ),
                        ],
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


