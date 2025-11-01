// lib/features/authentication/wrapper.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doanmobile/data/services/auth_service.dart';
import 'package:doanmobile/features/admin_flow/admin_dashboard/admin_dashboard_screen.dart';
import 'package:doanmobile/features/authentication/banned_screen.dart';
import 'package:doanmobile/features/authentication/screens/login_screen.dart';
import 'package:doanmobile/features/seller_flow/dashboard/seller_dashboard_screen.dart';
import 'package:doanmobile/features/user_flow/home/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<User?>(
      stream: authService.user,
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (userSnapshot.hasData) {
          return FutureBuilder<DocumentSnapshot?>(
            future: authService.getCurrentUserDetails(),
            builder: (context, detailsSnapshot) {
              if (detailsSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                    body: Center(child: CircularProgressIndicator()));
              }

              if (detailsSnapshot.hasData &&
                  (detailsSnapshot.data?.exists ?? false)) {
               
                final userData =
                    detailsSnapshot.data!.data() as Map<String, dynamic>?;
                final role = userData?['role'];
                final status = userData?['status'] ?? 'active';

                if (status == 'banned') {
                  return const BannedScreen();
                }

                switch (role) {
                  case 'admin':
                    return const AdminDashboardScreen();
                  case 'seller':
                    return const SellerDashboardScreen();
                  default:
                    return const HomeScreen();
                }
              }

              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 60),
                      const SizedBox(height: 16),
                      const Text(
                        'Không tìm thấy thông tin người dùng trên hệ thống.',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => authService.signOut(),
                        child: const Text('Đăng xuất'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}

