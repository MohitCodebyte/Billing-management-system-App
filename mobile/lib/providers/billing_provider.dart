import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/models.dart';

class CartItem {
  final ProductModel product;
  double quantity;
  double unitPrice;
  double discountPercent;

  CartItem({
    required this.product,
    this.quantity = 1.0,
    required this.unitPrice,
    this.discountPercent = 0.0,
  });

  double get gross => quantity * unitPrice;
  double get discountAmount => gross * (discountPercent / 100.0);
  double get taxable => gross - discountAmount;
  double get taxAmount => taxable * (product.gstRate / 100.0);
  double get total => taxable + taxAmount;
}

class BillingProvider extends ChangeNotifier {
  CustomerModel? _selectedCustomer;
  final List<CartItem> _cart = [];
  double _additionalCharges = 0.0;
  double _globalDiscount = 0.0;

  String _paymentMethod = 'CASH'; // CASH, UPI, CARD, CREDIT, SPLIT
  double _paidAmount = 0.0;
  List<Map<String, dynamic>> _splitPayments = [];

  bool _isSubmitting = false;
  String? _errorMessage;
  InvoiceModel? _lastCreatedInvoice;

  CustomerModel? get selectedCustomer => _selectedCustomer;
  List<CartItem> get cart => _cart;
  double get additionalCharges => _additionalCharges;
  double get globalDiscount => _globalDiscount;
  String get paymentMethod => _paymentMethod;
  double get paidAmount => _paidAmount;
  List<Map<String, dynamic>> get splitPayments => _splitPayments;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  InvoiceModel? get lastCreatedInvoice => _lastCreatedInvoice;

  void selectCustomer(CustomerModel? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void addToCart(ProductModel product, {double quantity = 1.0}) {
    final existingIndex = _cart.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      _cart[existingIndex].quantity += quantity;
    } else {
      _cart.add(CartItem(
        product: product,
        quantity: quantity,
        unitPrice: product.sellingPrice,
      ));
    }
    _autoUpdatePaidAmount();
    notifyListeners();
  }

  void updateQuantity(int index, double quantity) {
    if (index >= 0 && index < _cart.length) {
      if (quantity <= 0) {
        _cart.removeAt(index);
      } else {
        _cart[index].quantity = quantity;
      }
      _autoUpdatePaidAmount();
      notifyListeners();
    }
  }

  void updateItemPrice(int index, double price) {
    if (index >= 0 && index < _cart.length) {
      _cart[index].unitPrice = price;
      _autoUpdatePaidAmount();
      notifyListeners();
    }
  }

  void updateItemDiscount(int index, double discountPercent) {
    if (index >= 0 && index < _cart.length) {
      _cart[index].discountPercent = discountPercent;
      _autoUpdatePaidAmount();
      notifyListeners();
    }
  }

  void removeFromCart(int index) {
    if (index >= 0 && index < _cart.length) {
      _cart.removeAt(index);
      _autoUpdatePaidAmount();
      notifyListeners();
    }
  }

  void setAdditionalCharges(double charges) {
    _additionalCharges = charges;
    _autoUpdatePaidAmount();
    notifyListeners();
  }

  void setGlobalDiscount(double discount) {
    _globalDiscount = discount;
    _autoUpdatePaidAmount();
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    if (method == 'CREDIT') {
      _paidAmount = 0.0;
    } else {
      _paidAmount = grandTotal;
    }
    notifyListeners();
  }

  void setPaidAmount(double amount) {
    _paidAmount = amount;
    notifyListeners();
  }

  void setSplitPayments(List<Map<String, dynamic>> splits) {
    _splitPayments = splits;
    _paidAmount = splits.fold(0.0, (acc, s) => acc + (s['amount'] as num? ?? 0.0).toDouble());
    notifyListeners();
  }

  void _autoUpdatePaidAmount() {
    if (_paymentMethod != 'CREDIT' && _paymentMethod != 'SPLIT') {
      _paidAmount = grandTotal;
    }
  }

  double get subtotal => _cart.fold(0.0, (acc, itm) => acc + itm.gross);
  double get itemDiscounts => _cart.fold(0.0, (acc, itm) => acc + itm.discountAmount);
  double get totalDiscount => itemDiscounts + _globalDiscount;
  double get taxableSubtotal => _cart.fold(0.0, (acc, itm) => acc + itm.taxable) - _globalDiscount;
  double get totalGst => _cart.fold(0.0, (acc, itm) => acc + itm.taxAmount);
  double get netBeforeRound => (taxableSubtotal > 0 ? taxableSubtotal : 0) + totalGst + _additionalCharges;
  double get grandTotal => netBeforeRound.roundToDouble();
  double get roundOff => grandTotal - netBeforeRound;
  double get balanceAmount => (grandTotal - _paidAmount) > 0 ? (grandTotal - _paidAmount) : 0.0;

  Future<bool> submitInvoice() async {
    if (_cart.isEmpty) {
      _errorMessage = "Cannot generate invoice with empty cart";
      notifyListeners();
      return false;
    }

    if (_selectedCustomer == null) {
      _errorMessage = "Please select a customer for this invoice";
      notifyListeners();
      return false;
    }

    // Protection against duplicate submissions
    if (_isSubmitting) return false;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final payload = {
      'customer_id': _selectedCustomer!.id,
      'items': _cart.map((i) => {
        'product_id': i.product.id,
        'quantity': i.quantity,
        'unit_price': i.unitPrice,
        'discount_percent': i.discountPercent,
        'gst_rate': i.product.gstRate,
      }).toList(),
      'additional_charges': _additionalCharges,
      'global_discount': _globalDiscount,
      'payment': {
        'amount': _paidAmount,
        'payment_method': _paymentMethod,
        'splits': _paymentMethod == 'SPLIT' ? _splitPayments : [],
      }
    };

    final res = await ApiClient().post(ApiConstants.invoices, body: payload);

    _isSubmitting = false;
    if (res.success && res.data != null) {
      final invoiceData = res.data['invoice'];
      _lastCreatedInvoice = InvoiceModel.fromJson(invoiceData);
      clearCart();
      notifyListeners();
      return true;
    } else {
      _errorMessage = res.error ?? "Failed to create invoice";
      notifyListeners();
      return false;
    }
  }

  void clearCart() {
    _cart.clear();
    _selectedCustomer = null;
    _additionalCharges = 0.0;
    _globalDiscount = 0.0;
    _paymentMethod = 'CASH';
    _paidAmount = 0.0;
    _splitPayments.clear();
    _errorMessage = null;
    notifyListeners();
  }
}
