import 'package:doanmobile/data/services/auth_service.dart';
import 'package:doanmobile/features/authentication/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  final _bankAccountCtrl = TextEditingController();

  bool _isLoading = false;
  bool _isRegisteringAsSeller = false;

  String? _selectedBank;

  // Danh sách ngân hàng và mã BIN tương ứng
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
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _displayNameCtrl.dispose();
    _bankAccountCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_isRegisteringAsSeller && _selectedBank == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn ngân hàng'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);
      final authService = Provider.of<AuthService>(context, listen: false);

      Map<String, String>? sellerInfo;
      if (_isRegisteringAsSeller) {
        final bankBin = _bankBinMap[_selectedBank!] ?? '';
        sellerInfo = {
          'bankAccount': _bankAccountCtrl.text.trim(),
          'bankName': _selectedBank!,
          'bankBin': bankBin,
        };
      }

      String result = await authService.registerWithEmailPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        displayName: _displayNameCtrl.text.trim(),
        isSeller: _isRegisteringAsSeller,
        sellerInfo: sellerInfo,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result == "Success") {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isRegisteringAsSeller
              ? 'Đăng ký thành công làm seller! Vui lòng đăng nhập.'
              : 'Đăng ký thành công! Vui lòng đăng nhập.'),
          backgroundColor: Colors.green,
        ));

        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tạo tài khoản")),
      body: Center(
        child: SingleChildScrollView(
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
                  validator: (v) => v!.isEmpty ? 'Không được bỏ trống' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v!.isEmpty ? 'Không được bỏ trống' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (v) =>
                      v!.length < 6 ? 'Mật khẩu phải > 6 ký tự' : null,
                ),
                SwitchListTile(
                  title: const Text('Đăng ký làm người bán'),
                  value: _isRegisteringAsSeller,
                  onChanged: (bool value) {
                    setState(() {
                      _isRegisteringAsSeller = value;
                    });
                  },
                ),
                if (_isRegisteringAsSeller) ...[
                  const SizedBox(height: 12),
                  // Chọn ngân hàng
                  DropdownButtonFormField<String>(
                    initialValue: _selectedBank,
                    decoration: const InputDecoration(
                      labelText: 'Chọn ngân hàng',
                      border: OutlineInputBorder(),
                    ),
                    items: _bankBinMap.keys
                        .map((bank) =>
                            DropdownMenuItem(value: bank, child: Text(bank)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedBank = value;
                      });
                    },
                    validator: (v) =>
                        v == null ? 'Vui lòng chọn ngân hàng' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bankAccountCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Số tài khoản ngân hàng',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Không được bỏ trống' : null,
                  ),
                ],
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        onPressed: _submit,
                        child: const Text('Đăng ký'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
