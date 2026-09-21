import '../core/storage/local_store.dart';

class CustomerRepository {
  final LocalStore _store = LocalStore();

  List<Map<String, dynamic>> getAll({String? search}) {
    var customers = _store.getCollection('customers');
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      customers = customers.where((c) {
        final name = (c['name'] ?? '').toString().toLowerCase();
        final company = (c['company_name'] ?? '').toString().toLowerCase();
        final phone = (c['phone'] ?? '').toString().toLowerCase();
        final gstin = (c['gstin'] ?? '').toString().toLowerCase();
        return name.contains(q) || company.contains(q) || phone.contains(q) || gstin.contains(q);
      }).toList();
    }
    return customers;
  }

  Map<String, dynamic>? getById(int id) {
    final customers = _store.getCollection('customers');
    final customer = customers.firstWhere((c) => c['id'] == id, orElse: () => {});
    if (customer.isEmpty) return null;

    final invoices = _store.getCollection('invoices')
        .where((inv) => inv['customer_id'] == id)
        .toList();
    final ledgerEntries = _store.getCollection('ledger_entries')
        .where((le) => le['customer_id'] == id)
        .toList();

    return {
      ...customer,
      'recent_invoices': invoices,
      'ledger_entries': ledgerEntries,
    };
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final customers = _store.getCollection('customers');
    final id = _store.generateId('customers');

    final openingBalance = (data['opening_balance'] as num? ?? 0.0).toDouble();
    final currentBalance = (data['current_balance'] as num? ?? openingBalance).toDouble();

    final newCust = {
      'id': id,
      'business_id': data['business_id'] ?? 1,
      'name': data['name'] ?? '',
      'company_name': data['company_name'] ?? '',
      'phone': data['phone'] ?? '',
      'email': data['email'] ?? '',
      'gstin': data['gstin'] ?? '',
      'address': data['address'] ?? '',
      'city': data['city'] ?? '',
      'state': data['state'] ?? 'Maharashtra',
      'credit_limit': (data['credit_limit'] as num? ?? 100000.0).toDouble(),
      'opening_balance': openingBalance,
      'current_balance': currentBalance,
    };

    customers.add(newCust);
    _store.setCollection('customers', customers);

    if (openingBalance > 0) {
      final ledgers = _store.getCollection('ledger_entries');
      final ledgerId = _store.generateId('ledger_entries');
      ledgers.add({
        'id': ledgerId,
        'business_id': 1,
        'customer_id': id,
        'entry_date': DateTime.now().toIso8601String().substring(0, 10),
        'voucher_type': 'OPENING',
        'voucher_number': 'OP-$id',
        'debit_amount': openingBalance,
        'credit_amount': 0.0,
        'narration': 'Opening Balance',
        'voucher_id': 0,
      });
      _store.setCollection('ledger_entries', ledgers);
    }

    await _store.save();
    return newCust;
  }

  Future<Map<String, dynamic>?> update(int id, Map<String, dynamic> data) async {
    final customers = _store.getCollection('customers');
    final index = customers.indexWhere((c) => c['id'] == id);
    if (index == -1) return null;

    final existing = customers[index];
    final updated = {
      ...existing,
      ...data,
      'id': id,
    };

    customers[index] = updated;
    _store.setCollection('customers', customers);
    await _store.save();
    return updated;
  }

  Future<bool> delete(int id) async {
    final customers = _store.getCollection('customers');
    final initialLen = customers.length;
    customers.removeWhere((c) => c['id'] == id);
    if (customers.length != initialLen) {
      _store.setCollection('customers', customers);
      await _store.save();
      return true;
    }
    return false;
  }

  Future<void> adjustBalance(int customerId, double delta) async {
    final customers = _store.getCollection('customers');
    final index = customers.indexWhere((c) => c['id'] == customerId);
    if (index != -1) {
      final current = (customers[index]['current_balance'] as num? ?? 0.0).toDouble();
      customers[index]['current_balance'] = current + delta;
      _store.setCollection('customers', customers);
      await _store.save();
    }
  }
}
