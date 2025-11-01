// lib/features/user_flow/product_details/product_details_screen.dart

import 'dart:convert'; // <-- Import để dùng base64Decode
import 'dart:typed_data'; // <-- Import để dùng Uint8List
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doanmobile/data/services/auth_service.dart';
import 'package:doanmobile/data/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:provider/provider.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;
  const ProductDetailsScreen({super.key, required this.productId});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String? _selectedSize;
  int _currentImageIndex = 0;

  // Biến để lưu trữ Future, tránh gọi lại trong build()
  late Future<DocumentSnapshot> _productDetailsFuture;

  @override
  void initState() {
    super.initState();
    // Gọi Future MỘT LẦN duy nhất khi màn hình được khởi tạo
    _productDetailsFuture =
        _firestoreService.getProductDetails(widget.productId);
  }

  // Lấy danh sách các size còn hàng
  List<String> _getAvailableSizes(List<dynamic> variants) {
    return variants
        .where((v) => v['stock'] > 0)
        .map<String>((v) => v['size'])
        .toSet()
        .toList();
  }

  // Tìm số lượng tồn kho của size đã chọn
  int _getSelectedVariantStock(List<dynamic> variants) {
    if (_selectedSize == null) return 0;
    final variant = variants.firstWhere(
      (v) => v['size'] == _selectedSize,
      orElse: () => null,
    );
    return variant != null ? (variant['stock'] as int) : 0;
  }
  
  // Hàm tiện ích để hiển thị lỗi ảnh
  Widget _buildErrorPlaceholder(String error) {
    print("LỖI HIỂN THỊ ẢNH: $error");
    return Container(
      color: Colors.grey[200],
      child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết sản phẩm'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _productDetailsFuture, // <-- SỬ DỤNG FUTURE ĐÃ LƯU
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data?.data() == null) {
            return const Center(child: Text('Lỗi: Không thể tải sản phẩm.'));
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;
          List<dynamic> variants = data['variants'] ?? [];
          List<String> imageUrls = List<String>.from(data['imageUrls'] ?? []);
          List<String> availableSizes = _getAvailableSizes(variants);
          int currentStock = _getSelectedVariantStock(variants);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image gallery
                if (imageUrls.isNotEmpty)
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.45,
                        child: PageView.builder(
                          itemCount: imageUrls.length,
                          onPageChanged: (index) =>
                              setState(() => _currentImageIndex = index),
                          
                          // --- CODE ĐÃ SỬA ĐỂ ĐỌC BASE64 ---
                          itemBuilder: (context, index) {
                            final imageDataString = imageUrls[index];

                            // 1. KIỂM TRA NẾU LÀ BASE64
                            if (imageDataString.startsWith('data:image')) {
                              try {
                                // Tách chuỗi "data:image/png;base64,ABC..."
                                final parts = imageDataString.split(',');
                                if (parts.length != 2) {
                                  return _buildErrorPlaceholder("Data URI không hợp lệ");
                                }
                                // Lấy phần dữ liệu Base64
                                final base64Data = parts[1];
                                
                                // Giải mã Base64 thành bytes
                                final Uint8List imageBytes = base64Decode(base64Data);

                                // Dùng Image.memory để hiển thị
                                return Image.memory(
                                  imageBytes,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) =>
                                      _buildErrorPlaceholder("Lỗi giải mã Base64: $e"),
                                );
                              } catch (e) {
                                return _buildErrorPlaceholder("Lỗi Base64: $e");
                              }
                            }
                            // 2. KIỂM TRA NẾU LÀ URL (cho các ảnh cũ)
                            else if (imageDataString.startsWith('http')) {
                              return Image.network(
                                imageDataString,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) =>
                                    _buildErrorPlaceholder("Lỗi tải URL: $e"),
                              );
                            }
                            // 3. NẾU KHÔNG PHẢI CẢ HAI
                            else {
                              return _buildErrorPlaceholder("Định dạng ảnh không được hỗ trợ");
                            }
                          },
                          // --- KẾT THÚC SỬA ---
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: imageUrls.map((url) {
                            int index = imageUrls.indexOf(url);
                            return Container(
                              width: 8.0,
                              height: 8.0,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentImageIndex == index
                                    ? Colors.white
                                    : Colors.white.withAlpha(150),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),

                // Product info
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['sellerName'] ?? 'Thương hiệu',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(data['productName'] ?? 'Tên sản phẩm',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text('${data['price']} đ',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor)),
                      const Divider(height: 30),

                      // Size selector
                      _buildOptionSelector(
                        title: 'Size:',
                        options: availableSizes,
                        selectedValue: _selectedSize,
                        onSelected: (value) =>
                            setState(() => _selectedSize = value),
                      ),

                      // Display stock quantity
                      if (_selectedSize != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            currentStock > 0
                                ? 'Còn lại: $currentStock'
                                : 'Hết hàng',
                            style: TextStyle(
                                color: currentStock > 0
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold),
                          ),
                        ),

                      // Description
                      ExpansionTile(
                        title: const Text('Mô tả sản phẩm',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child:
                                Text(data['description'] ?? 'Không có mô tả.'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: FutureBuilder<DocumentSnapshot>(
            future: _productDetailsFuture, // <-- SỬ DỤNG FUTURE ĐÃ LƯU
            builder: (context, snapshot) {
              // Ensure the document exists and has data before casting.
              final docData = snapshot.data?.data() as Map<String, dynamic>?;
              if (docData == null) return const SizedBox(height: 50);

              List<dynamic> variants =
                  List<dynamic>.from(docData['variants'] ?? []);
              int stock = _getSelectedVariantStock(variants);
              bool canAddToCart = _selectedSize != null && stock > 0;

              return ElevatedButton.icon(
                icon: const Icon(Icons.add_shopping_cart_outlined),
                label: Text(canAddToCart
                    ? 'Thêm vào giỏ hàng'
                    : (_selectedSize == null
                        ? 'Vui lòng chọn Size'
                        : 'Hết hàng')),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: canAddToCart ? Colors.black : Colors.grey,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: canAddToCart
                    ? () async {
                        final userId = authService.currentUserId;
                        if (userId != null) {
                          try {
                            await _firestoreService.addToCart(
                              userId: userId,
                              productId: widget.productId,
                              size: _selectedSize!,
                            );
                            if (context.mounted) {
                              await Flushbar(
                                message: 'Đã thêm vào giỏ hàng!',
                                duration: const Duration(seconds: 2),
                              ).show(context);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              await Flushbar(
                                message:
                                    'Thêm vào giỏ thất bại: ${e.toString()}',
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 3),
                              ).show(context);
                            }
                          }
                        }
                      }
                    : null,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOptionSelector(
      {required String title,
      required List<String> options,
      required String? selectedValue,
      required ValueChanged<String> onSelected}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (options.isEmpty)
          const Text('Không có tùy chọn', style: TextStyle(color: Colors.grey))
        else
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: options.map((option) {
              final isSelected = selectedValue == option;
              return ChoiceChip(
                label: Text(option),
                selected: isSelected,
                onSelected: (selected) => onSelected(option),
                selectedColor: Colors.black,
                labelStyle:
                    TextStyle(color: isSelected ? Colors.white : Colors.black),
                backgroundColor: Colors.grey[200],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                      color: isSelected ? Colors.black : Colors.grey[400]!),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}