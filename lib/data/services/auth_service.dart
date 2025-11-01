// lib/data/services/auth_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get user => _auth.authStateChanges();
  String? get currentUserId => _auth.currentUser?.uid;
  String? get currentUserDisplayName => _auth.currentUser?.displayName;

  /// ----------------------------
  /// Đăng ký người dùng mới
  /// ----------------------------
  Future<String> registerWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
    required bool isSeller,
    Map<String, String>? sellerInfo,
  }) async {
    try {
      // Tạo tài khoản
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? newUser = result.user;
      if (newUser == null) {
        return "Không thể tạo người dùng.";
      }

      // Cập nhật tên hiển thị
      await newUser.updateDisplayName(displayName);
      await newUser.reload();

      // Dữ liệu lưu Firestore
      Map<String, dynamic> userData = {
        'uid': newUser.uid,
        'email': email,
        'displayName': displayName,
        'role': isSeller ? 'seller' : 'user',
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Nếu là seller thì thêm thông tin ngân hàng (nếu có)
      if (isSeller && sellerInfo != null) {
        userData.addAll({
          'bankAccount': sellerInfo['bankAccount'],
          'bankBin': sellerInfo['bankBin'],
        });
      }

      // Ghi dữ liệu lên Firestore
      await _firestore.collection('users').doc(newUser.uid).set(userData);

      // Sau khi tạo xong → đăng xuất
      await _auth.signOut();

      return "Success";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') return 'Email này đã được sử dụng.';
      if (e.code == 'invalid-email') return 'Email không hợp lệ.';
      if (e.code == 'weak-password') {
        return 'Mật khẩu quá yếu, vui lòng dùng mật khẩu mạnh hơn.';
      }
      return e.message ?? 'Đã xảy ra lỗi xác thực.';
    } catch (e) {
      debugPrint("Error in register: $e");
      return "Đã xảy ra lỗi không xác định.";
    }
  }

  /// ----------------------------
  /// Đăng nhập
  /// ----------------------------
  Future<String> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return "Success";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return 'Người dùng không tồn tại.';
      if (e.code == 'wrong-password') return 'Sai mật khẩu.';
      return e.message ?? "Lỗi đăng nhập.";
    } catch (e) {
      debugPrint("Error signing in: $e");
      return "Đã xảy ra lỗi không xác định khi đăng nhập.";
    }
  }

  /// ----------------------------
  /// Đăng xuất
  /// ----------------------------
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint("Error signing out: $e");
    }
  }

  /// ----------------------------
  /// Lấy thông tin người dùng hiện tại
  /// ----------------------------
  Future<DocumentSnapshot?> getCurrentUserDetails() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return null;
      }
      return await _firestore.collection('users').doc(user.uid).get();
    } catch (e) {
      debugPrint("Error getting user details: $e");
      return null;
    }
  }

  /// ----------------------------
  /// Kiểm tra xem người dùng hiện tại có phải là seller không
  /// ----------------------------
  Future<bool> get currentUserIsSeller async {
    try {
      final userSnap = await getCurrentUserDetails();
      if (userSnap == null) {
        return false;
      }
      final data = userSnap.data() as Map<String, dynamic>? ?? {};
      bool isSeller = data['role'] == 'seller';
      debugPrint('isSeller: $isSeller');
      return isSeller;
    } catch (e) {
      debugPrint("Error checking seller role: $e");
      return false;
    }
  }
}
