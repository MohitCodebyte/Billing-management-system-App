import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/models.dart';

class SupplierProvider extends ChangeNotifier {
  List<SupplierModel> _suppliers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<SupplierModel> get suppliers => _suppliers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchSuppliers({String? search}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final queryParams = <String, dynamic>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final res = await ApiClient().get(ApiConstants.suppliers, queryParams: queryParams);

    _isLoading = false;
    if (res.success && res.data != null) {
      final List raw = res.data;
      _suppliers = raw.map((json) => SupplierModel.fromJson(json)).toList();
    } else {
      _errorMessage = res.error ?? "Failed to load suppliers";
    }
    notifyListeners();
  }

  Future<bool> createSupplier(Map<String, dynamic> data) async {
    final res = await ApiClient().post(ApiConstants.suppliers, body: data);
    if (res.success) {
      await fetchSuppliers();
      return true;
    }
    return false;
  }
}
