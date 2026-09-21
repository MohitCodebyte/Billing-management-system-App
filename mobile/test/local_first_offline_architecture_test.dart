import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/storage/local_store.dart';
import 'package:mobile/core/security/password_hasher.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/repositories/auth_repository.dart';
import 'package:mobile/repositories/product_repository.dart';
import 'package:mobile/repositories/customer_repository.dart';
import 'package:mobile/repositories/invoice_repository.dart';
import 'package:mobile/repositories/inventory_repository.dart';
import 'package:mobile/repositories/purchase_repository.dart';
import 'package:mobile/repositories/supplier_repository.dart';
import 'package:mobile/repositories/expense_repository.dart';
import 'package:mobile/repositories/return_repository.dart';
import 'package:mobile/repositories/employee_repository.dart';
import 'package:mobile/repositories/branch_repository.dart';
import 'package:mobile/repositories/notification_repository.dart';
import 'package:mobile/repositories/settings_repository.dart';
import 'package:mobile/repositories/report_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late String testDbPath;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('bharat_ledger_test_');
    testDbPath = '${tempDir.path}/test_ledger_data.json';
    await LocalStore().init(filePath: testDbPath);
    await ApiClient().init();
  });

  tearDown(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('1. Local Storage & Security Tests', () {
    test('LocalStore initializes with complete seed data without any database', () {
      final store = LocalStore();
      expect(store.isInitialized, isTrue);

      final business = store.getDocument('business');
      expect(business['name'], contains('Bharat Steels'));

      final users = store.getCollection('users');
      expect(users.length, greaterThanOrEqualTo(2));

      final products = store.getCollection('products');
      expect(products.length, greaterThanOrEqualTo(5));

      final customers = store.getCollection('customers');
      expect(customers.length, greaterThanOrEqualTo(2));
    });

    test('PasswordHasher verifies seeded passwords correctly and rejects invalid ones', () {
      final hashed = PasswordHasher.hashPassword('admin123');
      expect(PasswordHasher.verifyPassword('admin123', hashed), isTrue);
      expect(PasswordHasher.verifyPassword('wrongpass', hashed), isFalse);

      final cashierHash = PasswordHasher.hashPassword('cashier123');
      expect(PasswordHasher.verifyPassword('cashier123', cashierHash), isTrue);
    });

    test('Backup export and restore operates seamlessly via JSON', () async {
      final store = LocalStore();
      final exportedJson = store.exportJsonString();
      expect(exportedJson, contains('Bharat Steels'));
      expect(exportedJson, contains('admin@bharatledger.com'));

      // Modify business name
      store.setDocument('business', {'name': 'Modified Corp'});
      expect(store.getDocument('business')['name'], equals('Modified Corp'));

      // Restore from backup
      final success = await store.restoreFromJsonString(exportedJson);
      expect(success, isTrue);
      expect(store.getDocument('business')['name'], contains('Bharat Steels'));
    });
  });

  group('2. Offline Authentication & RBAC Tests', () {
    test('Admin login with admin@bharatledger.com succeeds', () async {
      final authRepo = AuthRepository();
      final res = await authRepo.login('admin@bharatledger.com', 'admin123');

      expect(res, isNotNull);
      expect(res!['user']['email'], equals('admin@bharatledger.com'));
      expect(res['user']['role'], equals('Admin'));
      expect((res['user']['permissions'] as List), contains('all'));
      expect(res['token'], isNotEmpty);
    });

    test('Cashier login with cashier@bharatledger.com succeeds with restricted permissions', () async {
      final authRepo = AuthRepository();
      final res = await authRepo.login('cashier@bharatledger.com', 'cashier123');

      expect(res, isNotNull);
      expect(res!['user']['email'], equals('cashier@bharatledger.com'));
      expect(res['user']['role'], equals('Cashier'));
      final perms = res['user']['permissions'] as List;
      expect(perms, contains('billing.view'));
      expect(perms, isNot(contains('employees.view')));
      expect(perms, isNot(contains('all')));
    });

    test('Login with incorrect password fails gracefully', () async {
      final authRepo = AuthRepository();
      final res = await authRepo.login('admin@bharatledger.com', 'wrongpassword');
      expect(res, isNull);
    });

    test('OTP login with 1234 succeeds offline', () async {
      final authRepo = AuthRepository();
      final res = await authRepo.verifyOtp('+91 98230 12345', '1234');
      expect(res, isNotNull);
      expect(res!['user']['role'], equals('Admin'));
    });
  });

  group('3. Offline Products & Inventory Tests', () {
    test('Product CRUD and search operate locally', () async {
      final prodRepo = ProductRepository();
      final list = prodRepo.getAll();
      expect(list.length, greaterThanOrEqualTo(5));

      final searchValve = prodRepo.getAll(search: 'Valve');
      expect(searchValve.length, greaterThanOrEqualTo(2));

      final lowStock = prodRepo.getAll(lowStock: true);
      expect(lowStock.any((p) => p['name'].toString().contains('Hex Bolt')), isTrue);

      final newProd = await prodRepo.create({
        'name': 'Industrial Flange 4 Inch',
        'selling_price': 850.0,
        'purchase_price': 600.0,
        'initial_stock': 30.0,
        'min_stock': 10.0,
      });
      expect(newProd['id'], isNotNull);

      final fetched = prodRepo.getById(newProd['id']);
      expect(fetched?['name'], equals('Industrial Flange 4 Inch'));
    });

    test('Inventory adjustment updates stock and logs movement audit trail', () async {
      final prodRepo = ProductRepository();
      final invRepo = InventoryRepository();

      final prod = prodRepo.getAll().first;
      final initialStock = (prod['current_stock'] as num).toDouble();

      await invRepo.adjustStock(
        productId: prod['id'],
        quantity: 15.0,
        movementType: 'IN',
        notes: 'Warehouse shipment arrived',
      );

      final updatedProd = prodRepo.getById(prod['id']);
      expect((updatedProd!['current_stock'] as num).toDouble(), equals(initialStock + 15.0));

      final history = invRepo.getStockHistory(productId: prod['id']);
      expect(history.isNotEmpty, isTrue);
      expect(history.first['movement_type'], equals('IN'));
      expect(history.first['quantity'], equals(15.0));
    });
  });

  group('4. Complete Offline Billing & POS Flow Tests', () {
    test('Full invoice creation flow: cart -> invoice -> stock deduction -> ledger debit/credit', () async {
      final invRepo = InvoiceRepository();
      final prodRepo = ProductRepository();
      final custRepo = CustomerRepository();

      final customer = custRepo.getAll().first;
      final product = prodRepo.getAll().first;
      final stockBefore = (product['current_stock'] as num).toDouble();
      final balanceBefore = (customer['current_balance'] as num).toDouble();

      final invoicePayload = {
        'customer_id': customer['id'],
        'items': [
          {
            'product_id': product['id'],
            'product_name': product['name'],
            'quantity': 2.0,
            'unit_price': product['selling_price'],
            'discount_percent': 0.0,
            'gst_rate': product['gst_rate'],
          }
        ],
        'additional_charges': 0.0,
        'global_discount': 0.0,
        'payment': {
          'amount': 1000.0,
          'payment_method': 'CASH',
        }
      };

      final invoice = await invRepo.createInvoice(invoicePayload);
      expect(invoice['id'], isNotNull);
      expect(invoice['invoice_number'], contains('BL-INV-'));

      final grandTotal = (invoice['grand_total'] as num).toDouble();
      final paidAmount = (invoice['paid_amount'] as num).toDouble();
      final balanceDue = (invoice['balance_amount'] as num).toDouble();
      expect(paidAmount, equals(1000.0));
      expect(balanceDue, equals(grandTotal - 1000.0));

      // Verify product stock deduction
      final productAfter = prodRepo.getById(product['id']);
      expect((productAfter!['current_stock'] as num).toDouble(), equals(stockBefore - 2.0));

      // Verify customer balance increase by balance amount
      final customerAfter = custRepo.getById(customer['id']);
      expect((customerAfter!['current_balance'] as num).toDouble(), equals(balanceBefore + balanceDue));

      // Verify subsequent payment against invoice
      final payOk = await invRepo.recordPayment(invoice['id'], balanceDue, 'UPI');
      expect(payOk, isTrue);

      final paidInvoice = invRepo.getById(invoice['id']);
      expect(paidInvoice!['status'], equals('PAID'));
      expect((paidInvoice['balance_amount'] as num).toDouble(), equals(0.0));
    });
  });

  group('5. Offline Purchases, Returns & Ledgers Tests', () {
    test('Purchase creates PO, adds stock, and updates supplier payable', () async {
      final purRepo = PurchaseRepository();
      final supRepo = SupplierRepository();
      final prodRepo = ProductRepository();

      final supplier = supRepo.getAll().first;
      final product = prodRepo.getAll().first;
      final stockBefore = (product['current_stock'] as num).toDouble();
      final payableBefore = (supplier['current_payable'] as num).toDouble();

      final po = await purRepo.createPurchase({
        'supplier_id': supplier['id'],
        'items': [
          {
            'product_id': product['id'],
            'quantity': 10.0,
            'unit_price': product['purchase_price'],
            'gst_rate': product['gst_rate'],
          }
        ],
        'payment': {
          'amount': 0.0,
        }
      });

      expect(po['purchase_number'], contains('BL-PO-'));

      // Check stock increased
      final prodAfter = prodRepo.getById(product['id']);
      expect((prodAfter!['current_stock'] as num).toDouble(), equals(stockBefore + 10.0));

      // Check supplier payable increased
      final supAfter = supRepo.getById(supplier['id']);
      expect((supAfter!['current_payable'] as num).toDouble(), greaterThan(payableBefore));
    });

    test('Sales return restocks inventory and issues credit note', () async {
      final invRepo = InvoiceRepository();
      final retRepo = ReturnRepository();
      final prodRepo = ProductRepository();

      // Create an invoice first
      final prod = prodRepo.getAll().first;
      final invoice = await invRepo.createInvoice({
        'customer_id': 1,
        'items': [
          {
            'product_id': prod['id'],
            'quantity': 5.0,
            'unit_price': 100.0,
            'gst_rate': 18.0,
          }
        ],
        'payment': {'amount': 0.0}
      });

      final stockBeforeReturn = (prodRepo.getById(prod['id'])!['current_stock'] as num).toDouble();

      final sReturn = await retRepo.createSalesReturn({
        'invoice_id': invoice['id'],
        'refund_type': 'CREDIT_NOTE',
        'reason': 'Customer returned 2 units',
        'items': [
          {
            'product_id': prod['id'],
            'product_name': prod['name'],
            'quantity': 2.0,
            'unit_price': 100.0,
          }
        ]
      });

      expect(sReturn['return_number'], contains('SR-'));

      // Verify stock restocked by 2
      final stockAfterReturn = (prodRepo.getById(prod['id'])!['current_stock'] as num).toDouble();
      expect(stockAfterReturn, equals(stockBeforeReturn + 2.0));

      // Verify credit note created
      final creditNotes = retRepo.getCreditNotes();
      expect(creditNotes.any((cn) => cn['invoice_id'] == invoice['id']), isTrue);
    });
  });

  group('6. Dynamic Reports Calculation Tests', () {
    test('ReportRepository calculates dashboard, sales analytics, P&L, and GST dynamically from local data', () {
      final reportRepo = ReportRepository();

      final dash = reportRepo.getDashboardStats();
      expect(dash.containsKey('today_sales'), isTrue);
      expect(dash.containsKey('total_receivables'), isTrue);
      expect(dash.containsKey('total_payables'), isTrue);
      expect(dash.containsKey('total_inventory_valuation'), isTrue);
      expect((dash['total_inventory_valuation'] as num).toDouble(), greaterThan(0));

      final sales = reportRepo.getSalesAnalytics();
      expect(sales.containsKey('total_sales'), isTrue);
      expect(sales.containsKey('trend'), isTrue);

      final pl = reportRepo.getProfitAndLoss();
      expect(pl.containsKey('total_revenue'), isTrue);
      expect(pl.containsKey('gross_profit'), isTrue);
      expect(pl.containsKey('net_profit'), isTrue);

      final gst = reportRepo.getGstReport();
      expect(gst.containsKey('outward'), isTrue);
      expect(gst.containsKey('inward_itc'), isTrue);
      expect(gst.containsKey('net_gst_payable'), isTrue);

      final inv = reportRepo.getInventoryReport();
      expect(inv.containsKey('total_items'), isTrue);
      expect(inv.containsKey('total_valuation'), isTrue);
      expect((inv['total_valuation'] as num).toDouble(), greaterThan(0));
    });
  });

  group('7. ApiClient Offline Dispatcher Bridge Tests', () {
    test('ApiClient routes calls locally without any network access', () async {
      final client = ApiClient();

      // Auth endpoint
      final loginRes = await client.post('/auth/login', body: {
        'email': 'admin@bharatledger.com',
        'password': 'admin123',
      });
      expect(loginRes.success, isTrue);
      expect(loginRes.data['user']['role'], equals('Admin'));

      // Dashboard endpoint
      final dashRes = await client.get('/dashboard');
      expect(dashRes.success, isTrue);
      expect(dashRes.data['total_products'], greaterThanOrEqualTo(5));

      // Products endpoint
      final prodRes = await client.get('/products');
      expect(prodRes.success, isTrue);
      expect((prodRes.data as List).length, greaterThanOrEqualTo(5));

      // Invoices endpoint
      final invRes = await client.get('/invoices');
      expect(invRes.success, isTrue);
    });
  });
}
