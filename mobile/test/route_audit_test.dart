import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobile/navigation/app_router.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/billing_provider.dart';
import 'package:mobile/providers/inventory_provider.dart';
import 'package:mobile/providers/customer_provider.dart';
import 'package:mobile/providers/supplier_provider.dart';
import 'package:mobile/providers/report_provider.dart';

void main() {
  group('Route Audit Tests — All 40 screens and aliases resolve', () {
    final expectedRoutes = [
      '/',
      '/splash',
      '/login',
      '/otp',
      '/otp-verify',
      '/register',
      '/business-setup',
      '/dashboard',
      '/billing',
      '/pos',
      '/product-search',
      '/cart-preview',
      '/payment',
      '/invoices',
      '/invoice-details',
      '/customers',
      '/customer-details',
      '/inventory',
      '/product-details',
      '/add-product',
      '/add-edit-product',
      '/stock',
      '/stock-management',
      '/stock-adjust',
      '/stock-history',
      '/purchases',
      '/purchase-details',
      '/new-purchase',
      '/suppliers',
      '/supplier-details',
      '/payments',
      '/expenses',
      '/sales-returns',
      '/purchase-returns',
      '/credit-debit-notes',
      '/customer-ledger',
      '/reports',
      '/sales-analytics',
      '/reports/sales',
      '/profit-loss',
      '/reports/profit-loss',
      '/gst-reports',
      '/reports/gst',
      '/inventory-reports',
      '/reports/inventory',
      '/employees',
      '/branches',
      '/notifications',
      '/settings',
      '/business-settings',
      '/printer-settings',
    ];

    for (final route in expectedRoutes) {
      testWidgets('Route $route resolves without "No route defined"', (tester) async {
        final generated = AppRouter.generateRoute(RouteSettings(name: route));
        expect(generated, isA<MaterialPageRoute>());

        final pageRoute = generated as MaterialPageRoute;

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => AuthProvider()),
              ChangeNotifierProvider(create: (_) => BillingProvider()),
              ChangeNotifierProvider(create: (_) => InventoryProvider()),
              ChangeNotifierProvider(create: (_) => CustomerProvider()),
              ChangeNotifierProvider(create: (_) => SupplierProvider()),
              ChangeNotifierProvider(create: (_) => ReportProvider()),
            ],
            child: MaterialApp(
              home: Builder(
                builder: (context) => pageRoute.builder(context),
              ),
            ),
          ),
        );

        if (route == '/' || route == '/splash') {
          await tester.pump(const Duration(seconds: 3));
        }

        // Verify that the "No route defined" error text is NEVER rendered
        expect(find.textContaining('No route defined'), findsNothing,
            reason: 'Route $route failed to resolve to a valid screen!');
      });
    }

    test('ApiConstants baseUrl is initialized properly', () {
      expect(ApiConstants.baseUrl, isNotEmpty);
      expect(ApiConstants.baseUrl.startsWith('http://'), isTrue);
      expect(ApiConstants.copyright, contains('NexvoraTech LLP'));
    });
  });
}
