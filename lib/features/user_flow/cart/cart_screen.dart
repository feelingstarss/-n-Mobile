import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doanmobile/data/services/auth_service.dart';
import 'package:doanmobile/data/services/firestore_service.dart';
import 'package:doanmobile/features/user_flow/checkout/checkout_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final ValueNotifier<Set<String>> _selectedProductIds = ValueNotifier({});
  final Map<String, int> _quantities = {}; 

  late Stream<List<Map<String, dynamic>>> _cartItemsStream;
  final Map<String, Map<String, dynamic>> _productDetailsCache = {};
  String? _userId;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _userId = authService.currentUserId;

    if (_userId != null) {
      _cartItemsStream = _firestoreService.getCartStream(_userId!)
          .asyncMap(_fetchCartDetails)
          .asBroadcastStream();
    } else {
      _cartItemsStream = Stream.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Scaffold(
        body: Center(child: Text("Vui lòng đăng nhập để xem giỏ hàng.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Giỏ hàng của bạn')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _cartItemsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Đã xảy ra lỗi khi tải giỏ hàng.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('Giỏ hàng của bạn đang trống.'));
          }

          for (var item in items) {
            _quantities[item['cartItemId']] ??= item['quantity'];
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final cartItemId = item['cartItemId'] as String;
                    final stock = item['stock'] as int? ?? 100;
                    final quantity = _quantities[cartItemId] ?? item['quantity'];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ValueListenableBuilder<Set<String>>(
                              valueListenable: _selectedProductIds,
                              builder: (context, selectedIds, _) {
                                final isSelected =
                                    selectedIds.contains(cartItemId);
                                return Checkbox(
                                  value: isSelected,
                                  onChanged: (checked) {
                                    final newSet =
                                        Set<String>.from(selectedIds);
                                    if (checked == true) {
                                      newSet.add(cartItemId);
                                    } else {
                                      newSet.remove(cartItemId);
                                    }
                                    _selectedProductIds.value = newSet;
                                  },
                                );
                              },
                            ),

                         
                            Builder(builder: (context) {
                              final imageUrl = item['imageUrl'] as String;
                       
                              final bool isValidUrl = imageUrl.startsWith('http');

                              if (isValidUrl) {
                                return Image.network(
                                  imageUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                
                                    return Container(
                                      width: 50,
                                      height: 50,
                                      color: Colors.grey[200],
                                      child: Icon(Icons.broken_image,
                                          color: Colors.grey[400]),
                                    );
                                  },
                                );
                              } else {
                              
                                return Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey[200],
                                  child: Icon(Icons.image_not_supported,
                                      color: Colors.grey[400]),
                                );
                              }
                            }),
                       
                          ],
                        ),
                        title: Text(item['productName']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Giá: ${_formatCurrency(item['price'])}'),
                            Text('Kho còn: $stock'),

                           
                            Row(
                              mainAxisSize: MainAxisSize.min, 
                              children: [
                                IconButton(
                                  padding: EdgeInsets.zero, 
                                  constraints: const BoxConstraints(), 
                                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                                  onPressed: quantity > 1
                                      ? () async {
                                          final newQty = quantity - 1;
                                          setState(() =>
                                              _quantities[cartItemId] = newQty);
                                          await _firestoreService
                                              .updateCartQuantity(
                                                  _userId!, cartItemId, newQty);
                                        }
                                      : null,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text('$quantity', style: const TextStyle(fontSize: 16)),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero, 
                                  constraints: const BoxConstraints(), 
                                  icon: const Icon(Icons.add_circle_outline, size: 20),
                                  onPressed: quantity < stock
                                      ? () async {
                                          final newQty = quantity + 1;
                                          setState(() =>
                                              _quantities[cartItemId] = newQty);
                                          await _firestoreService
                                              .updateCartQuantity(
                                                  _userId!, cartItemId, newQty);
                                        }
                                      : null,
                                ),
                              ],
                            ),
                            
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () async {
                            await _firestoreService.removeFromCart(
                                _userId!, cartItemId);
                            setState(() => _quantities.remove(cartItemId));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Đã xóa sản phẩm khỏi giỏ hàng.'),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              ValueListenableBuilder<Set<String>>(
                valueListenable: _selectedProductIds,
                builder: (context, selectedIds, _) {
                  final selectedItems = items
                      .where((item) => selectedIds.contains(item['cartItemId']))
                      .toList();
                  
                  final totalPrice = selectedItems.fold<int>(
                    0,
                    (total, item) =>
                        total +
                        (_quantities[item['cartItemId']]! *
                            (item['price'] as int)),
                  );

                  final itemsForCheckout = selectedItems.map((item) {
                    final newItem = Map<String, dynamic>.from(item);
                    newItem['quantity'] = _quantities[item['cartItemId']] ?? item['quantity'];
                    return newItem;
                  }).toList();

                  return _buildTotalSection(context, totalPrice, itemsForCheckout);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTotalSection(
      BuildContext context, int totalPrice, List<Map<String, dynamic>> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: const Border(top: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng cộng:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(_formatCurrency(totalPrice),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: items.isEmpty
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CheckoutScreen(
                          totalAmount: totalPrice,
                          cartItems: items,
                        ),
                      ),
                    );
                  },
            icon: const Icon(Icons.payment),
            label: const Text('Tiến hành thanh toán'),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchCartDetails(
      QuerySnapshot cartSnapshot) async {
    
    final cartDocs = cartSnapshot.docs;

    final futures = cartDocs.map((doc) async {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final cartItemId = doc.id;
      final productId = data['productId'] ?? '';
      final quantity = data['quantity'] ?? 0;
      if (productId.isEmpty) return null;

      Map<String, dynamic>? productData;

      try {
        if (_productDetailsCache.containsKey(productId)) {
          productData = _productDetailsCache[productId];
        } else {
          final productSnap = await _firestoreService.getProductDetails(productId);
          productData = productSnap.data();
          if (productData != null) {
            _productDetailsCache[productId] = productData;
          }
        }

        if (productData == null) return null;

        final imageList = (productData['imageUrls'] ?? []) as List<dynamic>? ?? [];
        final imageUrl = imageList.isNotEmpty ? imageList.first as String : '';

        return {
          'cartItemId': cartItemId,
          'productId': productId,
          'productName': productData['productName'] ?? 'Không rõ tên',
          'price': (productData['price'] as num).toInt(),
          'imageUrl': imageUrl,
          'quantity': quantity,
          'stock': productData['stock'] ?? 100,
          'sellerId': productData['sellerId'] ?? 'unknown',
          'sellerBankName': productData['sellerBankName'] ?? '',
          'sellerBankAccount': productData['sellerBankAccount'] ?? '',
        };
      } catch (_) {
        return null;
      }
    }).toList();

    final results = await Future.wait(futures);
    return results.whereType<Map<String, dynamic>>().toList();
  }

  String _formatCurrency(int value) {
    return '${value.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        )} đ';
  }

}
