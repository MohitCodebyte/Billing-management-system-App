import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/models.dart';

class InventoryProvider extends ChangeNotifier {
  List<ProductModel> _products = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ProductModel> get products => _products;
  List<Map<String, dynamic>> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchProducts({String? search, int? categoryId, bool? lowStock}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final queryParams = <String, dynamic>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (categoryId != null) queryParams['category_id'] = categoryId;
    if (lowStock != null && lowStock) queryParams['low_stock'] = true;

    final res = await ApiClient().get(ApiConstants.products, queryParams: queryParams);

    _isLoading = false;
    if (res.success && res.data != null) {
      final List raw = res.data;
      _products = raw.map((json) => ProductModel.fromJson(json)).toList();
    } else {
      _errorMessage = res.error ?? "Failed to load products";
    }
    notifyListeners();
  }

  Future<void> fetchCategories() async {
    final res = await ApiClient().get(ApiConstants.categories);
    if (res.success && res.data != null) {
      final List raw = res.data;
      _categories = List<Map<String, dynamic>>.from(raw);
      notifyListeners();
    }
  }

  Future<bool> createProduct(Map<String, dynamic> data) async {
    final res = await ApiClient().post(ApiConstants.products, body: data);
    if (res.success) {
      await fetchProducts();
      return true;
    }
    return false;
  }

  Future<bool> updateProduct(int id, Map<String, dynamic> data) async {
    final res = await ApiClient().put("${ApiConstants.products}/$id", body: data);
    if (res.success) {
      await fetchProducts();
      return true;
    }
    return false;
  }

  Future<bool> adjustStock({required int productId, required double quantity, required String movementType, String? notes}) async {
    final res = await ApiClient().post(ApiConstants.inventoryAdjust, body: {
      'product_id': productId,
      'quantity': quantity,
      'movement_type': movementType,
      'notes': notes ?? '',
    });
    if (res.success) {
      await fetchProducts();
      return true;
    }
    return false;
  }
}
