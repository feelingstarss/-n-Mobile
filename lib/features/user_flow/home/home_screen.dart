import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doanmobile/data/services/auth_service.dart';
import 'package:doanmobile/data/services/firestore_service.dart';
import 'package:doanmobile/features/authentication/screens/edit_profile_screen.dart';
import 'package:doanmobile/features/user_flow/cart/cart_screen.dart';
import 'package:doanmobile/features/user_flow/order_history/order_history_screen.dart';
import 'package:doanmobile/features/user_flow/product_details/product_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService firestoreService = FirestoreService();
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  String sortOption = 'newest';

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      if (mounted) setState(() => searchQuery = searchController.text);
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Widget buildGridFromDocs(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) {
      return const Center(child: Text('Không tìm thấy sản phẩm nào.'));
    }
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      itemCount: docs.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.65,
      ),
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data() as Map<String, dynamic>;
        final productName = data['productName'] ?? 'N/A';
        final price = data['price'] ?? 0;
        final firstImage = (data['imageUrls'] as List).isNotEmpty
            ? data['imageUrls'][0]
            : '';

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailsScreen(productId: doc.id),
            ),
          ),
          child: Card(
            clipBehavior: Clip.antiAlias,
            elevation: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: firstImage.isNotEmpty
                      ? (firstImage.startsWith('data:image')
                          ? Image.memory(
                              base64Decode(firstImage.split(',').last),
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) =>
                                  const Icon(Icons.error),
                            )
                          : Image.network(
                              firstImage,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) =>
                                  const Icon(Icons.error),
                            ))
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 40,
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    '$price đ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductDetailsScreen(productId: doc.id),
                      ),
                    ),
                    child: const Text('Xem chi tiết'),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  List<QueryDocumentSnapshot> sortDocs(List<QueryDocumentSnapshot> docs) {
    final list = List<QueryDocumentSnapshot>.from(docs);
    if (sortOption == 'price_asc') {
      list.sort((a, b) {
        final ad = a.data() as Map<String, dynamic>;
        final bd = b.data() as Map<String, dynamic>;
        return (ad['price'] ?? 0).compareTo(bd['price'] ?? 0);
      });
    } else if (sortOption == 'price_desc') {
      list.sort((a, b) {
        final ad = a.data() as Map<String, dynamic>;
        final bd = b.data() as Map<String, dynamic>;
        return (bd['price'] ?? 0).compareTo(ad['price'] ?? 0);
      });
    } else {
      list.sort((a, b) {
        final ad = a.data() as Map<String, dynamic>;
        final bd = b.data() as Map<String, dynamic>;
        final at = ad['createdAt'] as Timestamp?;
        final bt = bd['createdAt'] as Timestamp?;
        final aMillis = at?.millisecondsSinceEpoch ?? 0;
        final bMillis = bt?.millisecondsSinceEpoch ?? 0;
        return bMillis.compareTo(aMillis);
      });
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: const Text('Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Lịch sử đơn hàng'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const OrderHistoryScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Thông tin cá nhân'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const EditProfileScreen()),
                );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('DoanMobile Shop'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authService.signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm quần áo...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text('Sắp xếp theo: '),
                    DropdownButton<String>(
                      value: sortOption,
                      items: const [
                        DropdownMenuItem(
                            value: 'newest', child: Text('Mới nhất')),
                        DropdownMenuItem(
                            value: 'price_asc', child: Text('Giá tăng dần')),
                        DropdownMenuItem(
                            value: 'price_desc', child: Text('Giá giảm dần')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => sortOption = value);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: searchQuery.trim().isEmpty
                  ? firestoreService.getProductsStream()
                  : firestoreService.getFilteredProductsStream(
                      searchQuery: searchQuery, sortOption: sortOption),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: firestoreService.getProductsStream(),
                    builder: (c, s2) {
                      if (s2.hasError) {
                        return const Center(child: Text('Đã xảy ra lỗi.'));
                      }
                      if (s2.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      final docs = s2.data?.docs ?? [];
                      final filtered = docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = (data['productName'] ?? '')
                            .toString()
                            .toLowerCase();
                        return name.contains(searchQuery.toLowerCase());
                      }).toList();

                      if (sortOption == 'price_asc') {
                        filtered.sort((a, b) {
                          final ad = a.data() as Map<String, dynamic>;
                          final bd = b.data() as Map<String, dynamic>;
                          return (ad['price'] ?? 0)
                              .compareTo(bd['price'] ?? 0);
                        });
                      } else if (sortOption == 'price_desc') {
                        filtered.sort((a, b) {
                          final ad = a.data() as Map<String, dynamic>;
                          final bd = b.data() as Map<String, dynamic>;
                          return (bd['price'] ?? 0)
                              .compareTo(ad['price'] ?? 0);
                        });
                      } else {
                        filtered.sort((a, b) {
                          final ad = a.data() as Map<String, dynamic>;
                          final bd = b.data() as Map<String, dynamic>;
                          final at = ad['createdAt'] as Timestamp?;
                          final bt = bd['createdAt'] as Timestamp?;
                          final aMillis = at?.millisecondsSinceEpoch ?? 0;
                          final bMillis = bt?.millisecondsSinceEpoch ?? 0;
                          return bMillis.compareTo(aMillis);
                        });
                      }

                      return Column(
                        children: [
                          Container(
                            width: double.infinity,
                            color: Colors.amber.shade100,
                            padding: const EdgeInsets.all(8.0),
                            child: const Text(
                              'Chú ý: tìm kiếm trên server tạm thời không khả dụng, hiển thị kết quả bằng bộ lọc client-side.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                              child: buildGridFromDocs(
                                  filtered.cast<QueryDocumentSnapshot>())),
                        ],
                      );
                    },
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                return buildGridFromDocs(sortDocs(docs.cast<QueryDocumentSnapshot>()));
              },
            ),
          ),
        ],
      ),
    );
  }
}
