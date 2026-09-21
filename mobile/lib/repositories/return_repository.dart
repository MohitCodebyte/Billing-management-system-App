import '../core/storage/local_store.dart';

class ReturnRepository {
  final LocalStore _store = LocalStore();

  List<Map<String, dynamic>> getSalesReturns() {
    return _store.getCollection('sales_returns').reversed.toList();
  }

  List<Map<String, dynamic>> getPurchaseReturns() {
    return _store.getCollection('purchase_returns').reversed.toList();
  }

  List<Map<String, dynamic>> getCreditNotes() {
    return _store.getCollection('credit_notes').reversed.toList();
  }

  List<Map<String, dynamic>> getDebitNotes() {
    return _store.getCollection('debit_notes').reversed.toList();
  }

  Future<Map<String, dynamic>> createSalesReturn(Map<String, dynamic> data) async {
    final invoiceId = (data['invoice_id'] as num?)?.toInt() ?? 0;
    final invoices = _store.getCollection('invoices');
    final invoice = invoices.firstWhere((i) => i['id'] == invoiceId, orElse: () => {});
    if (invoice.isEmpty) throw Exception("Invoice not found for sales return");

    final rawItems = (data['items'] as List?) ?? [];
    final returnItems = <Map<String, dynamic>>[];
    double totalRefund = 0.0;

    final products = _store.getCollection('products');
    final stockMovements = _store.getCollection('stock_movements');
    final retId = _store.generateId('sales_returns');
    final retNumber = "SR-${DateTime.now().millisecondsSinceEpoch}";

    for (final it in rawItems) {
      final pId = (it['product_id'] as num?)?.toInt() ?? 0;
      final qty = (it['quantity'] as num? ?? 1.0).toDouble();
      final price = (it['unit_price'] as num? ?? 0.0).toDouble();
      final itemTotal = qty * price;
      totalRefund += itemTotal;

      returnItems.add({
        'product_id': pId,
        'product_name': it['product_name'] ?? 'Returned Item',
        'quantity': qty,
        'unit_price': price,
        'total_amount': itemTotal,
      });

      // Restock inventory
      final pIdx = products.indexWhere((p) => p['id'] == pId);
      if (pIdx != -1) {
        final cur = (products[pIdx]['current_stock'] as num? ?? 0.0).toDouble();
        final newStock = cur + qty;
        products[pIdx]['current_stock'] = newStock;

        stockMovements.add({
          'id': _store.generateId('stock_movements') + stockMovements.length,
          'product_id': pId,
          'product_name': products[pIdx]['name'],
          'movement_type': 'RETURN',
          'quantity': qty,
          'balance_after': newStock,
          'reference_type': 'SALES_RETURN',
          'reference_id': retId,
          'notes': 'Restock from Sales Return $retNumber',
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    }

    _store.setCollection('products', products);
    _store.setCollection('stock_movements', stockMovements);

    final refundType = data['refund_type'] ?? 'CREDIT_NOTE';
    final salesReturn = {
      'id': retId,
      'business_id': 1,
      'branch_id': 1,
      'invoice_id': invoiceId,
      'invoice_number': invoice['invoice_number'],
      'customer_id': invoice['customer_id'],
      'customer_name': invoice['customer_name'],
      'return_number': retNumber,
      'return_date': DateTime.now().toIso8601String().substring(0, 10),
      'refund_type': refundType,
      'total_amount': totalRefund,
      'reason': data['reason'] ?? 'Customer return',
      'items': returnItems,
    };

    final sReturns = _store.getCollection('sales_returns');
    sReturns.add(salesReturn);
    _store.setCollection('sales_returns', sReturns);

    if (refundType == 'CREDIT_NOTE') {
      final cnNumber = "CN-${DateTime.now().millisecondsSinceEpoch}";
      final creditNotes = _store.getCollection('credit_notes');
      final cnId = _store.generateId('credit_notes');
      creditNotes.add({
        'id': cnId,
        'business_id': 1,
        'customer_id': invoice['customer_id'],
        'customer_name': invoice['customer_name'],
        'invoice_id': invoiceId,
        'note_number': cnNumber,
        'note_date': DateTime.now().toIso8601String().substring(0, 10),
        'amount': totalRefund,
        'reason': data['reason'] ?? 'Sales Return $retNumber',
        'status': 'ACTIVE',
      });
      _store.setCollection('credit_notes', creditNotes);

      // Customer Ledger Credit
      final ledgers = _store.getCollection('ledger_entries');
      ledgers.add({
        'id': _store.generateId('ledger_entries'),
        'business_id': 1,
        'customer_id': invoice['customer_id'],
        'entry_date': DateTime.now().toIso8601String().substring(0, 10),
        'voucher_type': 'CREDIT_NOTE',
        'voucher_number': cnNumber,
        'debit_amount': 0.0,
        'credit_amount': totalRefund,
        'narration': 'Sales Return against ${invoice['invoice_number']}',
        'voucher_id': cnId,
      });
      _store.setCollection('ledger_entries', ledgers);

      // Adjust customer balance
      final customers = _store.getCollection('customers');
      final cIdx = customers.indexWhere((c) => c['id'] == invoice['customer_id']);
      if (cIdx != -1) {
        final bal = (customers[cIdx]['current_balance'] as num? ?? 0.0).toDouble();
        customers[cIdx]['current_balance'] = (bal - totalRefund) > 0 ? (bal - totalRefund) : 0.0;
        _store.setCollection('customers', customers);
      }
    }

    await _store.save();
    return salesReturn;
  }

  Future<Map<String, dynamic>> createPurchaseReturn(Map<String, dynamic> data) async {
    final purchaseId = (data['purchase_id'] as num?)?.toInt() ?? 0;
    final purchases = _store.getCollection('purchases');
    final purchase = purchases.firstWhere((p) => p['id'] == purchaseId, orElse: () => {});
    if (purchase.isEmpty) throw Exception("Purchase order not found");

    final rawItems = (data['items'] as List?) ?? [];
    final returnItems = <Map<String, dynamic>>[];
    double totalReturnAmt = 0.0;

    final products = _store.getCollection('products');
    final stockMovements = _store.getCollection('stock_movements');
    final retId = _store.generateId('purchase_returns');
    final retNumber = "PR-${DateTime.now().millisecondsSinceEpoch}";

    for (final it in rawItems) {
      final pId = (it['product_id'] as num?)?.toInt() ?? 0;
      final qty = (it['quantity'] as num? ?? 1.0).toDouble();
      final price = (it['unit_price'] as num? ?? 0.0).toDouble();
      final itemTotal = qty * price;
      totalReturnAmt += itemTotal;

      returnItems.add({
        'product_id': pId,
        'product_name': it['product_name'] ?? 'Item',
        'quantity': qty,
        'unit_price': price,
        'total_amount': itemTotal,
      });

      // Deduct returned items from inventory
      final pIdx = products.indexWhere((p) => p['id'] == pId);
      if (pIdx != -1) {
        final cur = (products[pIdx]['current_stock'] as num? ?? 0.0).toDouble();
        final newStock = cur - qty;
        products[pIdx]['current_stock'] = newStock;

        stockMovements.add({
          'id': _store.generateId('stock_movements') + stockMovements.length,
          'product_id': pId,
          'product_name': products[pIdx]['name'],
          'movement_type': 'OUT',
          'quantity': qty,
          'balance_after': newStock,
          'reference_type': 'PURCHASE_RETURN',
          'reference_id': retId,
          'notes': 'Goods Return to Supplier on $retNumber',
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    }

    _store.setCollection('products', products);
    _store.setCollection('stock_movements', stockMovements);

    final pReturn = {
      'id': retId,
      'business_id': 1,
      'purchase_id': purchaseId,
      'purchase_number': purchase['purchase_number'],
      'supplier_id': purchase['supplier_id'],
      'supplier_name': purchase['supplier_name'],
      'return_number': retNumber,
      'return_date': DateTime.now().toIso8601String().substring(0, 10),
      'total_amount': totalReturnAmt,
      'reason': data['reason'] ?? 'Damaged or specification mismatch',
      'items': returnItems,
    };

    final pReturns = _store.getCollection('purchase_returns');
    pReturns.add(pReturn);
    _store.setCollection('purchase_returns', pReturns);

    // Issue Debit Note
    final dnNumber = "DN-${DateTime.now().millisecondsSinceEpoch}";
    final debitNotes = _store.getCollection('debit_notes');
    final dnId = _store.generateId('debit_notes');
    debitNotes.add({
      'id': dnId,
      'business_id': 1,
      'supplier_id': purchase['supplier_id'],
      'supplier_name': purchase['supplier_name'],
      'purchase_id': purchaseId,
      'note_number': dnNumber,
      'note_date': DateTime.now().toIso8601String().substring(0, 10),
      'amount': totalReturnAmt,
      'reason': data['reason'] ?? 'Purchase Return $retNumber',
      'status': 'ACTIVE',
    });
    _store.setCollection('debit_notes', debitNotes);

    // Supplier Ledger Debit (reduces liability)
    final ledgers = _store.getCollection('ledger_entries');
    ledgers.add({
      'id': _store.generateId('ledger_entries'),
      'business_id': 1,
      'supplier_id': purchase['supplier_id'],
      'entry_date': DateTime.now().toIso8601String().substring(0, 10),
      'voucher_type': 'DEBIT_NOTE',
      'voucher_number': dnNumber,
      'debit_amount': totalReturnAmt,
      'credit_amount': 0.0,
      'narration': 'Purchase Return against ${purchase['purchase_number']}',
      'voucher_id': dnId,
    });
    _store.setCollection('ledger_entries', ledgers);

    // Adjust supplier payable
    final suppliers = _store.getCollection('suppliers');
    final sIdx = suppliers.indexWhere((s) => s['id'] == purchase['supplier_id']);
    if (sIdx != -1) {
      final curPay = (suppliers[sIdx]['current_payable'] as num? ?? 0.0).toDouble();
      suppliers[sIdx]['current_payable'] = (curPay - totalReturnAmt) > 0 ? (curPay - totalReturnAmt) : 0.0;
      _store.setCollection('suppliers', suppliers);
    }

    await _store.save();
    return pReturn;
  }
}
