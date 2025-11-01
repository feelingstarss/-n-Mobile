// lib/features/admin_flow/admin_dashboard/admin_dashboard_screen.dart

import 'package:doanmobile/data/services/auth_service.dart';
import 'package:doanmobile/features/admin_flow/manage_users/manage_users_screen.dart';
import 'package:doanmobile/features/admin_flow/view_all_products/view_all_products_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng điều khiển của Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authService.signOut(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.people, color: Colors.purple),
              title: const Text('Quản lý Người dùng'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ManageUsersScreen()),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.shopping_bag, color: Colors.teal),
              title: const Text('Quản lý Tất cả Sản phẩm'),
              subtitle: const Text('Xem hoặc gỡ bỏ sản phẩm vi phạm'),
              onTap: () {
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ViewAllProductsScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


