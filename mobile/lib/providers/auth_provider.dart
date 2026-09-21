import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/models.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  BusinessModel? _business;
  BranchModel? _branch;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  BusinessModel? get business => _business;
  BranchModel? get branch => _branch;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => ApiClient().isAuthenticated;
  bool get isAdmin => user?.role.toLowerCase() == 'admin' || user?.role.toLowerCase() == 'owner';
  bool get isCashier => user?.role.toLowerCase() == 'cashier';
  bool get isManager => user?.role.toLowerCase() == 'manager';
  bool get isSalesperson => user?.role.toLowerCase() == 'salesperson';
  bool get isAccountant => user?.role.toLowerCase() == 'accountant';
  bool get isInventoryManager => user?.role.toLowerCase() == 'inventory manager' || user?.role.toLowerCase() == 'inventory_manager';

  bool hasPermission(String perm) {
    if (isAdmin) return true;
    if (user == null) return false;
    final perms = user!.permissions;
    if (perms.contains("all")) return true;
    if (perms.contains(perm)) return true;
    if (perm.contains('.')) {
      final module = perm.split('.').first;
      if (perms.contains(module)) return true;
    }
    return false;
  }

  Future<void> loadUserFromStorage() => checkAuth();

  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();

    await ApiClient().init();
    if (ApiClient().isAuthenticated) {
      final res = await ApiClient().get(ApiConstants.me);
      if (res.success && res.data != null) {
        final data = res.data is Map && res.data.containsKey('data') && res.data['data'] is Map
            ? res.data['data']
            : res.data;
        if (data['user'] != null) {
          _user = UserModel.fromJson(data['user']);
        }
        if (data['business'] != null) {
          _business = BusinessModel.fromJson(data['business']);
        }
        if (data['branch'] != null) {
          _branch = BranchModel.fromJson(data['branch']);
        }
      } else {
        ApiClient().setToken(null);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await ApiClient().post(ApiConstants.login, body: {
      'email': email,
      'password': password,
    });

    _isLoading = false;
    if (res.success && res.data != null) {
      final data = res.data is Map && res.data.containsKey('data') && res.data['data'] is Map
          ? res.data['data']
          : res.data;
      final token = data['token'] ?? res.data['token'];
      if (token != null) {
        ApiClient().setToken(token.toString());
      }
      final userData = data['user'] ?? res.data['user'];
      if (userData != null) {
        _user = UserModel.fromJson(userData);
      }
      final bizData = data['business'] ?? res.data['business'];
      if (bizData != null) {
        _business = BusinessModel.fromJson(bizData);
      }
      final branchData = data['branch'] ?? res.data['branch'];
      if (branchData != null) {
        _branch = BranchModel.fromJson(branchData);
      }
      notifyListeners();
      return true;
    } else {
      _errorMessage = res.error ?? 'Login failed';
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await ApiClient().post(ApiConstants.verifyOtp, body: {
      'phone': phone,
      'otp': otp,
    });

    _isLoading = false;
    if (res.success && res.data != null) {
      final data = res.data is Map && res.data.containsKey('data') && res.data['data'] is Map
          ? res.data['data']
          : res.data;
      final token = data['token'] ?? res.data['token'];
      if (token != null) {
        ApiClient().setToken(token.toString());
      }
      final userData = data['user'] ?? res.data['user'];
      if (userData != null) {
        _user = UserModel.fromJson(userData);
      }
      final bizData = data['business'] ?? res.data['business'];
      if (bizData != null) {
        _business = BusinessModel.fromJson(bizData);
      }
      final branchData = data['branch'] ?? res.data['branch'];
      if (branchData != null) {
        _branch = BranchModel.fromJson(branchData);
      }
      notifyListeners();
      return true;
    } else {
      _errorMessage = res.error ?? 'Invalid OTP';
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerBusiness({
    required String name,
    required String ownerName,
    required String phone,
    required String email,
    required String password,
    String? gstin,
    String? address,
    String? city,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await ApiClient().post(ApiConstants.registerBusiness, body: {
      'name': name,
      'owner_name': ownerName,
      'phone': phone,
      'email': email,
      'password': password,
      'gstin': gstin ?? '',
      'address': address ?? '',
      'city': city ?? '',
    });

    _isLoading = false;
    if (res.success && res.data != null) {
      final data = res.data;
      ApiClient().setToken(data['token']);
      if (data['user'] != null) {
        _user = UserModel.fromJson(data['user']);
      }
      if (data['business'] != null) {
        _business = BusinessModel.fromJson(data['business']);
      }
      if (data['branch'] != null) {
        _branch = BranchModel.fromJson(data['branch']);
      }
      notifyListeners();
      return true;
    } else {
      _errorMessage = res.error ?? 'Registration failed';
      notifyListeners();
      return false;
    }
  }

  Future<bool> switchBranch(int branchId) async {
    final res = await ApiClient().post(ApiConstants.switchBranch, body: {'branch_id': branchId});
    if (res.success && res.data != null) {
      if (res.data['branch'] != null) {
        _branch = BranchModel.fromJson(res.data['branch']);
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  void logout() {
    ApiClient().setToken(null);
    _user = null;
    _business = null;
    _branch = null;
    notifyListeners();
  }
}
