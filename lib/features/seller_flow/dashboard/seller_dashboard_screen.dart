// lib/features/seller_flow/dashboard/seller_dashboard_screen.dart

import 'package:doanmobile/data/services/auth_service.dart';
import 'package:doanmobile/features/authentication/screens/edit_profile_screen.dart';
import 'package:doanmobile/features/seller_flow/manage_orders/manage_orders_screen.dart';
import 'package:doanmobile/features/seller_flow/manage_products/manage_products_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SellerDashboardScreen extends StatelessWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng điều khiển của Người bán'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () => authService.signOut(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.storefront, color: Colors.blue),
              title: const Text('Quản lý Sản phẩm'),
              subtitle: const Text('Thêm, sửa, xóa sản phẩm của bạn'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ManageProductsScreen()),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.receipt_long, color: Colors.green),
              title: const Text('Quản lý Đơn hàng'),
              subtitle: const Text('Xem các đơn hàng bạn đã nhận'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ManageOrdersScreen()),
                );
              },
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.account_circle, color: Colors.purple),
              title: const Text('Thông tin cá nhân & Ngân hàng'),
              subtitle: const Text('Cập nhật tên shop, tài khoản nhận tiền...'),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const EditProfileScreen()));
              },
            ),
          ),
        ],
      ),
    );
  }

}
