import '../core/storage/local_store.dart';

class ReportRepository {
  final LocalStore _store = LocalStore();

  Map<String, dynamic> getDashboardStats() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final invoices = _store.getCollection('invoices');
    final customers = _store.getCollection('customers');
    final suppliers = _store.getCollection('suppliers');
    final products = _store.getCollection('products');

    double todaySales = 0.0;
    int todayCount = 0;

    for (final inv in invoices) {
      if (inv['invoice_date'] == today) {
        todaySales += (inv['grand_total'] as num? ?? 0.0).toDouble();
        todayCount++;
      }
    }

    double receivables = 0.0;
    for (final c in customers) {
      receivables += (c['current_balance'] as num? ?? 0.0).toDouble();
    }

    double payables = 0.0;
    for (final s in suppliers) {
      payables += (s['current_payable'] as num? ?? 0.0).toDouble();
    }

    double inventoryValuation = 0.0;
    int lowStock = 0;
    final lowStockItems = <Map<String, dynamic>>[];

    for (final p in products) {
      final stock = (p['current_stock'] as num? ?? 0.0).toDouble();
      final buyPrice = (p['purchase_price'] as num? ?? 0.0).toDouble();
      final minStock = (p['min_stock'] as num? ?? 10.0).toDouble();

      inventoryValuation += (stock * buyPrice);
      if (stock <= minStock) {
        lowStock++;
        lowStockItems.add(p);
      }
    }

    final recentInvoices = invoices.reversed.take(5).toList();

    return {
      'today_sales': todaySales,
      'today_invoices': todayCount,
      'total_receivables': receivables,
      'total_payables': payables,
      'total_inventory_valuation': inventoryValuation,
      'low_stock_count': lowStock,
      'total_customers': customers.length,
      'total_products': products.length,
      'recent_invoices': recentInvoices,
      'low_stock_products': lowStockItems,
    };
  }

  Map<String, dynamic> getSalesAnalytics() {
    final invoices = _store.getCollection('invoices');

    double totalSales = 0.0;
    double totalTaxable = 0.0;
    double totalGst = 0.0;
    double totalPaid = 0.0;
    double totalOutstanding = 0.0;

    final trendMap = <String, double>{};
    final custSalesMap = <String, double>{};

    for (final inv in invoices) {
      final gTotal = (inv['grand_total'] as num? ?? 0.0).toDouble();
      final taxVal = (inv['taxable_value'] as num? ?? 0.0).toDouble();
      final gst = (inv['total_gst'] as num? ?? 0.0).toDouble();
      final paid = (inv['paid_amount'] as num? ?? 0.0).toDouble();
      final bal = (inv['balance_amount'] as num? ?? 0.0).toDouble();
      final date = inv['invoice_date'] ?? 'Unknown';
      final cust = inv['customer_name'] ?? 'General';

      totalSales += gTotal;
      totalTaxable += taxVal;
      totalGst += gst;
      totalPaid += paid;
      totalOutstanding += bal;

      trendMap[date] = (trendMap[date] ?? 0.0) + gTotal;
      custSalesMap[cust] = (custSalesMap[cust] ?? 0.0) + gTotal;
    }

    final trend = trendMap.entries.map((e) => {'date': e.key, 'amount': e.value}).toList();
    trend.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

    final topCustomers = custSalesMap.entries.map((e) => {'name': e.key, 'total_spent': e.value}).toList();
    topCustomers.sort((a, b) => (b['total_spent'] as double).compareTo(a['total_spent'] as double));

    return {
      'total_sales': totalSales,
      'total_taxable': totalTaxable,
      'total_gst': totalGst,
      'total_paid': totalPaid,
      'total_outstanding': totalOutstanding,
      'invoice_count': invoices.length,
      'trend': trend,
      'top_customers': topCustomers.take(5).toList(),
    };
  }

  Map<String, dynamic> getProfitAndLoss() {
    final invoices = _store.getCollection('invoices');
    final purchases = _store.getCollection('purchases');
    final expenses = _store.getCollection('expenses');

    double revenue = 0.0;
    for (final i in invoices) {
      revenue += (i['grand_total'] as num? ?? 0.0).toDouble();
    }

    double cogs = 0.0;
    for (final p in purchases) {
      cogs += (p['grand_total'] as num? ?? 0.0).toDouble();
    }

    double totalExpenses = 0.0;
    for (final e in expenses) {
      totalExpenses += (e['amount'] as num? ?? 0.0).toDouble();
    }

    final grossProfit = revenue - cogs;
    final netProfit = grossProfit - totalExpenses;
    final margin = revenue > 0 ? (netProfit / revenue) * 100.0 : 0.0;

    return {
      'total_revenue': revenue,
      'cost_of_goods': cogs,
      'gross_profit': grossProfit,
      'total_expenses': totalExpenses,
      'net_profit': netProfit,
      'profit_margin_percent': double.parse(margin.toStringAsFixed(2)),
    };
  }

  Map<String, dynamic> getGstReport() {
    final invoices = _store.getCollection('invoices');
    final purchases = _store.getCollection('purchases');

    double outTaxable = 0.0, outCgst = 0.0, outSgst = 0.0, outIgst = 0.0;
    for (final i in invoices) {
      outTaxable += (i['taxable_value'] as num? ?? 0.0).toDouble();
      outCgst += (i['cgst_amount'] as num? ?? 0.0).toDouble();
      outSgst += (i['sgst_amount'] as num? ?? 0.0).toDouble();
      outIgst += (i['igst_amount'] as num? ?? 0.0).toDouble();
    }
    final outTotalTax = outCgst + outSgst + outIgst;

    double inTaxable = 0.0, inCgst = 0.0, inSgst = 0.0, inIgst = 0.0;
    for (final p in purchases) {
      inTaxable += (p['taxable_value'] as num? ?? 0.0).toDouble();
      inCgst += (p['cgst_amount'] as num? ?? 0.0).toDouble();
      inSgst += (p['sgst_amount'] as num? ?? 0.0).toDouble();
      inIgst += (p['igst_amount'] as num? ?? 0.0).toDouble();
    }
    final inTotalTax = inCgst + inSgst + inIgst;
    final netGst = (outTotalTax - inTotalTax) > 0 ? (outTotalTax - inTotalTax) : 0.0;

    return {
      'outward': {
        'taxable_value': outTaxable,
        'cgst': outCgst,
        'sgst': outSgst,
        'igst': outIgst,
        'total_tax': outTotalTax,
      },
      'inward_itc': {
        'taxable_value': inTaxable,
        'cgst': inCgst,
        'sgst': inSgst,
        'igst': inIgst,
        'total_tax': inTotalTax,
      },
      'net_gst_payable': netGst,
    };
  }

  Map<String, dynamic> getInventoryReport() {
    final products = _store.getCollection('products');

    int totalItems = products.length;
    int lowStock = 0;
    int outOfStock = 0;
    double totalValuation = 0.0;

    final items = <Map<String, dynamic>>[];

    for (final p in products) {
      final stock = (p['current_stock'] as num? ?? 0.0).toDouble();
      final minStock = (p['min_stock'] as num? ?? 10.0).toDouble();
      final buyPrice = (p['purchase_price'] as num? ?? 0.0).toDouble();
      final sellPrice = (p['selling_price'] as num? ?? 0.0).toDouble();
      final valuation = stock * buyPrice;

      totalValuation += valuation;
      if (stock <= 0) {
        outOfStock++;
      } else if (stock <= minStock) {
        lowStock++;
      }

      items.add({
        'id': p['id'],
        'name': p['name'],
        'sku': p['sku'],
        'category_name': p['category_name'],
        'current_stock': stock,
        'min_stock': minStock,
        'purchase_price': buyPrice,
        'selling_price': sellPrice,
        'valuation': valuation,
        'status': stock <= 0 ? 'OUT_OF_STOCK' : (stock <= minStock ? 'LOW_STOCK' : 'IN_STOCK'),
      });
    }

    return {
      'total_items': totalItems,
      'low_stock_items': lowStock,
      'out_of_stock_items': outOfStock,
      'total_valuation': totalValuation,
      'items': items,
    };
  }
}
