import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/models.dart';

class CustomerProvider extends ChangeNotifier {
  List<CustomerModel> _customers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CustomerModel> get customers => _customers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchCustomers({String? search}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final queryParams = <String, dynamic>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final res = await ApiClient().get(ApiConstants.customers, queryParams: queryParams);

    _isLoading = false;
    if (res.success && res.data != null) {
      final List raw = res.data;
      _customers = raw.map((json) => CustomerModel.fromJson(json)).toList();
    } else {
      _errorMessage = res.error ?? "Failed to load customers";
    }
    notifyListeners();
  }

  Future<bool> createCustomer(Map<String, dynamic> data) async {
    final res = await ApiClient().post(ApiConstants.customers, body: data);
    if (res.success) {
      await fetchCustomers();
      return true;
    }
    return false;
  }
}
