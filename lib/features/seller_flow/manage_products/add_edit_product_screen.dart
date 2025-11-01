import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:doanmobile/data/services/product_image_db.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doanmobile/data/models/product_model.dart';
import 'package:doanmobile/data/services/auth_service.dart';
import 'package:doanmobile/data/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:provider/provider.dart';

class ProductVariant {
  String? size;
  TextEditingController stockController;

  ProductVariant({this.size, String stock = ''})
      : stockController = TextEditingController(text: stock);

  void dispose() {
    stockController.dispose();
  }
}

class AddEditProductScreen extends StatefulWidget {
  final ProductModel? product;
  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  String? _base64Image;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String? _selectedCategory;
  List<ProductVariant> _variants = [ProductVariant()];

  final FirestoreService _firestoreService = FirestoreService();
  final _imageLinkCtrl = TextEditingController();
  List<String> _existingImageUrls = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameCtrl.text = widget.product!.productName;
      _descCtrl.text = widget.product!.description;
      _priceCtrl.text = widget.product!.price.toString();
      _selectedCategory = widget.product!.category;
      _existingImageUrls = List.from(widget.product!.imageUrls);
      if (_existingImageUrls.isNotEmpty) {
        _imageLinkCtrl.text = _existingImageUrls.first;
      }
      if (widget.product!.variants.isNotEmpty) {
        _variants = widget.product!.variants
            .map((v) =>
                ProductVariant(size: v['size'], stock: v['stock'].toString()))
            .toList();
      }
    }
    // Load ảnh từ SQLite nếu sửa sản phẩm
    if (widget.product != null) {
      ProductImageDatabase.instance
          .getImages(productId: widget.product!.id)
          .then((images) {
        if (images.isNotEmpty) {
          setState(() {
            _base64Image = images.first.base64Image;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _imageLinkCtrl.dispose();
    for (var variant in _variants) {
      variant.dispose();
    }
    super.dispose();
  }

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final sellerId = authService.currentUserId;
        final sellerName = authService.currentUserDisplayName ?? "Không rõ tên";

        if (sellerId == null) throw Exception("Không thể xác thực người dùng.");

        // Chỉ kiểm tra role seller thôi
        bool isSeller = await authService.currentUserIsSeller;
        if (!isSeller) {
          if (!mounted) return;
          await Flushbar(
            message: "Bạn không có quyền đăng bài.",
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ).show(context);
          return;
        }

        List<Map<String, dynamic>> variantsData = _variants.map((variant) {
          return {
            'size': variant.size,
            'stock': int.tryParse(variant.stockController.text.trim()) ?? 0,
          };
        }).toList();

        List<String> imageUrls = [];
        if (_base64Image != null && _base64Image!.isNotEmpty) {
          imageUrls.add('data:image/png;base64,$_base64Image');
        }

        Map<String, dynamic> productData = {
          'productName': _nameCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'price': int.tryParse(_priceCtrl.text.trim()) ?? 0,
          'category': _selectedCategory,
          'variants': variantsData,
          'imageUrls': imageUrls,
          'sellerId': sellerId,
          'sellerName': sellerName,
          'createdAt':
              widget.product?.createdAt ?? FieldValue.serverTimestamp(),
        };

        if (widget.product == null) {
          await _firestoreService.addProduct(productData);
        } else {
          await _firestoreService.updateProduct(
              widget.product!.id, productData);
        }

        if (mounted) {
          final navigator = Navigator.of(context);
          await Flushbar(
            message: widget.product == null
                ? 'Thêm sản phẩm thành công'
                : 'Cập nhật sản phẩm thành công',
            duration: const Duration(seconds: 2),
          ).show(context);
          if (mounted) navigator.pop();
        }
      } catch (e) {
        if (!mounted) return;
        await Flushbar(
          message: 'Lỗi: ${e.toString()}',
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ).show(context);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.product == null ? 'Thêm sản phẩm' : 'Chỉnh sửa sản phẩm'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProduct,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.image),
                          label: const Text('Chọn ảnh'),
                          onPressed: () async {
                            final picker = ImagePicker();
                            final picked = await picker.pickImage(
                                source: ImageSource.gallery);
                            if (picked != null) {
                              final bytes = await picked.readAsBytes();
                              final base64Str = base64Encode(bytes);
                              setState(() {
                                _base64Image = base64Str;
                              });
                              await ProductImageDatabase.instance.insertImage(
                                  ProductImage(
                                      base64Image: base64Str,
                                      productId: widget.product?.id));
                            }
                          },
                        ),
                        const SizedBox(width: 16),
                        _base64Image != null
                            ? Image.memory(
                                base64Decode(_base64Image!),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              )
                            : const Text('Chưa có ảnh'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Tên sản phẩm',
                          border: OutlineInputBorder()),
                      validator: (v) =>
                          v!.isEmpty ? 'Không được bỏ trống' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                          labelText: 'Mô tả (chất liệu, màu sắc...)',
                          border: OutlineInputBorder()),
                      validator: (v) =>
                          v!.isEmpty ? 'Không được bỏ trống' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Giá', border: OutlineInputBorder()),
                      validator: (v) =>
                          v!.isEmpty ? 'Không được bỏ trống' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                          labelText: 'Phân loại', border: OutlineInputBorder()),
                      items: [
                        'Áo Thun',
                        'Áo Sơ Mi',
                        'Áo Khoác',
                        'Quần Jean',
                        'Quần Short',
                        'Váy',
                        'Phụ kiện'
                      ]
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedCategory = value),
                      validator: (v) => v == null ? 'Vui lòng chọn' : null,
                    ),
                    const Divider(height: 30),
                    Text('Các phiên bản (Size & Số lượng)',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _variants.length,
                      itemBuilder: (context, index) {
                        return _buildVariantRow(index);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Thêm phiên bản'),
                      onPressed: () =>
                          setState(() => _variants.add(ProductVariant())),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildVariantRow(int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 0, 0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                initialValue: _variants[index].size,
                decoration: const InputDecoration(
                    labelText: 'Size', border: InputBorder.none),
                items: ['S', 'M', 'L', 'XL', 'XXL', 'FREE SIZE']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _variants[index].size = value;
                  });
                },
                validator: (v) => v == null ? 'Chọn' : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: TextFormField(
                  controller: _variants[index].stockController,
                  decoration: const InputDecoration(
                      labelText: 'SL', border: InputBorder.none),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Nhập' : null),
            ),
            if (_variants.length > 1)
              IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                onPressed: () => setState(() => _variants.removeAt(index)),
              ),
          ],
        ),
      ),
    );
  }
}
