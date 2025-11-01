// lib/features/authentication/banned_screen.dart

import 'package:doanmobile/data/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BannedScreen extends StatelessWidget {
  const BannedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block_flipped, color: Colors.red, size: 80),
              const SizedBox(height: 20),
              const Text(
                'Tài khoản của bạn đã bị cấm',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Vui lòng liên hệ quản trị viên để biết thêm chi tiết.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  foregroundColor: Colors.white,
                ),
                onPressed: () => authService.signOut(),
                child: const Text('Đăng xuất'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}