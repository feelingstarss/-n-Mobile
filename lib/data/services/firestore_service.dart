import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // <-- THÊM IMPORT NÀY

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;



  Future<DocumentSnapshot<Map<String, dynamic>>> getProductDetails(
      String productId) {
    return _db.collection('products').doc(productId).get();
  }

  Stream<QuerySnapshot> getProductsStream() {
    return _db
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getProductsStreamBySeller(String sellerId) {
    return _db
        .collection('products')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots();
  }

  Future<void> addProduct(Map<String, dynamic> productData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Bạn chưa đăng nhập');

    final userDoc = await _db.collection('users').doc(user.uid).get();
    final userData = userDoc.data();

    if (userData == null || userData['role'] != 'seller') {
      throw Exception('Chỉ seller mới có thể thêm sản phẩm');
    }

    productData['sellerId'] = user.uid;
    productData['createdAt'] = FieldValue.serverTimestamp();

    await _db.collection('products').add(productData);
  }

  Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    data.remove('createdAt');
    await _db.collection('products').doc(productId).update(data);
  }

  Future<void> deleteProduct(String productId) async {
    await _db.collection('products').doc(productId).delete();
  }

  Stream<QuerySnapshot> searchAllProducts(String searchQuery) {
    Query query = _db.collection('products').orderBy('createdAt', descending: true);

    if (searchQuery.isNotEmpty) {
      String endQuery = searchQuery.substring(0, searchQuery.length - 1) +
          String.fromCharCode(searchQuery.codeUnitAt(searchQuery.length - 1) + 1);
      query = query
          .where('productName', isGreaterThanOrEqualTo: searchQuery)
          .where('productName', isLessThan: endQuery);
    }

    return query.snapshots();
  }

  Stream<QuerySnapshot> getFilteredProductsStream({
    required String searchQuery,
    required String sortOption,
  }) {
    Query query = _db.collection('products');

    if (searchQuery.isNotEmpty) {
      String endQuery = searchQuery.substring(0, searchQuery.length - 1) +
          String.fromCharCode(searchQuery.codeUnitAt(searchQuery.length - 1) + 1);
      query = query
          .where('productName', isGreaterThanOrEqualTo: searchQuery)
          .where('productName', isLessThan: endQuery);
    }

    switch (sortOption) {
      case 'price_asc':
        query = query.orderBy('price', descending: false);
        break;
      case 'price_desc':
        query = query.orderBy('price', descending: true);
        break;
      default:
        query = query.orderBy(
          searchQuery.isNotEmpty ? 'productName' : 'createdAt',
          descending: searchQuery.isNotEmpty ? false : true,
        );
        break;
    }

    return query.snapshots();
  }



  Stream<QuerySnapshot> getCartStream(String userId) {
    return _db.collection('users').doc(userId).collection('cart').snapshots();
  }

  Future<void> addToCart({
    required String userId,
    required String productId,
    required String size,
    int quantity = 1,
  }) async {
    final String cartItemId = '${productId}_$size';
    final cartItemRef =
        _db.collection('users').doc(userId).collection('cart').doc(cartItemId);

    await _db.runTransaction((transaction) async {
      final doc = await transaction.get(cartItemRef);
      if (doc.exists) {
        transaction
            .update(cartItemRef, {'quantity': FieldValue.increment(quantity)});
      } else {
        transaction.set(cartItemRef, {
          'productId': productId,
          'size': size,
          'quantity': quantity,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> updateCartQuantity(
      String userId, String cartItemId, int quantity) async {
    final cartRef =
        _db.collection('users').doc(userId).collection('cart').doc(cartItemId);
    await cartRef.update({'quantity': quantity});
  }

  Future<void> removeFromCart(String userId, String cartItemId) async {
    final cartRef =
        _db.collection('users').doc(userId).collection('cart').doc(cartItemId);
    await cartRef.delete();
  }

 


  Stream<QuerySnapshot> getOrdersByUser(String userId) {
    return _db
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

 
  Stream<QuerySnapshot> getOrdersBySeller(String sellerId) {
    return _db
        .collection('orders')
        .where('sellerIds', arrayContains: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }


  Stream<QuerySnapshot> getAllOrdersStream() {
    return _db.collection('orders').orderBy('createdAt', descending: true).snapshots();
  }


  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _db.collection('orders').doc(orderId).update({'status': newStatus});
  }


  Future<void> createOrder({
    required String userId,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required String address,
  }) async {
    final sellerIds = <String>{};
    for (var item in items) {
      if (item.containsKey('sellerId')) {
        sellerIds.add(item['sellerId']);
      } else {
        final productDoc =
            await _db.collection('products').doc(item['productId']).get();
        if (productDoc.exists) {
          sellerIds.add(productDoc.data()?['sellerId']);
        }
      }
    }

    final orderData = {
      'userId': userId,
      'sellerIds': sellerIds.toList(),
      'items': items,
      'totalAmount': totalAmount,
      'address': address,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _db.collection('orders').add(orderData);
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await _db.collection('users').doc(userId).update(data);
  }

  Future<DocumentSnapshot> getUserDetails(String userId) {
    return _db.collection('users').doc(userId).get();
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    await _db.collection('users').doc(userId).update({'role': newRole});
  }

  Future<void> updateUserStatus(String userId, String newStatus) async {
    await _db.collection('users').doc(userId).update({'status': newStatus});
  }

  Future<void> updateUserField(String userId, String field, dynamic value) async {
    await _db.collection('users').doc(userId).update({field: value});
  }

  Stream<QuerySnapshot> getAllUsersStream() {
    return _db.collection('users').snapshots();
  }

  Future<List<Map<String, dynamic>>> getSellerProductsInOrder(
      String orderId, String sellerId) async {
    try {
      final orderDoc = await _db.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) {
      
        debugPrint("=== DEBUG Firestore: Order $orderId not found");
        return [];
      }
      final orderData = orderDoc.data();

      debugPrint("=== DEBUG Firestore: Order data for $orderId: $orderData");
      final List<dynamic> products = orderData?['items'] ?? [];
      final List<Map<String, dynamic>> sellerProducts = [];

      for (var product in products) {
        final productId = product['productId'] as String?;
        if (productId == null) continue;
        final productDoc = await getProductDetails(productId);
        if (!productDoc.exists) {
   
          debugPrint("=== DEBUG Firestore: Product $productId not found");
          continue;
        }
        final productData = productDoc.data();
 
        debugPrint(
            "=== DEBUG Firestore: Product $productId sellerId: ${productData?['sellerId']}");
        if (productData?['sellerId'] == sellerId) {
          sellerProducts.add(product);
        }
      }
      return sellerProducts;
    } catch (e, s) { 
      debugPrint(
          "=== DEBUG Firestore Error in getSellerProductsInOrder: $e\nStackTrace: $s");
      return [];
    }
  }
}

