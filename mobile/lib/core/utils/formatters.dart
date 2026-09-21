import 'package:intl/intl.dart';

class AppFormatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _compactCurrency = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 1,
  );

  static String formatCurrency(num? amount) {
    if (amount == null) return '₹0.00';
    return _currencyFormat.format(amount);
  }

  static String formatCompactCurrency(num? amount) {
    if (amount == null) return '₹0';
    return _compactCurrency.format(amount);
  }

  static String formatDate(dynamic date) {
    if (date == null) return '';
    DateTime parsed;
    if (date is DateTime) {
      parsed = date;
    } else {
      try {
        parsed = DateTime.parse(date.toString());
      } catch (e) {
        return date.toString();
      }
    }
    return DateFormat('dd MMM yyyy').format(parsed);
  }

  static String formatDateTime(dynamic date) {
    if (date == null) return '';
    DateTime parsed;
    if (date is DateTime) {
      parsed = date;
    } else {
      try {
        parsed = DateTime.parse(date.toString());
      } catch (e) {
        return date.toString();
      }
    }
    return DateFormat('dd MMM yyyy, hh:mm a').format(parsed);
  }
}

class AppValidators {
  static String? requiredField(String? value, [String message = 'This field is required']) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length < 10) {
      return 'Enter a valid 10-digit phone number';
    }
    return null;
  }

  static String? positiveNumber(String? value, [String message = 'Enter a valid positive number']) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }
    final numVal = double.tryParse(value);
    if (numVal == null || numVal <= 0) {
      return message;
    }
    return null;
  }

  static String? gstin(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional unless required
    }
    final pattern = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
    if (!pattern.hasMatch(value.trim().toUpperCase())) {
      return 'Invalid 15-digit GSTIN format (e.g. 27AAAAA0000A1Z5)';
    }
    return null;
  }
}
