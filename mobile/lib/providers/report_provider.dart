import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';

class ReportProvider extends ChangeNotifier {
  Map<String, dynamic>? _salesAnalytics;
  Map<String, dynamic>? _profitLoss;
  Map<String, dynamic>? _gstReport;
  Map<String, dynamic>? _inventoryReport;

  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic>? get salesAnalytics => _salesAnalytics;
  Map<String, dynamic>? get profitLoss => _profitLoss;
  Map<String, dynamic>? get gstReport => _gstReport;
  Map<String, dynamic>? get inventoryReport => _inventoryReport;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAllReports() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resSales = await ApiClient().get(ApiConstants.reportSales);
      if (resSales.success) _salesAnalytics = resSales.data;

      final resPl = await ApiClient().get(ApiConstants.reportProfitLoss);
      if (resPl.success) _profitLoss = resPl.data;

      final resGst = await ApiClient().get(ApiConstants.reportGst);
      if (resGst.success) _gstReport = resGst.data;

      final resInv = await ApiClient().get(ApiConstants.reportInventory);
      if (resInv.success) _inventoryReport = resInv.data;
    } catch (e) {
      _errorMessage = "Failed to load reports: $e";
    }

    _isLoading = false;
    notifyListeners();
  }
}
