import 'package:shared_preferences/shared_preferences.dart';
import '../core/storage/local_store.dart';
import '../core/security/password_hasher.dart';

class AuthRepository {
  final LocalStore _store = LocalStore();

  Future<Map<String, dynamic>?> login(String email, String password) async {
    final users = _store.getCollection('users');
    final user = users.firstWhere(
      (u) => (u['email'] as String? ?? '').trim().toLowerCase() == email.trim().toLowerCase(),
      orElse: () => {},
    );

    if (user.isEmpty) {
      return null;
    }

    final storedHash = user['password_hash'] as String? ?? '';
    final isValid = PasswordHasher.verifyPassword(password, storedHash);
    if (!isValid) {
      return null;
    }

    if (user['is_active'] == false) {
      throw Exception("User account is deactivated");
    }

    final token = "local_jwt_token_${user['id']}_${DateTime.now().millisecondsSinceEpoch}";
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("auth_token", token);
    await prefs.setInt("current_user_id", user['id']);

    final business = _store.getDocument('business');
    final branches = _store.getCollection('branches');
    final branchId = user['branch_id'] ?? 1;
    final branch = branches.firstWhere((b) => b['id'] == branchId, orElse: () => branches.isNotEmpty ? branches.first : {});

    return {
      'token': token,
      'user': user,
      'business': business,
      'branch': branch,
    };
  }

  Future<Map<String, dynamic>?> verifyOtp(String phone, String otp) async {
    // Development default OTP is 1234
    if (otp.trim() != "1234") {
      return null;
    }

    final users = _store.getCollection('users');
    var user = users.firstWhere(
      (u) => (u['phone'] as String? ?? '').replaceAll(' ', '').contains(phone.replaceAll(' ', '')),
      orElse: () => {},
    );

    if (user.isEmpty) {
      // If phone wasn't matched specifically, fall back to admin
      user = users.firstWhere((u) => u['role'].toString().toLowerCase() == 'admin', orElse: () => users.first);
    }

    final token = "local_jwt_token_${user['id']}_${DateTime.now().millisecondsSinceEpoch}";
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("auth_token", token);
    await prefs.setInt("current_user_id", user['id']);

    final business = _store.getDocument('business');
    final branches = _store.getCollection('branches');
    final branchId = user['branch_id'] ?? 1;
    final branch = branches.firstWhere((b) => b['id'] == branchId, orElse: () => branches.isNotEmpty ? branches.first : {});

    return {
      'token': token,
      'user': user,
      'business': business,
      'branch': branch,
    };
  }

  Future<Map<String, dynamic>> registerBusiness({
    required String name,
    required String ownerName,
    required String phone,
    required String email,
    required String password,
    String? gstin,
    String? address,
    String? city,
  }) async {
    final business = {
      'id': 1,
      'name': name,
      'trade_name': name,
      'gstin': gstin ?? '',
      'phone': phone,
      'email': email,
      'address': address ?? '',
      'city': city ?? '',
      'state': 'Maharashtra',
      'currency': 'INR',
    };
    _store.setDocument('business', business);

    final branch = {
      'id': 1,
      'business_id': 1,
      'name': 'Main Branch',
      'code': 'HQ-01',
      'phone': phone,
      'email': email,
      'address': address ?? '',
      'city': city ?? '',
      'state': 'Maharashtra',
      'gstin': gstin ?? '',
      'is_head_office': true,
    };
    _store.setCollection('branches', [branch]);

    final passwordHash = PasswordHasher.hashPassword(password);
    final user = {
      'id': 1,
      'business_id': 1,
      'branch_id': 1,
      'name': ownerName,
      'email': email,
      'phone': phone,
      'password_hash': passwordHash,
      'role': 'Admin',
      'is_active': true,
      'permissions': ['all'],
    };
    _store.setCollection('users', [user]);

    await _store.save();

    final token = "local_jwt_token_1_${DateTime.now().millisecondsSinceEpoch}";
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("auth_token", token);
    await prefs.setInt("current_user_id", 1);

    return {
      'token': token,
      'user': user,
      'business': business,
      'branch': branch,
    };
  }

  Future<Map<String, dynamic>?> getCurrentSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    if (token == null) return null;

    final userId = prefs.getInt("current_user_id") ?? 1;
    final users = _store.getCollection('users');
    final user = users.firstWhere((u) => u['id'] == userId, orElse: () => users.isNotEmpty ? users.first : {});
    if (user.isEmpty) return null;

    final business = _store.getDocument('business');
    final branches = _store.getCollection('branches');
    final branchId = prefs.getInt("active_branch_id") ?? (user['branch_id'] ?? 1);
    final branch = branches.firstWhere((b) => b['id'] == branchId, orElse: () => branches.isNotEmpty ? branches.first : {});

    return {
      'user': user,
      'business': business,
      'branch': branch,
      'token': token,
    };
  }

  Future<void> switchBranch(int branchId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("active_branch_id", branchId);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("auth_token");
    await prefs.remove("current_user_id");
    await prefs.remove("active_branch_id");
  }
}
