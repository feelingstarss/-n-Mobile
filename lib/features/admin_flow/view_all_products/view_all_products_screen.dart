// lib/features/admin_flow/view_all_products/view_all_products_screen.dart

import 'dart:convert'; 
import 'dart:typed_data'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doanmobile/data/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';

class ViewAllProductsScreen extends StatefulWidget {
  const ViewAllProductsScreen({super.key});

  @override
  State<ViewAllProductsScreen> createState() => _ViewAllProductsScreenState();
}

class _ViewAllProductsScreenState extends State<ViewAllProductsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDeleteConfirmation(
      BuildContext context, String productId, String productName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận Xóa'),
        content: Text('Bạn có chắc chắn muốn xóa sản phẩm "$productName"?'),
        actions: [
          TextButton(
              child: const Text('Hủy'),
              onPressed: () => Navigator.of(ctx).pop()),
          TextButton(
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await _firestoreService.deleteProduct(productId);
                if (context.mounted) {
                  await Flushbar(
                          message: 'Đã xóa sản phẩm',
                          duration: const Duration(seconds: 2))
                      .show(context);
                }
              } catch (e) {
                if (context.mounted) {
                  await Flushbar(
                          message: 'Xóa thất bại: ${e.toString()}',
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 3))
                      .show(context);
                }
              }
            },
          ),
        ],
      ),
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
        print("Lỗi giải mã Base64 (ViewAll): $e");
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tất cả Sản phẩm'),
      ),
      body: Column(
        children: [
         
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Tìm theo tên sản phẩm hoặc tên shop...',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
       
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestoreService
                  .searchAllProducts(_searchQuery), // Dùng hàm tìm kiếm mới
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Đã xảy ra lỗi'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('Không tìm thấy sản phẩm nào.'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    
                    String firstImage = (data['imageUrls'] as List).isNotEmpty
                        ? data['imageUrls'][0]
                        : '';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: _buildImageWidget(firstImage),
                        title: Text(data['productName']),
                        subtitle: Text('Shop: ${data['sellerName'] ?? 'Không rõ tên'}'), 
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_forever,
                              color: Colors.red),
                          tooltip: 'Xóa sản phẩm',
                          onPressed: () => _showDeleteConfirmation(
                              context, doc.id, data['productName']),
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
