import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/models/models.dart';
import 'package:mobile/widgets/custom_drawer.dart';
import 'package:mobile/widgets/access_denied_screen.dart';
import 'package:mobile/navigation/app_router.dart';

class MockAuthProvider extends AuthProvider {
  UserModel? _mockUser;
  bool _mockAuth = true;

  @override
  UserModel? get user => _mockUser;

  @override
  bool get isAuthenticated => _mockAuth;

  void setMockUser(UserModel? u, {bool isAuth = true}) {
    _mockUser = u;
    _mockAuth = isAuth;
    notifyListeners();
  }
}

void main() {
  group('RBAC Navigation & Route Guard Tests', () {
    testWidgets('CustomDrawer dynamically hides restricted items for Cashier', (WidgetTester tester) async {
      final mockAuth = MockAuthProvider();
      mockAuth.setMockUser(
        UserModel(
          id: 4,
          name: 'Cashier Terminal',
          email: 'cashier@bharatledger.com',
          phone: '9823099999',
          role: 'Cashier',
          permissions: [
            'dashboard.view',
            'billing.view',
            'billing.create',
            'invoices.view',
            'customers.view',
            'payments.view',
            'notifications.view',
          ],
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: mockAuth,
          child: const MaterialApp(
            home: Scaffold(
              drawer: CustomDrawer(),
            ),
          ),
        ),
      );

      // Open drawer
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Authorized items MUST be visible
      expect(find.text('6. Business Dashboard'), findsOneWidget);
      expect(find.text('7. Billing / POS'), findsOneWidget);
      expect(find.text('11. Invoice Management'), findsOneWidget);
      expect(find.text('13. Customers Management'), findsOneWidget);
      expect(find.text('25. Payments & Receivables'), findsOneWidget);
      expect(find.text('38. Notifications Center'), findsOneWidget);

      // Restricted items MUST NOT be visible for Cashier
      expect(find.text('36. Employees & Roles'), findsNothing);
      expect(find.text('37. Branch Management'), findsNothing);
      expect(find.text('39. Business Settings'), findsNothing);
      expect(find.text('33. Profit & Loss'), findsNothing);
      expect(find.text('34. GST / Tax Reports'), findsNothing);
      expect(find.text('35. Inventory Reports'), findsNothing);
      expect(find.text('20. Purchase List'), findsNothing);
      expect(find.text('22. New Purchase'), findsNothing);
      expect(find.text('23. Suppliers List'), findsNothing);
      expect(find.text('18. Stock Management'), findsNothing);
      expect(find.text('19. Stock History'), findsNothing);
    });

    testWidgets('CustomDrawer shows all items for Admin', (WidgetTester tester) async {
      final mockAuth = MockAuthProvider();
      mockAuth.setMockUser(
        UserModel(
          id: 1,
          name: 'Admin User',
          email: 'admin@bharatledger.com',
          phone: '9823012345',
          role: 'Admin',
          permissions: ['all'],
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: mockAuth,
          child: const MaterialApp(
            home: Scaffold(
              drawer: CustomDrawer(),
            ),
          ),
        ),
      );

      // Open drawer
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // All major admin items should exist
      expect(find.text('6. Business Dashboard'), findsOneWidget);
      expect(find.text('7. Billing / POS'), findsOneWidget);
      expect(find.text('11. Invoice Management'), findsOneWidget);

      // Scroll to administration items
      await tester.scrollUntilVisible(find.text('36. Employees & Roles'), 100);
      expect(find.text('36. Employees & Roles'), findsOneWidget);
      expect(find.text('37. Branch Management'), findsOneWidget);
    });

    testWidgets('ProtectedScreen blocks Cashier navigating directly to /employees', (WidgetTester tester) async {
      final mockAuth = MockAuthProvider();
      mockAuth.setMockUser(
        UserModel(
          id: 4,
          name: 'Cashier Terminal',
          email: 'cashier@bharatledger.com',
          phone: '9823099999',
          role: 'Cashier',
          permissions: ['billing.view', 'invoices.view', 'payments.view'],
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: mockAuth,
          child: const MaterialApp(
            home: ProtectedScreen(
              permission: 'employees.view',
              child: Scaffold(body: Text('Employees Management Page')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Must display AccessDeniedScreen and block target child
      expect(find.byType(AccessDeniedScreen), findsOneWidget);
      expect(find.text('403 — Access Denied'), findsOneWidget);
      expect(find.text('Return to Dashboard'), findsOneWidget);
      expect(find.text('Employees Management Page'), findsNothing);
    });
  });
}
