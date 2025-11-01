import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doanmobile/data/services/auth_service.dart';
import 'package:doanmobile/data/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameCtrl = TextEditingController();
  final _bankAccountCtrl = TextEditingController();

  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;
  bool _isInitialized = false; // tránh gán lại text khi rebuild
  String? _selectedBank;

  // Bản đồ ngân hàng -> mã BIN
  final Map<String, String> _bankBinMap = {
    'Vietcombank': '970436',
    'VietinBank': '970411',
    'BIDV': '970403',
    'Techcombank': '970422',
    'Agribank': '970418',
    'MB Bank': '970422',
    'Sacombank': '970415',
    'ACB': '970407',
  };

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _bankAccountCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile(String userId, String currentRole) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      Map<String, dynamic> dataToUpdate = {
        'displayName': _displayNameCtrl.text.trim(),
      };

      if (currentRole == 'seller') {
        if (_selectedBank != null) {
          dataToUpdate['bankName'] = _selectedBank!;
          dataToUpdate['bankBin'] = _bankBinMap[_selectedBank!]!;
        }
        dataToUpdate['bankAccount'] = _bankAccountCtrl.text.trim();
      }

      await _firestoreService.updateUserProfile(userId, dataToUpdate);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật thông tin thành công!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final userId = authService.currentUserId;

    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa thông tin')),
      body: userId == null
          ? const Center(child: Text('Lỗi: Không tìm thấy người dùng.'))
          : FutureBuilder<DocumentSnapshot>(
              future: _firestoreService.getUserDetails(userId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final userData =
                    snapshot.data!.data() as Map<String, dynamic>? ?? {};

                // chỉ gán text lần đầu
                if (!_isInitialized) {
                  _displayNameCtrl.text = userData['displayName'] ?? '';
                  if (userData['role'] == 'seller') {
                    _bankAccountCtrl.text = userData['bankAccount'] ?? '';
                    _selectedBank = userData['bankName'];
                  }
                  _isInitialized = true;
                }

                final isSeller = userData['role'] == 'seller';

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _displayNameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Tên hiển thị / Tên Shop',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              v!.isEmpty ? 'Không được bỏ trống' : null,
                        ),
                        if (isSeller) ...[
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedBank,
                            decoration: const InputDecoration(
                              labelText: 'Chọn ngân hàng',
                              border: OutlineInputBorder(),
                            ),
                            items: _bankBinMap.keys
                                .map((bank) => DropdownMenuItem(
                                      value: bank,
                                      child: Text(bank),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedBank = value;
                              });
                            },
                            validator: (v) =>
                                v == null ? 'Vui lòng chọn ngân hàng' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _bankAccountCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Số tài khoản ngân hàng',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v!.isEmpty ? 'Không được bỏ trống' : null,
                          ),
                        ],
                        const SizedBox(height: 24),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50),
                                ),
                                onPressed: () =>
                                    _saveProfile(userId, userData['role']),
                                icon: const Icon(Icons.save),
                                label: const Text('Lưu thay đổi'),
                              ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
