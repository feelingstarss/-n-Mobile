// lib/features/seller_flow/manage_products/manage_products_screen.dart

import 'dart:convert'; 
import 'dart:typed_data'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doanmobile/data/models/product_model.dart';
import 'package:doanmobile/data/services/auth_service.dart';
import 'package:doanmobile/data/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:another_flushbar/flushbar.dart';
import 'add_edit_product_screen.dart';

class ManageProductsScreen extends StatelessWidget {
  ManageProductsScreen({super.key});

  final FirestoreService _firestoreService = FirestoreService();

  void _showDeleteConfirmation(
      BuildContext context, String productId, String productName) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Xác nhận Xóa'),
          content: Text('Bạn có chắc chắn muốn xóa sản phẩm "$productName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(), 
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop(); 
                try {
                  await _firestoreService.deleteProduct(productId);
                  if (context.mounted) {
                    await Flushbar(
                      message: 'Đã xóa sản phẩm',
                      duration: const Duration(seconds: 2),
                    ).show(context);
                  }
                } catch (e) {
                  if (context.mounted) {
                    await Flushbar(
                      message: 'Xóa thất bại: ${e.toString()}',
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ).show(context);
                  }
                }
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }


  Widget _buildErrorPlaceholder() {
    return Container(
      width: 50,
      height: 50,
      color: Colors.grey[200],
      child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
    );
  }

 
  Widget _buildImageWidget(String imageDataString) {
    if (imageDataString.isEmpty) {
      return _buildErrorPlaceholder();
    }
    

    if (imageDataString.startsWith('data:image')) {
      try {
        final parts = imageDataString.split(',');
        if (parts.length != 2) throw Exception('Invalid data URI');
        
        final Uint8List imageBytes = base64Decode(parts[1]); 
        
        return Image.memory(
          imageBytes,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => _buildErrorPlaceholder(),
        );
      } catch (e) {
        print("Lỗi giải mã Base64 (ManageProducts): $e");
        return _buildErrorPlaceholder();
      }
    }

 
    if (imageDataString.startsWith('http')) {
      return Image.network(
        imageDataString,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => _buildErrorPlaceholder(),
      );
    }


    return _buildErrorPlaceholder();
  }
  

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final String? sellerId = authService.currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý sản phẩm'),
      ),
      body: sellerId == null
          ? const Center(child: Text("Không tìm thấy thông tin người bán."))
          : StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getProductsStreamBySeller(sellerId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Lỗi tải dữ liệu'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Bạn chưa có sản phẩm nào.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    ProductModel product = ProductModel.fromFirestore(doc);

                    
                    String firstImage = product.imageUrls.isNotEmpty
                        ? product.imageUrls.first
                        : '';

                    return Card(
                      child: ListTile(
                       
                        leading: _buildImageWidget(firstImage),
                      
                        title: Text(product.productName),
                        subtitle:
                            Text('${product.price} đ - Kho: ${product.stock}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                              
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          AddEditProductScreen(
                                              product: product)),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _showDeleteConfirmation(
                                    context, doc.id, product.productName);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddEditProductScreen(),
            ),
          );
        },
        tooltip: 'Thêm sản phẩm mới',
        child: const Icon(Icons.add),
      ),
    );
  }

}
