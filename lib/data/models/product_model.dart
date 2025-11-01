// lib/data/models/product_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String productName;
  final String description;
  final int price;
  final String category; 
  final List<dynamic> variants; 
  final List<String> imageUrls;
  final String sellerId;
  final String sellerName;
  final Timestamp? createdAt;
  
  
  final List<String>? sizes;
  final List<String>? colors;
  final int? stock;


  ProductModel({
    required this.id,
    required this.productName,
    required this.description,
    required this.price,
    required this.category, // <-- Thêm mới
    required this.variants, // <-- Thêm mới
    required this.imageUrls,
    required this.sellerId,
    required this.sellerName,
    this.createdAt,
    this.sizes,
    this.colors,
    this.stock,
  });

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      productName: data['productName'] ?? '',
      description: data['description'] ?? '',
      price: data['price'] ?? 0,
      category: data['category'] ?? '', 
      variants: data['variants'] ?? [], 
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      createdAt: data['createdAt'],
      sizes: data.containsKey('sizes') ? List<String>.from(data['sizes']) : null,
      colors: data.containsKey('colors') ? List<String>.from(data['colors']) : null,
      stock: data['stock'],
    );
  }
}

