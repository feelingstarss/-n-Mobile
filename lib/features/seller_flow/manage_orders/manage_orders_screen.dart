import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doanmobile/data/services/auth_service.dart';
import 'package:doanmobile/data/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ManageOrdersScreen extends StatelessWidget {
  ManageOrdersScreen({super.key});

  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final String? sellerId = authService.currentUserId;

    debugPrint("=== DEBUG ManageOrders: SellerId = $sellerId");  // Debug sellerId

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn hàng của bạn'),
      ),
      body: sellerId == null
          ? const Center(child: Text("Không thể xác thực người bán."))
          : StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getOrdersBySeller(sellerId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint("=== DEBUG ManageOrders Error: ${snapshot.error}");  // Debug lỗi
                  return const Center(
                      child: Text('Đã xảy ra lỗi khi tải đơn hàng.'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.docs.isEmpty) {
                  debugPrint("=== DEBUG ManageOrders: No orders found for seller $sellerId");
                  return const Center(child: Text('Bạn chưa có đơn hàng nào.'));
                }

                final orders = snapshot.data!.docs;
                debugPrint("=== DEBUG ManageOrders: Loaded ${orders.length} orders");

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final orderDoc = orders[index];
                    final orderData = orderDoc.data() as Map<String, dynamic>;

                    final String currentStatus = orderData['status'] ?? 'pending';

                    return FutureBuilder<List<Map<String, dynamic>>>(
                      future: _firestoreService.getSellerProductsInOrder(orderDoc.id, sellerId),
                      builder: (context, productSnapshot) {
                        if (productSnapshot.hasError) {
                          debugPrint("=== DEBUG ManageOrders Future Error: ${productSnapshot.error}");  // Debug lỗi Future
                          return const SizedBox.shrink();
                        }
                        if (productSnapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox.shrink();
                        }
                        if (!productSnapshot.hasData || productSnapshot.data!.isEmpty) {
                          debugPrint("=== DEBUG ManageOrders: No seller products in order ${orderDoc.id}");
                          return const SizedBox();  // Bỏ qua nếu không có sản phẩm của seller
                        }

                        final sellerProducts = productSnapshot.data!;
                        debugPrint("=== DEBUG ManageOrders: Found ${sellerProducts.length} seller products in ${orderDoc.id}");
                        final productList = sellerProducts
                            .map((p) => "• ${p['productName']} (x${p['quantity']}) - ${p['price']} đ")
                            .join('\n');
                        final double totalSellerAmount = sellerProducts.fold(
                          0.0,
                          (acc, p) => acc + (p['price'] as num).toDouble() * (p['quantity'] as num).toDouble(),
                        );

                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Đơn hàng #${orderDoc.id.substring(0, 6).toUpperCase()}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const Divider(),
                                Text('Sản phẩm của bạn:\n$productList'),
                                const SizedBox(height: 8),
                                Text(
                                    'Tổng tiền của bạn: ${totalSellerAmount.toStringAsFixed(0)} đ'),
                                const SizedBox(height: 8),
                                Text('Khách hàng ID: ${orderData['userId']}'),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Trạng thái:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    DropdownButton<String>(
                                      value: currentStatus,
                                      items: const [
                                        DropdownMenuItem(
                                            value: 'pending', child: Text('Chờ xử lý')),
                                        DropdownMenuItem(
                                            value: 'processing', child: Text('Đang xử lý')),
                                        DropdownMenuItem(
                                            value: 'shipped', child: Text('Đang giao')),
                                        DropdownMenuItem(
                                            value: 'delivered', child: Text('Đã giao')),
                                        DropdownMenuItem(
                                            value: 'cancelled', child: Text('Đã hủy')),
                                      ],
                                      onChanged: (String? newStatus) {
                                        if (newStatus != null &&
                                            newStatus != currentStatus) {
                                          _firestoreService.updateOrderStatus(
                                              orderDoc.id, newStatus);
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
                );
              },
            ),
    );
  }
}