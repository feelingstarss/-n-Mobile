import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doanmobile/data/services/auth_service.dart';
import 'package:doanmobile/data/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final String? userId = authService.currentUserId;
    final firestoreService = FirestoreService();

    debugPrint("=== DEBUG OrderHistory: UserId = $userId"); 

    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử đơn hàng')),
      body: userId == null
          ? const Center(child: Text('Vui lòng đăng nhập để xem lịch sử.'))
          : StreamBuilder<QuerySnapshot>(
              stream: firestoreService.getOrdersByUser(userId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint("=== DEBUG OrderHistory Error: ${snapshot.error}");  
                  return Center(child: Text('Lỗi tải đơn hàng: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.docs.isEmpty) {
                  debugPrint("=== DEBUG OrderHistory: No orders found for user $userId");
                  return const Center(child: Text('Bạn chưa có đơn hàng nào.'));
                }

                final orders = snapshot.data!.docs;
                debugPrint("=== DEBUG OrderHistory: Loaded ${orders.length} orders");

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final orderDoc = orders[index];
                    final orderData = orderDoc.data() as Map<String, dynamic>;

                    final String orderId = orderDoc.id.substring(0, 6).toUpperCase();
                    final String status = orderData['status'] ?? 'pending';
                    final List<dynamic> items = orderData['items'] ?? [];
                    final List<dynamic> sellerNames = orderData['sellerNames'] ?? [];

                    final productList = items
                        .map((item) =>
                            "• ${item['productName']} (x${item['quantity']}) - ${item['price']} đ")
                        .join('\n');

                    final sellerList = sellerNames.isNotEmpty
                        ? sellerNames.join(', ')
                        : "Không xác định";

                    final double totalAmount =
                        (orderData['totalAmount'] ?? 0).toDouble();

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        title: Text(
                          'Đơn hàng #$orderId',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Tổng: ${totalAmount.toStringAsFixed(0)} đ\n'
                          'Trạng thái: ${_translateStatus(status)}',
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sản phẩm:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(height: 4),
                                Text(productList),
                                const SizedBox(height: 10),
                                Text('Người bán: $sellerList'),
                                const SizedBox(height: 10),
                                Text(
                                  'Tổng cộng: ${totalAmount.toStringAsFixed(0)} đ',
                                  style:
                                      const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ xử lý';
      case 'processing':
        return 'Đang xử lý';
      case 'shipped':
        return 'Đang giao';
      case 'delivered':
        return 'Đã giao';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

}
