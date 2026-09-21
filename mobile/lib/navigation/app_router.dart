import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/access_denied_screen.dart';

// Auth Screens (1-5)
import '../screens/auth/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/business_setup_screen.dart';

// Core Billing Screens (6-10)
import '../screens/billing/dashboard_screen.dart';
import '../screens/billing/pos_screen.dart';
import '../screens/billing/product_search_screen.dart';
import '../screens/billing/cart_preview_screen.dart';
import '../screens/billing/payment_screen.dart';

// Invoice, Customer, Inventory Screens (11-15)
import '../screens/invoices/invoice_list_screen.dart';
import '../screens/invoices/invoice_details_screen.dart';
import '../screens/customers/customers_list_screen.dart';
import '../screens/customers/customer_details_screen.dart';
import '../screens/inventory/inventory_screen.dart';

// Product, Stock, Purchases Screens (16-22)
import '../screens/inventory/product_details_screen.dart';
import '../screens/inventory/add_edit_product_screen.dart';
import '../screens/inventory/stock_management_screen.dart';
import '../screens/inventory/stock_history_screen.dart';
import '../screens/purchases/purchase_list_screen.dart';
import '../screens/purchases/purchase_details_screen.dart';
import '../screens/purchases/new_purchase_screen.dart';

// Supplier & Accounting Screens (23-30)
import '../screens/suppliers/suppliers_list_screen.dart';
import '../screens/suppliers/supplier_details_screen.dart';
import '../screens/accounting/payments_screen.dart';
import '../screens/accounting/expenses_screen.dart';
import '../screens/accounting/sales_returns_screen.dart';
import '../screens/accounting/purchase_returns_screen.dart';
import '../screens/accounting/credit_debit_notes_screen.dart';
import '../screens/accounting/customer_ledger_screen.dart';

// Reports Screens (31-35)
import '../screens/reports/reports_dashboard_screen.dart';
import '../screens/reports/sales_analytics_screen.dart';
import '../screens/reports/profit_loss_screen.dart';
import '../screens/reports/gst_reports_screen.dart';
import '../screens/reports/inventory_reports_screen.dart';

// Administration Screens (36-40)
import '../screens/admin/employees_screen.dart';
import '../screens/admin/branch_management_screen.dart';
import '../screens/admin/notifications_screen.dart';
import '../screens/admin/business_settings_screen.dart';
import '../screens/admin/printer_settings_screen.dart';

class ProtectedScreen extends StatelessWidget {
  final String? permission;
  final Widget child;

  const ProtectedScreen({
    super.key,
    this.permission,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    AuthProvider? auth;
    try {
      auth = Provider.of<AuthProvider>(context, listen: true);
    } catch (_) {
      return child;
    }

    if (auth != null) {
      if (!auth.isAuthenticated) {
        return const LoginScreen();
      }
      if (permission != null && !auth.hasPermission(permission!)) {
        return AccessDeniedScreen(requiredPermission: permission);
      }
    }
    return child;
  }
}

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // 1. Splash
      case '/':
      case '/splash':
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      // 2. Login
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      // 3. OTP Verification
      case '/otp':
      case '/otp-verify':
        final phone = settings.arguments as String? ?? '';
        return MaterialPageRoute(builder: (_) => OtpScreen(phone: phone));

      // 4. Business Registration
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      // 5. Business Setup
      case '/business-setup':
        return MaterialPageRoute(builder: (_) => const BusinessSetupScreen());

      // 6. Business Dashboard
      case '/dashboard':
        return MaterialPageRoute(builder: (_) => const ProtectedScreen(child: DashboardScreen()));

      // 7. Billing / POS
      case '/billing':
      case '/pos':
        return MaterialPageRoute(builder: (_) => const ProtectedScreen(permission: 'billing.view', child: PosScreen()));

      // 8. Product Search
      case '/product-search':
        return MaterialPageRoute(builder: (_) => const ProtectedScreen(permission: 'billing.view', child: ProductSearchScreen()));

      // 9. Cart / Invoice Preview
      case '/cart-preview':
        return MaterialPageRoute(builder: (_) => const ProtectedScreen(permission: 'billing.view', child: CartPreviewScreen()));

      // 10. Payment
      case '/payment':
        return MaterialPageRoute(builder: (_) => const ProtectedScreen(permission: 'payments.view', child: PaymentScreen()));

      // 11. Invoice List
      case '/invoices':
        return MaterialPageRoute(builder: (_) => const ProtectedScreen(permission: 'invoices.view', child: InvoiceListScreen()));

      // 12. Invoice Details
      case '/invoice-details':
        final invoiceId = settings.arguments as int? ?? 1;
        return MaterialPageRoute(builder: (_) => ProtectedScreen(permission: 'invoices.view', child: InvoiceDetailsScreen(invoiceId: invoiceId)));

      // 13. Customers List
      case '/customers':
        return MaterialPageRoute(builder: (_) => const ProtectedScreen(permission: 'customers.view', child: CustomersListScreen()));

      // 14. Customer Details
      case '/customer-details':
        final customerId = settings.arguments as int? ?? 1;
        return MaterialPageRoute(builder: (_) => ProtectedScreen(permission: 'customers.view', child: CustomerDetailsScreen(customerId: customerId)));

      // 15. Inventory
      case '/inventory':
        return MaterialPageRoute(builder: (_) => const ProtectedScreen(permission: 'products.view', child: InventoryScreen()));

      // 16. Product Details
      case '/product-details':
        final productId = settings.arguments as int? ?? 1;
        return MaterialPageRoute(builder: (_) => ProtectedScreen(permission: 'products.view', child: ProductDetailsScreen(productId: productId)));

      // 17. Add / Edit Product
      case '/add-product':
      case '/add-edit-product':
        final productId = settings.arguments as int?;
        return MaterialPageRoute(builder: (_) => ProtectedScreen(permission: 'products.create', child: AddEditProductScreen(productId: productId)));

      // 18. Stock Management
      case '/stock':
      case '/stock-management':
      case '/stock-adjust':
        return MaterialPageRoute(builder: (_) => const ProtectedScreen(permission: 'inventory.adjust', child: StockManagementScreen()));

      // 19. Stock History
      case '/stock-history':
        return MaterialPageRoute(builder: (_) => const ProtectedScreen(permission: 'stock.history', child: StockHistoryScreen()));

      // 20. Purchase List
      case '/purchases':
        return MaterialPageRoute(builder: (_) => const ProtectedScreen(permission: 'purchases.view', child: PurchaseListScreen()));

      // 21. Purchase Details
      case '/purchase-details':
        final purchaseId = settings.arguments as int? ?? 1;
        return MaterialPageRoute(builder: (_) => ProtectedScreen(permission: 'purchases.view', child: PurchaseDetailsScreen(purchaseId: purchaseId)));

      // 22. New Purchase
      case '/new-purchase':
        return MaterialPageRoute(builder: (_) => const ProtectedScreen(permission: 'purchases.create', child: NewPurchaseScreen()));

      // 23. Suppliers List
      case '/suppliers':
        return MaterialPageRoute(builder: (_) => const ProtectedScreen(permission: 'suppliers.view', child: SuppliersListScreen()));

      // 24. Supplier Details
      case '/supplier-details':
        final supplierId = settings.arguments as int? ?? 1;
        return MaterialPageRoute(builder: (_) => ProtectedScreen(permission: 'suppliers.view', child: SupplierDetailsScreen(supplierId: supplierId)));

      // 25. Payments & Receivables
      case '/payments':
        return MaterialPageRoute(builder: (_) => const ProtectedScreen(permission: 'payments.view', child: PaymentsScreen()));

      // 26. Expenses Management
      case '/expenses':
        return MaterialPageRoute(builder: (_) => const ProtectedScreen(permission: 'expenses.view', child: ExpensesScreen()));

      // 27. Sales Returns
      case '/sales-returns':
        return MaterialPageRoute(builder: (_) => const ProtectedScreen(permission: 'returns.sales', child: SalesReturnsScreen()));

      // 28. Purchase Returns
      case '/purchase-returns':
        return MaterialPageRoute(builder: (_) => const ProtectedScreen(permission: 'returns.purchases', child: PurchaseReturnsScreen()));

      // 29. Credit / Debit Notes
      case '/credit-debit-notes':
        return MaterialPageRoute(builder: (_) => const ProtectedScreen(permission: 'credit_debit.view', child: CreditDebitNotesScreen()));

      // 30. Customer Ledger
      case '/customer-ledger':
        final customerId = settings.arguments as int?;
        return MaterialPageRoute(builder: (_) => ProtectedScreen(permission: 'ledger.customer', child: CustomerLedgerScreen(initialCustomerId: customerId)));

      // 31. Reports Dashboard
      case '/reports':
        return MaterialPageRoute(builder: (_) => const ProtectedScreen(permission: 'reports.view', child: ReportsDashboardScreen()));

      // 32. Sales Analytics
      case '/reports/sales':
      case '/sales-analytics':
        return MaterialPageRoute(builder: (_) => const ProtectedScreen(permission: 'reports.sales', child: SalesAnalyticsScreen()));

      // 33. Profit & Loss
      case '/reports/profit-loss':
      case '/profit-loss':
        return MaterialPageRoute(builder: (_) => const ProtectedScreen(permission: 'reports.profit_loss', child: ProfitLossScreen()));

      // 34. GST / Tax Reports
      case '/reports/gst':
      case '/gst-reports':
        return MaterialPageRoute(builder: (_) => const ProtectedScreen(permission: 'reports.gst', child: GstReportsScreen()));

      // 35. Inventory Reports
      case '/reports/inventory':
      case '/inventory-reports':
        return MaterialPageRoute(builder: (_) => const ProtectedScreen(permission: 'reports.inventory', child: InventoryReportsScreen()));

      // 36. Employees & Roles
      case '/employees':
        return MaterialPageRoute(builder: (_) => const ProtectedScreen(permission: 'employees.view', child: EmployeesScreen()));

      // 37. Branch Management
      case '/branches':
        return MaterialPageRoute(builder: (_) => const ProtectedScreen(permission: 'branches.view', child: BranchManagementScreen()));

      // 38. Notifications Center
      case '/notifications':
        return MaterialPageRoute(builder: (_) => const ProtectedScreen(permission: 'notifications.view', child: NotificationsScreen()));

      // 39. Business Settings
      case '/settings':
      case '/business-settings':
        return MaterialPageRoute(builder: (_) => const ProtectedScreen(permission: 'settings.view', child: BusinessSettingsScreen()));

      // 40. Printer Settings
      case '/printer-settings':
        return MaterialPageRoute(builder: (_) => const ProtectedScreen(permission: 'billing.view', child: PrinterSettingsScreen()));

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
