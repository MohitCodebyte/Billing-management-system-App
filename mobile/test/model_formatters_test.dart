import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/formatters.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/models/models.dart';

void main() {
  group('AppFormatters Tests', () {
    test('Currency formatting with Rupee symbol and Indian numbering format', () {
      expect(AppFormatters.formatCurrency(1245000), '₹12,45,000.00');
      expect(AppFormatters.formatCurrency(500), '₹500.00');
      expect(AppFormatters.formatCurrency(0), '₹0.00');
    });

    test('GSTIN validation', () {
      expect(AppValidators.gstin('27AABCU9603R1ZM'), null);
      expect(AppValidators.gstin('123'), isNotNull);
    });

    test('Phone validation', () {
      expect(AppValidators.phone('9823012345'), null);
      expect(AppValidators.phone('1234'), isNotNull);
    });
  });

  group('Models & Branding Tests', () {
    test('Copyright attribution and versioning match specification', () {
      expect(ApiConstants.copyright, '© NexvoraTech LLP — Developed by Mohit');
      expect(ApiConstants.appTitle, 'BharatLedger Pro');
    });

    test('CustomerModel JSON round-trip serialization', () {
      final json = {
        'id': 1,
        'name': 'Rahul Engineering Works',
        'phone': '9822011223',
        'email': 'rahul@industrial.in',
        'gstin': '27ABCDE1234F1Z5',
        'current_balance': 45000.0,
        'credit_limit': 100000.0,
      };

      final customer = CustomerModel.fromJson(json);
      expect(customer.id, 1);
      expect(customer.name, 'Rahul Engineering Works');
      expect(customer.currentBalance, 45000.0);
      expect(customer.creditLimit, 100000.0);
    });

    test('ProductModel stock status calculation', () {
      final json = {
        'id': 10,
        'name': 'CNC Carbide End Mill 12mm',
        'sku': 'EM-12MM-4F',
        'unit': 'PCS',
        'selling_price': 1250.0,
        'purchase_price': 850.0,
        'tax_rate': 18.0,
        'current_stock': 2.0,
        'min_stock': 5.0,
        'is_low_stock': true,
      };

      final product = ProductModel.fromJson(json);
      expect(product.isLowStock, true);
      expect(product.isOutOfStock, false);
    });
  });
}
