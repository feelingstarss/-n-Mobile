import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:doanmobile/data/services/firestore_service.dart';
import 'package:doanmobile/data/services/auth_service.dart';

class CheckoutScreen extends StatefulWidget {
  final int totalAmount;
  final List<Map<String, dynamic>> cartItems;

  const CheckoutScreen({
    super.key,
    required this.totalAmount,
    required this.cartItems,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String paymentMethod = 'Tiền mặt';
  final Map<String, int> _quantities = {};
  final TextEditingController _receiverNameController = TextEditingController();
  final TextEditingController _receiverPhoneController = TextEditingController();
  final TextEditingController _receiverAddressController = TextEditingController();

  final firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    for (var item in widget.cartItems) {
      _quantities[item['productId']] = item['quantity'];
    }
  }

  @override
  void dispose() {
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _receiverAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int totalAmount = _quantities.entries.fold(0, (sum, e) {
      final item = widget.cartItems.firstWhere((i) => i['productId'] == e.key);
      return sum + (e.value * (item['price'] as int));
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Danh sách sản phẩm đã chọn:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  ...widget.cartItems.map((item) {
                    final pid = item['productId'];
                    final quantity = _quantities[pid] ?? item['quantity'];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(item['productName']),
                        subtitle: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: quantity > 1
                                  ? () {
                                      setState(() {
                                        _quantities[pid] = quantity - 1;
                                      });
                                    }
                                  : null,
                            ),
                            Text('$quantity'),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () {
                                setState(() {
                                  _quantities[pid] = quantity + 1;
                                });
                              },
                            ),
                          ],
                        ),
                        trailing: Text(
                          _formatCurrency(quantity * (item['price'] as int)),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  const Text(
                    'Thông tin người nhận:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _receiverNameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên người nhận',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _receiverPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _receiverAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ giao hàng',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Phương thức thanh toán: '),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: paymentMethod,
                        items: const [
                          DropdownMenuItem(value: 'Tiền mặt', child: Text('Tiền mặt')),
                          DropdownMenuItem(value: 'Chuyển khoản', child: Text('Chuyển khoản')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              paymentMethod = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (paymentMethod == 'Chuyển khoản') ..._buildSellerQrWidgets(totalAmount),
                ],
              ),
            ),
            const Divider(thickness: 1.2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng cộng:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  _formatCurrency(totalAmount),
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _showConfirmDialog(),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Xác nhận thanh toán'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSellerQrWidgets(int totalAmount) {
    final sellers = widget.cartItems.map((e) => e['sellerId']).toSet();
    return sellers.map((sellerId) {
      final sellerInfo = widget.cartItems.firstWhere((e) => e['sellerId'] == sellerId);

      final bankName = sellerInfo['sellerBankName'] ?? '';
      final bankAccount = sellerInfo['sellerBankAccount'] ?? '';

      final qrData = 'BANK:$bankName;ACCOUNT:$bankAccount;AMOUNT:$totalAmount;NOTE:Thanh toán đơn hàng';

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Thanh toán tới seller: ${sellerInfo['sellerName']}'),
              Text('Ngân hàng: $bankName'),
              Text('Số tài khoản: $bankAccount'),
              const SizedBox(height: 8),
              Center(
                child: QrImageView(
                  data: qrData,
                  size: 150.0,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _showConfirmDialog() {
    if (_receiverNameController.text.isEmpty ||
        _receiverPhoneController.text.isEmpty ||
        _receiverAddressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ thông tin người nhận.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận thanh toán'),
        content: const Text('Bạn có chắc muốn thanh toán đơn hàng này không?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processPayment(); 
            },
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUserId!;
    final address =
        '${_receiverNameController.text}, ${_receiverPhoneController.text}, ${_receiverAddressController.text}';

    // Tạo đơn cho từng seller
    final sellers = widget.cartItems.map((e) => e['sellerId']).toSet();
    for (var sellerId in sellers) {
      final sellerItems = widget.cartItems
          .where((item) => item['sellerId'] == sellerId)
          .map((item) => {
                'productId': item['productId'],
                'productName': item['productName'],
                'price': item['price'],
                'quantity': _quantities[item['productId']] ?? item['quantity'],
              })
          .toList();

      final totalPrice = sellerItems.fold<int>(
          0, (sum, item) => sum + (item['price'] as int) * (item['quantity'] as int));

      await firestoreService.createOrder(
        userId: userId,
        items: sellerItems,
        totalAmount: totalPrice.toDouble(),
        address: address,
      );
    }

 
    for (var item in widget.cartItems) {
      await firestoreService.removeFromCart(userId, item['cartItemId']);
    }

   
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thanh toán thành công!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  String _formatCurrency(int value) {
    return '${value.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} đ';
  }
}

