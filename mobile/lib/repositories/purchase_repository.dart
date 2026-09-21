import '../core/storage/local_store.dart';

class PurchaseRepository {
  final LocalStore _store = LocalStore();

  List<Map<String, dynamic>> getAll({String? status, String? search}) {
    var purchases = _store.getCollection('purchases');
    if (status != null && status.isNotEmpty && status != 'ALL') {
      purchases = purchases.where((p) => (p['status'] ?? '').toString().toUpperCase() == status.toUpperCase()).toList();
    }
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      purchases = purchases.where((p) {
        final po = (p['purchase_number'] ?? '').toString().toLowerCase();
        final sup = (p['supplier_name'] ?? '').toString().toLowerCase();
        return po.contains(q) || sup.contains(q);
      }).toList();
    }
    return purchases.reversed.toList();
  }

  Map<String, dynamic>? getById(int id) {
    final purchases = _store.getCollection('purchases');
    for (final p in purchases) {
      if (p['id'] == id) return p;
    }
    return null;
  }

  Future<Map<String, dynamic>> createPurchase(Map<String, dynamic> data) async {
    final rawItems = (data['items'] as List?) ?? [];
    if (rawItems.isEmpty) {
      throw Exception("Purchase must contain at least one item");
    }

    final supplierId = (data['supplier_id'] as num?)?.toInt() ?? 1;
    final suppliers = _store.getCollection('suppliers');
    final supplier = suppliers.firstWhere((s) => s['id'] == supplierId, orElse: () => {
      'id': supplierId,
      'name': 'Primary Supplier',
      'phone': '',
      'gstin': '',
      'state': 'Maharashtra',
      'current_payable': 0.0,
    });

    final settings = _store.getDocument('settings');
    final business = _store.getDocument('business');
    final poPrefix = settings['purchase_prefix'] ?? 'BL-PO-';
    final nextPoNum = (settings['next_purchase_number'] as num?)?.toInt() ?? 501;
    final poNumber = data['purchase_number'] ?? "$poPrefix$nextPoNum";
    settings['next_purchase_number'] = nextPoNum + 1;
    _store.setDocument('settings', settings);

    final bizState = (business['state'] ?? 'Maharashtra').toString().trim().toLowerCase();
    final supState = (supplier['state'] ?? 'Maharashtra').toString().trim().toLowerCase();
    final isInterstate = bizState.isNotEmpty && supState.isNotEmpty && bizState != supState;

    final products = _store.getCollection('products');
    final stockMovements = _store.getCollection('stock_movements');
    final purchaseId = _store.generateId('purchases');

    double subtotal = 0.0;
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
        'current_stock': 0.0,
        'min_stock': 10.0,
        'purchase_price': (raw['unit_price'] as num? ?? 0.0).toDouble(),
      });

      final qty = (raw['quantity'] as num? ?? 1.0).toDouble();
      final unitPrice = (raw['unit_price'] as num? ?? (prod['purchase_price'] as num? ?? 0.0)).toDouble();
      final gstRate = (raw['gst_rate'] as num? ?? (prod['gst_rate'] as num? ?? 18.0)).toDouble();

      final taxable = qty * unitPrice;
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

      subtotal += taxable;
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
        'taxable_amount': taxable,
        'gst_rate': gstRate,
        'cgst_amount': cgst,
        'sgst_amount': sgst,
        'igst_amount': igst,
        'total_amount': itemTotal,
      });

      // Increase stock for purchase
      final prodIndex = products.indexWhere((p) => p['id'] == prodId);
      if (prodIndex != -1) {
        final currentStock = (products[prodIndex]['current_stock'] as num? ?? 0.0).toDouble();
        final newStock = currentStock + qty;
        final minStock = (products[prodIndex]['min_stock'] as num? ?? 10.0).toDouble();
        products[prodIndex]['current_stock'] = newStock;
        products[prodIndex]['is_low_stock'] = newStock <= minStock;

        stockMovements.add({
          'id': _store.generateId('stock_movements') + stockMovements.length,
          'product_id': prodId,
          'product_name': prod['name'],
          'movement_type': 'IN',
          'quantity': qty,
          'balance_after': newStock,
          'reference_type': 'PURCHASE',
          'reference_id': purchaseId,
          'notes': 'Inward Goods from Purchase $poNumber',
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    }

    _store.setCollection('products', products);
    _store.setCollection('stock_movements', stockMovements);

    final totalGst = cgstTotal + sgstTotal + igstTotal;
    final grandTotal = (taxableValue + totalGst).roundToDouble();

    final paymentData = (data['payment'] as Map?) ?? {};
    final paidAmount = (paymentData['amount'] as num? ?? 0.0).toDouble();
    final balanceAmount = (grandTotal - paidAmount) > 0 ? (grandTotal - paidAmount) : 0.0;
    final status = balanceAmount <= 0.01 ? 'PAID' : (paidAmount > 0 ? 'PARTIAL' : 'RECEIVED');

    final purchaseDate = data['purchase_date'] ?? DateTime.now().toIso8601String().substring(0, 10);
    final dueDate = data['due_date'] ?? DateTime.now().add(const Duration(days: 30)).toIso8601String().substring(0, 10);

    final purchase = {
      'id': purchaseId,
      'business_id': 1,
      'branch_id': 1,
      'supplier_id': supplierId,
      'supplier_name': supplier['name'] ?? 'Supplier',
      'purchase_number': poNumber,
      'supplier_invoice_number': data['supplier_invoice_number'] ?? '',
      'purchase_date': purchaseDate,
      'due_date': dueDate,
      'subtotal': subtotal,
      'taxable_value': taxableValue,
      'cgst_amount': cgstTotal,
      'sgst_amount': sgstTotal,
      'igst_amount': igstTotal,
      'total_gst': totalGst,
      'grand_total': grandTotal,
      'paid_amount': paidAmount,
      'balance_amount': balanceAmount,
      'status': status,
      'items': calculatedItems,
    };

    final purchases = _store.getCollection('purchases');
    purchases.add(purchase);
    _store.setCollection('purchases', purchases);

    // Supplier Ledger Entries
    final ledgers = _store.getCollection('ledger_entries');
    final ledgerId = _store.generateId('ledger_entries');
    ledgers.add({
      'id': ledgerId,
      'business_id': 1,
      'supplier_id': supplierId,
      'entry_date': purchaseDate,
      'voucher_type': 'PURCHASE',
      'voucher_number': poNumber,
      'debit_amount': 0.0,
      'credit_amount': grandTotal,
      'narration': 'Inward Goods Purchase $poNumber',
      'voucher_id': purchaseId,
    });

    if (paidAmount > 0) {
      final payments = _store.getCollection('payments');
      final payId = _store.generateId('payments');
      payments.add({
        'id': payId,
        'business_id': 1,
        'reference_type': 'PURCHASE',
        'reference_id': purchaseId,
        'party_type': 'SUPPLIER',
        'party_id': supplierId,
        'party_name': supplier['name'],
        'amount': paidAmount,
        'payment_method': paymentData['payment_method'] ?? 'BANK_TRANSFER',
        'payment_date': purchaseDate,
        'status': 'SUCCESSFUL',
        'invoice_number': poNumber,
        'notes': 'Payment for Purchase $poNumber',
      });
      _store.setCollection('payments', payments);

      ledgers.add({
        'id': ledgerId + 1,
        'business_id': 1,
        'supplier_id': supplierId,
        'entry_date': purchaseDate,
        'voucher_type': 'PAYMENT',
        'voucher_number': 'PMT-$payId',
        'debit_amount': paidAmount,
        'credit_amount': 0.0,
        'narration': 'Payment made to supplier for $poNumber',
        'voucher_id': payId,
      });
    }

    _store.setCollection('ledger_entries', ledgers);

    // Adjust supplier payable
    final sIdx = suppliers.indexWhere((s) => s['id'] == supplierId);
    if (sIdx != -1) {
      final curPayable = (suppliers[sIdx]['current_payable'] as num? ?? 0.0).toDouble();
      suppliers[sIdx]['current_payable'] = curPayable + balanceAmount;
      _store.setCollection('suppliers', suppliers);
    }

    // Notification
    final notifications = _store.getCollection('notifications');
    notifications.add({
      'id': _store.generateId('notifications') + notifications.length,
      'business_id': 1,
      'type': 'PURCHASE_CREATED',
      'title': 'New Purchase Order',
      'message': 'Purchase $poNumber received from ${supplier['name']} (₹${grandTotal.toStringAsFixed(0)})',
      'reference_type': 'PURCHASE',
      'reference_id': purchaseId,
      'created_at': DateTime.now().toIso8601String(),
      'is_read': false,
    });
    _store.setCollection('notifications', notifications);

    await _store.save();
    return purchase;
  }
}
