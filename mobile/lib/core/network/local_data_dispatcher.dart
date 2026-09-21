import '../constants/api_constants.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/product_repository.dart';
import '../../repositories/customer_repository.dart';
import '../../repositories/invoice_repository.dart';
import '../../repositories/payment_repository.dart';
import '../../repositories/inventory_repository.dart';
import '../../repositories/purchase_repository.dart';
import '../../repositories/supplier_repository.dart';
import '../../repositories/expense_repository.dart';
import '../../repositories/return_repository.dart';
import '../../repositories/employee_repository.dart';
import '../../repositories/branch_repository.dart';
import '../../repositories/notification_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../repositories/report_repository.dart';
import 'api_client.dart';

class LocalDataDispatcher {
  static final LocalDataDispatcher _instance = LocalDataDispatcher._internal();
  factory LocalDataDispatcher() => _instance;
  LocalDataDispatcher._internal();

  final _authRepo = AuthRepository();
  final _productRepo = ProductRepository();
  final _customerRepo = CustomerRepository();
  final _invoiceRepo = InvoiceRepository();
  final _paymentRepo = PaymentRepository();
  final _inventoryRepo = InventoryRepository();
  final _purchaseRepo = PurchaseRepository();
  final _supplierRepo = SupplierRepository();
  final _expenseRepo = ExpenseRepository();
  final _returnRepo = ReturnRepository();
  final _employeeRepo = EmployeeRepository();
  final _branchRepo = BranchRepository();
  final _notifRepo = NotificationRepository();
  final _settingsRepo = SettingsRepository();
  final _reportRepo = ReportRepository();

  Future<ApiResponse<dynamic>> handleGet(String endpoint, {Map<String, dynamic>? queryParams}) async {
    try {
      final clean = _cleanEndpoint(endpoint);

      // Auth
      if (clean == ApiConstants.me) {
        final session = await _authRepo.getCurrentSession();
        if (session != null) {
          return ApiResponse.success(session);
        }
        return ApiResponse.error("No active session");
      }

      // Dashboard
      if (clean == ApiConstants.dashboard) {
        final stats = _reportRepo.getDashboardStats();
        return ApiResponse.success(stats);
      }

      // Products & Categories
      if (clean == ApiConstants.categories) {
        final cats = _productRepo.getCategories();
        return ApiResponse.success(cats);
      }
      if (clean == ApiConstants.products) {
        final search = queryParams?['search']?.toString();
        final catId = (queryParams?['category_id'] as num?)?.toInt();
        final lowStock = queryParams?['low_stock'] == true || queryParams?['low_stock'] == 'true';
        final prods = _productRepo.getAll(search: search, categoryId: catId, lowStock: lowStock);
        return ApiResponse.success(prods);
      }
      if (clean.startsWith("${ApiConstants.products}/")) {
        final id = int.tryParse(clean.replaceFirst("${ApiConstants.products}/", "")) ?? 0;
        final prod = _productRepo.getById(id);
        if (prod != null) return ApiResponse.success(prod);
        return ApiResponse.error("Product not found");
      }

      // Inventory
      if (clean == ApiConstants.inventoryHistory) {
        final history = _inventoryRepo.getStockHistory();
        return ApiResponse.success(history);
      }
      if (clean == ApiConstants.inventoryStock) {
        final prods = _productRepo.getAll();
        return ApiResponse.success(prods);
      }

      // Invoices
      if (clean == ApiConstants.invoices) {
        final status = queryParams?['status']?.toString();
        final search = queryParams?['search']?.toString();
        final invs = _invoiceRepo.getAll(status: status, search: search);
        return ApiResponse.success(invs);
      }
      if (clean.startsWith("${ApiConstants.invoices}/")) {
        final id = int.tryParse(clean.replaceFirst("${ApiConstants.invoices}/", "")) ?? 0;
        final inv = _invoiceRepo.getById(id);
        if (inv != null) return ApiResponse.success(inv);
        return ApiResponse.error("Invoice not found");
      }

      // Customers
      if (clean == ApiConstants.customers) {
        final search = queryParams?['search']?.toString();
        final custs = _customerRepo.getAll(search: search);
        return ApiResponse.success(custs);
      }
      if (clean.startsWith("${ApiConstants.customers}/")) {
        final id = int.tryParse(clean.replaceFirst("${ApiConstants.customers}/", "")) ?? 0;
        final cust = _customerRepo.getById(id);
        if (cust != null) return ApiResponse.success(cust);
        return ApiResponse.error("Customer not found");
      }

      // Suppliers
      if (clean == ApiConstants.suppliers) {
        final search = queryParams?['search']?.toString();
        final sups = _supplierRepo.getAll(search: search);
        return ApiResponse.success(sups);
      }
      if (clean.startsWith("${ApiConstants.suppliers}/")) {
        final id = int.tryParse(clean.replaceFirst("${ApiConstants.suppliers}/", "")) ?? 0;
        final sup = _supplierRepo.getById(id);
        if (sup != null) return ApiResponse.success(sup);
        return ApiResponse.error("Supplier not found");
      }

      // Purchases
      if (clean == ApiConstants.purchases) {
        final status = queryParams?['status']?.toString();
        final search = queryParams?['search']?.toString();
        final pos = _purchaseRepo.getAll(status: status, search: search);
        return ApiResponse.success(pos);
      }
      if (clean.startsWith("${ApiConstants.purchases}/")) {
        final id = int.tryParse(clean.replaceFirst("${ApiConstants.purchases}/", "")) ?? 0;
        final po = _purchaseRepo.getById(id);
        if (po != null) return ApiResponse.success(po);
        return ApiResponse.error("Purchase order not found");
      }

      // Expenses
      if (clean == ApiConstants.expenses) {
        final exps = _expenseRepo.getAll();
        return ApiResponse.success(exps);
      }
      if (clean == ApiConstants.expenseCategories) {
        final cats = _expenseRepo.getCategories();
        return ApiResponse.success(cats);
      }

      // Returns & Notes
      if (clean == ApiConstants.salesReturns) {
        final rets = _returnRepo.getSalesReturns();
        return ApiResponse.success(rets);
      }
      if (clean == ApiConstants.purchaseReturns) {
        final rets = _returnRepo.getPurchaseReturns();
        return ApiResponse.success(rets);
      }
      if (clean == ApiConstants.creditNotes) {
        final notes = _returnRepo.getCreditNotes();
        return ApiResponse.success(notes);
      }
      if (clean == ApiConstants.debitNotes) {
        final notes = _returnRepo.getDebitNotes();
        return ApiResponse.success(notes);
      }

      // Reports
      if (clean == ApiConstants.reportSales) {
        final rep = _reportRepo.getSalesAnalytics();
        return ApiResponse.success(rep);
      }
      if (clean == ApiConstants.reportProfitLoss) {
        final rep = _reportRepo.getProfitAndLoss();
        return ApiResponse.success(rep);
      }
      if (clean == ApiConstants.reportGst) {
        final rep = _reportRepo.getGstReport();
        return ApiResponse.success(rep);
      }
      if (clean == ApiConstants.reportInventory) {
        final rep = _reportRepo.getInventoryReport();
        return ApiResponse.success(rep);
      }

      // Administration
      if (clean == ApiConstants.employees) {
        final search = queryParams?['search']?.toString();
        final role = queryParams?['role']?.toString();
        final emps = _employeeRepo.getAll(search: search, role: role);
        return ApiResponse.success(emps);
      }
      if (clean == ApiConstants.branches) {
        final branches = _branchRepo.getAll();
        return ApiResponse.success(branches);
      }
      if (clean == ApiConstants.businessSettings) {
        final set = _settingsRepo.getBusinessSettings();
        return ApiResponse.success(set);
      }
      if (clean == ApiConstants.printerSettings) {
        final pSet = _settingsRepo.getPrinterSettings();
        return ApiResponse.success(pSet);
      }
      if (clean == ApiConstants.notifications) {
        final notifs = _notifRepo.getAll();
        return ApiResponse.success(notifs);
      }

      return ApiResponse.error("Unknown GET endpoint: $clean");
    } catch (e) {
      return ApiResponse.error("Error processing GET $endpoint: $e");
    }
  }

  Future<ApiResponse<dynamic>> handlePost(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final clean = _cleanEndpoint(endpoint);
      final b = body ?? {};

      // Auth
      if (clean == ApiConstants.login) {
        final email = b['email']?.toString() ?? '';
        final pass = b['password']?.toString() ?? '';
        final res = await _authRepo.login(email, pass);
        if (res != null) {
          return ApiResponse.success(res);
        }
        return ApiResponse.error("Invalid email or password");
      }

      if (clean == ApiConstants.verifyOtp) {
        final phone = b['phone']?.toString() ?? '';
        final otp = b['otp']?.toString() ?? '';
        final res = await _authRepo.verifyOtp(phone, otp);
        if (res != null) {
          return ApiResponse.success(res);
        }
        return ApiResponse.error("Invalid OTP. Development OTP is 1234");
      }

      if (clean == ApiConstants.registerBusiness) {
        final res = await _authRepo.registerBusiness(
          name: b['name'] ?? 'Bharat Business',
          ownerName: b['owner_name'] ?? 'Owner',
          phone: b['phone'] ?? '',
          email: b['email'] ?? '',
          password: b['password'] ?? 'admin123',
          gstin: b['gstin'],
          address: b['address'],
          city: b['city'],
        );
        return ApiResponse.success(res);
      }

      // Billing & Invoices
      if (clean == ApiConstants.invoices) {
        final inv = await _invoiceRepo.createInvoice(b);
        return ApiResponse.success({'invoice': inv});
      }
      if (clean.contains("/payments")) {
        // Record payment against invoice: /invoices/{id}/payments
        final match = RegExp(r'/invoices/(\d+)/payments').firstMatch(clean);
        if (match != null) {
          final invId = int.tryParse(match.group(1)!) ?? 0;
          final amt = (b['amount'] as num? ?? 0.0).toDouble();
          final method = b['payment_method']?.toString() ?? 'CASH';
          final success = await _invoiceRepo.recordPayment(invId, amt, method, notes: b['notes']);
          if (success) return ApiResponse.success({'success': true});
          return ApiResponse.error("Failed to record payment");
        }
      }

      // Products & Categories
      if (clean == ApiConstants.products) {
        final prod = await _productRepo.create(b);
        return ApiResponse.success(prod);
      }
      if (clean == ApiConstants.categories) {
        final name = b['name']?.toString() ?? 'Category';
        final desc = b['description']?.toString() ?? '';
        final cat = await _productRepo.createCategory(name, desc);
        return ApiResponse.success(cat);
      }

      // Inventory
      if (clean == ApiConstants.inventoryAdjust) {
        final pId = (b['product_id'] as num?)?.toInt() ?? 0;
        final qty = (b['quantity'] as num? ?? 0.0).toDouble();
        final type = b['movement_type']?.toString() ?? 'IN';
        final notes = b['notes']?.toString();
        final ok = await _inventoryRepo.adjustStock(productId: pId, quantity: qty, movementType: type, notes: notes);
        if (ok) return ApiResponse.success({'success': true});
        return ApiResponse.error("Failed to adjust inventory stock");
      }

      // Customers
      if (clean == ApiConstants.customers) {
        final cust = await _customerRepo.create(b);
        return ApiResponse.success(cust);
      }

      // Suppliers
      if (clean == ApiConstants.suppliers) {
        final sup = await _supplierRepo.create(b);
        return ApiResponse.success(sup);
      }

      // Purchases
      if (clean == ApiConstants.purchases) {
        final po = await _purchaseRepo.createPurchase(b);
        return ApiResponse.success(po);
      }

      // Expenses
      if (clean == ApiConstants.expenses) {
        final exp = await _expenseRepo.create(b);
        return ApiResponse.success(exp);
      }

      // Returns
      if (clean == ApiConstants.salesReturns) {
        final ret = await _returnRepo.createSalesReturn(b);
        return ApiResponse.success(ret);
      }
      if (clean == ApiConstants.purchaseReturns) {
        final ret = await _returnRepo.createPurchaseReturn(b);
        return ApiResponse.success(ret);
      }

      // Employees
      if (clean == ApiConstants.employees) {
        final emp = await _employeeRepo.create(b);
        return ApiResponse.success(emp);
      }
      if (clean.endsWith("/toggle-status")) {
        final match = RegExp(r'/employees/(\d+)/toggle-status').firstMatch(clean);
        if (match != null) {
          final id = int.tryParse(match.group(1)!) ?? 0;
          final ok = await _employeeRepo.toggleStatus(id);
          if (ok) return ApiResponse.success({'success': true});
        }
      }

      // Branches
      if (clean == ApiConstants.branches) {
        final br = await _branchRepo.create(b);
        return ApiResponse.success(br);
      }
      if (clean == ApiConstants.switchBranch) {
        final brId = (b['branch_id'] as num?)?.toInt() ?? 1;
        await _authRepo.switchBranch(brId);
        return ApiResponse.success({'success': true});
      }

      // Notifications
      if (clean.endsWith("/read-all")) {
        await _notifRepo.markAllAsRead();
        return ApiResponse.success({'success': true});
      }
      if (clean.contains("/notifications/") && clean.endsWith("/read")) {
        final match = RegExp(r'/notifications/(\d+)/read').firstMatch(clean);
        if (match != null) {
          final id = int.tryParse(match.group(1)!) ?? 0;
          await _notifRepo.markAsRead(id);
          return ApiResponse.success({'success': true});
        }
      }

      return ApiResponse.error("Unknown POST endpoint: $clean");
    } catch (e) {
      return ApiResponse.error("Error processing POST $endpoint: $e");
    }
  }

  Future<ApiResponse<dynamic>> handlePut(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final clean = _cleanEndpoint(endpoint);
      final b = body ?? {};

      // Settings
      if (clean == ApiConstants.businessSettings) {
        await _settingsRepo.updateBusinessSettings(b);
        return ApiResponse.success({'success': true});
      }
      if (clean == ApiConstants.printerSettings) {
        await _settingsRepo.updatePrinterSettings(b);
        return ApiResponse.success({'success': true});
      }

      // Products update: /products/{id}
      if (clean.startsWith("${ApiConstants.products}/")) {
        final id = int.tryParse(clean.replaceFirst("${ApiConstants.products}/", "")) ?? 0;
        final updated = await _productRepo.update(id, b);
        if (updated != null) return ApiResponse.success(updated);
        return ApiResponse.error("Product not found");
      }

      // Customers update: /customers/{id}
      if (clean.startsWith("${ApiConstants.customers}/")) {
        final id = int.tryParse(clean.replaceFirst("${ApiConstants.customers}/", "")) ?? 0;
        final updated = await _customerRepo.update(id, b);
        if (updated != null) return ApiResponse.success(updated);
        return ApiResponse.error("Customer not found");
      }

      // Suppliers update: /suppliers/{id}
      if (clean.startsWith("${ApiConstants.suppliers}/")) {
        final id = int.tryParse(clean.replaceFirst("${ApiConstants.suppliers}/", "")) ?? 0;
        final updated = await _supplierRepo.update(id, b);
        if (updated != null) return ApiResponse.success(updated);
        return ApiResponse.error("Supplier not found");
      }

      // Employees update: /employees/{id}
      if (clean.startsWith("${ApiConstants.employees}/")) {
        final id = int.tryParse(clean.replaceFirst("${ApiConstants.employees}/", "")) ?? 0;
        final updated = await _employeeRepo.update(id, b);
        if (updated != null) return ApiResponse.success(updated);
        return ApiResponse.error("Employee not found");
      }

      // Branches update: /branches/{id}
      if (clean.startsWith("${ApiConstants.branches}/")) {
        final id = int.tryParse(clean.replaceFirst("${ApiConstants.branches}/", "")) ?? 0;
        final updated = await _branchRepo.update(id, b);
        if (updated != null) return ApiResponse.success(updated);
        return ApiResponse.error("Branch not found");
      }

      return ApiResponse.error("Unknown PUT endpoint: $clean");
    } catch (e) {
      return ApiResponse.error("Error processing PUT $endpoint: $e");
    }
  }

  Future<ApiResponse<dynamic>> handleDelete(String endpoint) async {
    try {
      final clean = _cleanEndpoint(endpoint);

      if (clean.startsWith("${ApiConstants.products}/")) {
        final id = int.tryParse(clean.replaceFirst("${ApiConstants.products}/", "")) ?? 0;
        final ok = await _productRepo.delete(id);
        if (ok) return ApiResponse.success({'success': true});
        return ApiResponse.error("Product not found");
      }

      if (clean.startsWith("${ApiConstants.customers}/")) {
        final id = int.tryParse(clean.replaceFirst("${ApiConstants.customers}/", "")) ?? 0;
        final ok = await _customerRepo.delete(id);
        if (ok) return ApiResponse.success({'success': true});
        return ApiResponse.error("Customer not found");
      }

      if (clean.startsWith("${ApiConstants.suppliers}/")) {
        final id = int.tryParse(clean.replaceFirst("${ApiConstants.suppliers}/", "")) ?? 0;
        final ok = await _supplierRepo.delete(id);
        if (ok) return ApiResponse.success({'success': true});
        return ApiResponse.error("Supplier not found");
      }

      if (clean.startsWith("${ApiConstants.employees}/")) {
        final id = int.tryParse(clean.replaceFirst("${ApiConstants.employees}/", "")) ?? 0;
        final ok = await _employeeRepo.delete(id);
        if (ok) return ApiResponse.success({'success': true});
        return ApiResponse.error("Employee not found");
      }

      if (clean.startsWith("${ApiConstants.branches}/")) {
        final id = int.tryParse(clean.replaceFirst("${ApiConstants.branches}/", "")) ?? 0;
        final ok = await _branchRepo.delete(id);
        if (ok) return ApiResponse.success({'success': true});
        return ApiResponse.error("Branch cannot be deleted");
      }

      return ApiResponse.error("Unknown DELETE endpoint: $clean");
    } catch (e) {
      return ApiResponse.error("Error processing DELETE $endpoint: $e");
    }
  }

  String _cleanEndpoint(String endpoint) {
    var ep = endpoint.trim();

    // Remove any accidental API URL if an old caller still passes one.
    ep = ep.replaceFirst(
      RegExp(r'^https?://[^/]+/api', caseSensitive: false),
      '',
    );

    if (!ep.startsWith("/")) {
      ep = "/$ep";
    }

    return ep;
  }
}
