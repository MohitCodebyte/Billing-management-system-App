import '../core/storage/local_store.dart';

class InvoiceRepository {
  final LocalStore _store = LocalStore();

  List<Map<String, dynamic>> getAll({String? status, String? search}) {
    var invoices = _store.getCollection('invoices');

    if (status != null && status.isNotEmpty && status != 'ALL') {
      invoices = invoices.where((i) => (i['status'] ?? '').toString().toUpperCase() == status.toUpperCase()).toList();
    }

    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      invoices = invoices.where((i) {
        final invNum = (i['invoice_number'] ?? '').toString().toLowerCase();
        final customer = (i['customer_name'] ?? '').toString().toLowerCase();
        return invNum.contains(q) || customer.contains(q);
      }).toList();
    }

    return invoices.reversed.toList();
  }

  Map<String, dynamic>? getById(int id) {
    final invoices = _store.getCollection('invoices');
    for (final inv in invoices) {
      if (inv['id'] == id) return inv;
    }
    return null;
  }

  Future<Map<String, dynamic>> createInvoice(Map<String, dynamic> data) async {
    final rawItems = (data['items'] as List?) ?? [];
    if (rawItems.isEmpty) {
      throw Exception("Invoice must contain at least one item");
    }

    final customerId = (data['customer_id'] as num?)?.toInt() ?? 1;
    final customers = _store.getCollection('customers');
    final customer = customers.firstWhere((c) => c['id'] == customerId, orElse: () => {
      'id': customerId,
      'name': 'Walk-in Customer',
      'phone': '',
      'gstin': '',
      'state': 'Maharashtra',
      'current_balance': 0.0,
    });

    final business = _store.getDocument('business');
    final settings = _store.getDocument('settings');

    final prefix = settings['invoice_prefix'] ?? 'BL-INV-';
    final nextNum = (settings['next_invoice_number'] as num?)?.toInt() ?? 1001;
    final invNumber = data['invoice_number'] ?? "$prefix$nextNum";
    settings['next_invoice_number'] = nextNum + 1;
    _store.setDocument('settings', settings);

    final bizState = (business['state'] ?? 'Maharashtra').toString().trim().toLowerCase();
    final custState = (customer['state'] ?? 'Maharashtra').toString().trim().toLowerCase();
    final isInterstate = bizState.isNotEmpty && custState.isNotEmpty && bizState != custState;

    final products = _store.getCollection('products');
    final stockMovements = _store.getCollection('stock_movements');
    final invoiceId = _store.generateId('invoices');

    double subtotal = 0.0;
    double itemDiscounts = 0.0;
    double taxableValue = 0.0;
    double cgstTotal = 0.0;
    double sgstTotal = 0.0;
    double igstTotal = 0.0;

    final calculatedItems = <Map<String, dynamic>>[];

    for (int i = 0; i < rawItems.length; i++) {
      final raw = rawItems[i];
      final prodId = (raw['product_id'] as num?)?.toInt() ?? 0;
      final prod = products.firstWhere((p) => p['id'] == prodId, orElse: () => {
        'id': prodId,
        'name': raw['product_name'] ?? 'Product',
        'hsn_sac': '8481',
        'unit': 'PCS',
        'current_stock': 100.0,
        'min_stock': 10.0,
        'selling_price': (raw['unit_price'] as num? ?? 0.0).toDouble(),
      });

      final qty = (raw['quantity'] as num? ?? 1.0).toDouble();
      final unitPrice = (raw['unit_price'] as num? ?? (prod['selling_price'] as num? ?? 0.0)).toDouble();
      final discountPct = (raw['discount_percent'] as num? ?? 0.0).toDouble();
      final gstRate = (raw['gst_rate'] as num? ?? (prod['gst_rate'] as num? ?? 18.0)).toDouble();

      final gross = qty * unitPrice;
      final discAmt = gross * (discountPct / 100.0);
      final taxable = gross - discAmt;

      double cgst = 0.0;
      double sgst = 0.0;
      double igst = 0.0;

      if (isInterstate) {
        igst = taxable * (gstRate / 100.0);
      } else {
        cgst = taxable * ((gstRate / 2.0) / 100.0);
        sgst = taxable * ((gstRate / 2.0) / 100.0);
      }

      final itemTotal = taxable + cgst + sgst + igst;

      subtotal += gross;
      itemDiscounts += discAmt;
      taxableValue += taxable;
      cgstTotal += cgst;
      sgstTotal += sgst;
      igstTotal += igst;

      calculatedItems.add({
        'id': i + 1,
        'product_id': prodId,
        'product_name': prod['name'] ?? raw['product_name'] ?? 'Item',
        'hsn_sac': prod['hsn_sac'] ?? '8481',
        'quantity': qty,
        'unit': prod['unit'] ?? 'PCS',
        'unit_price': unitPrice,
        'discount_amount': discAmt,
        'taxable_amount': taxable,
        'gst_rate': gstRate,
        'cgst_amount': cgst,
        'sgst_amount': sgst,
        'igst_amount': igst,
        'total_amount': itemTotal,
      });

      // Deduct inventory stock
      final prodIndex = products.indexWhere((p) => p['id'] == prodId);
      if (prodIndex != -1) {
        final currentStock = (products[prodIndex]['current_stock'] as num? ?? 0.0).toDouble();
        final newStock = currentStock - qty;
        final minStock = (products[prodIndex]['min_stock'] as num? ?? 10.0).toDouble();
        products[prodIndex]['current_stock'] = newStock;
        products[prodIndex]['is_low_stock'] = newStock <= minStock;

        // Log stock movement OUT
        stockMovements.add({
          'id': _store.generateId('stock_movements') + stockMovements.length,
          'product_id': prodId,
          'product_name': prod['name'],
          'movement_type': 'OUT',
          'quantity': qty,
          'balance_after': newStock,
          'reference_type': 'INVOICE',
          'reference_id': invoiceId,
          'notes': 'Sale on Invoice $invNumber',
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    }

    _store.setCollection('products', products);
    _store.setCollection('stock_movements', stockMovements);

    final additionalCharges = (data['additional_charges'] as num? ?? 0.0).toDouble();
    final globalDiscount = (data['global_discount'] as num? ?? 0.0).toDouble();
    final netTaxable = (taxableValue - globalDiscount) > 0 ? (taxableValue - globalDiscount) : 0.0;
    final totalGst = cgstTotal + sgstTotal + igstTotal;

    final netBeforeRound = netTaxable + totalGst + additionalCharges;
    final grandTotal = netBeforeRound.roundToDouble();
    final roundOff = double.parse((grandTotal - netBeforeRound).toStringAsFixed(2));

    final paymentData = (data['payment'] as Map?) ?? {};
    final paidAmount = (paymentData['amount'] as num? ?? 0.0).toDouble();
    final balanceAmount = (grandTotal - paidAmount) > 0 ? (grandTotal - paidAmount) : 0.0;

    final status = balanceAmount <= 0.01 ? 'PAID' : (paidAmount > 0 ? 'PARTIAL' : 'ISSUED');
    final invoiceDate = data['invoice_date'] ?? DateTime.now().toIso8601String().substring(0, 10);
    final dueDate = data['due_date'] ?? DateTime.now().add(const Duration(days: 15)).toIso8601String().substring(0, 10);

    final invoice = {
      'id': invoiceId,
      'business_id': data['business_id'] ?? 1,
      'branch_id': data['branch_id'] ?? 1,
      'customer_id': customerId,
      'customer_name': customer['name'] ?? 'Walk-in Customer',
      'customer_phone': customer['phone'] ?? '',
      'customer_gstin': customer['gstin'] ?? '',
      'invoice_number': invNumber,
      'invoice_date': invoiceDate,
      'due_date': dueDate,
      'subtotal': subtotal,
      'discount_amount': itemDiscounts + globalDiscount,
      'taxable_value': netTaxable,
      'cgst_amount': cgstTotal,
      'sgst_amount': sgstTotal,
      'igst_amount': igstTotal,
      'total_gst': totalGst,
      'additional_charges': additionalCharges,
      'round_off': roundOff,
      'grand_total': grandTotal,
      'paid_amount': paidAmount,
      'balance_amount': balanceAmount,
      'status': status,
      'payment_method': paymentData['payment_method'] ?? 'CASH',
      'items': calculatedItems,
      'notes': data['notes'] ?? '',
      'payment_terms': data['payment_terms'] ?? 'Net 15',
    };

    final invoices = _store.getCollection('invoices');
    invoices.add(invoice);
    _store.setCollection('invoices', invoices);

    // Record Customer Ledger Entries
    final ledgers = _store.getCollection('ledger_entries');
    final ledgerId1 = _store.generateId('ledger_entries');
    ledgers.add({
      'id': ledgerId1,
      'business_id': 1,
      'customer_id': customerId,
      'entry_date': invoiceDate,
      'voucher_type': 'INVOICE',
      'voucher_number': invNumber,
      'debit_amount': grandTotal,
      'credit_amount': 0.0,
      'narration': 'Goods sold on Invoice $invNumber',
      'voucher_id': invoiceId,
    });

    // Record Payment if paid
    if (paidAmount > 0) {
      final payments = _store.getCollection('payments');
      final payId = _store.generateId('payments');
      payments.add({
        'id': payId,
        'business_id': 1,
        'reference_type': 'INVOICE',
        'reference_id': invoiceId,
        'party_type': 'CUSTOMER',
        'party_id': customerId,
        'party_name': customer['name'],
        'amount': paidAmount,
        'payment_method': paymentData['payment_method'] ?? 'CASH',
        'payment_date': invoiceDate,
        'status': 'SUCCESSFUL',
        'invoice_number': invNumber,
        'notes': 'Payment received for $invNumber',
      });
      _store.setCollection('payments', payments);

      ledgers.add({
        'id': ledgerId1 + 1,
        'business_id': 1,
        'customer_id': customerId,
        'entry_date': invoiceDate,
        'voucher_type': 'PAYMENT',
        'voucher_number': 'RCPT-$payId',
        'debit_amount': 0.0,
        'credit_amount': paidAmount,
        'narration': 'Payment received via ${paymentData['payment_method'] ?? 'CASH'} for $invNumber',
        'voucher_id': payId,
      });
    }

    _store.setCollection('ledger_entries', ledgers);

    // Update customer balance
    final custIndex = customers.indexWhere((c) => c['id'] == customerId);
    if (custIndex != -1) {
      final currBal = (customers[custIndex]['current_balance'] as num? ?? 0.0).toDouble();
      customers[custIndex]['current_balance'] = currBal + balanceAmount;
      _store.setCollection('customers', customers);
    }

    // Add Notification
    final notifications = _store.getCollection('notifications');
    notifications.add({
      'id': _store.generateId('notifications') + notifications.length,
      'business_id': 1,
      'type': 'INVOICE_CREATED',
      'title': 'New Invoice Created',
      'message': 'Invoice $invNumber created for ${customer['name']} (₹${grandTotal.toStringAsFixed(0)})',
      'reference_type': 'INVOICE',
      'reference_id': invoiceId,
      'created_at': DateTime.now().toIso8601String(),
      'is_read': false,
    });
    _store.setCollection('notifications', notifications);

    await _store.save();
    return invoice;
  }

  Future<bool> recordPayment(int invoiceId, double amount, String method, {String? notes}) async {
    final invoices = _store.getCollection('invoices');
    final index = invoices.indexWhere((i) => i['id'] == invoiceId);
    if (index == -1) return false;

    final inv = invoices[index];
    final grandTotal = (inv['grand_total'] as num? ?? 0.0).toDouble();
    final existingPaid = (inv['paid_amount'] as num? ?? 0.0).toDouble();
    final newPaid = existingPaid + amount;
    final newBalance = (grandTotal - newPaid) > 0 ? (grandTotal - newPaid) : 0.0;
    final newStatus = newBalance <= 0.01 ? 'PAID' : 'PARTIAL';

    inv['paid_amount'] = newPaid;
    inv['balance_amount'] = newBalance;
    inv['status'] = newStatus;
    invoices[index] = inv;
    _store.setCollection('invoices', invoices);

    final customerId = inv['customer_id'] ?? 1;

    // Record Payment
    final payments = _store.getCollection('payments');
    final payId = _store.generateId('payments');
    payments.add({
      'id': payId,
      'business_id': 1,
      'reference_type': 'INVOICE',
      'reference_id': invoiceId,
      'party_type': 'CUSTOMER',
      'party_id': customerId,
      'party_name': inv['customer_name'],
      'amount': amount,
      'payment_method': method,
      'payment_date': DateTime.now().toIso8601String().substring(0, 10),
      'status': 'SUCCESSFUL',
      'invoice_number': inv['invoice_number'],
      'notes': notes ?? 'Payment against ${inv['invoice_number']}',
    });
    _store.setCollection('payments', payments);

    // Ledger Credit
    final ledgers = _store.getCollection('ledger_entries');
    ledgers.add({
      'id': _store.generateId('ledger_entries') + ledgers.length,
      'business_id': 1,
      'customer_id': customerId,
      'entry_date': DateTime.now().toIso8601String().substring(0, 10),
      'voucher_type': 'PAYMENT',
      'voucher_number': 'RCPT-$payId',
      'debit_amount': 0.0,
      'credit_amount': amount,
      'narration': 'Payment received via $method for ${inv['invoice_number']}',
      'voucher_id': payId,
    });
    _store.setCollection('ledger_entries', ledgers);

    // Reduce customer balance
    final customers = _store.getCollection('customers');
    final cIdx = customers.indexWhere((c) => c['id'] == customerId);
    if (cIdx != -1) {
      final curr = (customers[cIdx]['current_balance'] as num? ?? 0.0).toDouble();
      customers[cIdx]['current_balance'] = (curr - amount) > 0 ? (curr - amount) : 0.0;
      _store.setCollection('customers', customers);
    }

    await _store.save();
    return true;
  }
}
