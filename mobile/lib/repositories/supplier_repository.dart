import '../core/storage/local_store.dart';

class SupplierRepository {
  final LocalStore _store = LocalStore();

  List<Map<String, dynamic>> getAll({String? search}) {
    var suppliers = _store.getCollection('suppliers');
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      suppliers = suppliers.where((s) {
        final name = (s['name'] ?? '').toString().toLowerCase();
        final comp = (s['company_name'] ?? '').toString().toLowerCase();
        final phone = (s['phone'] ?? '').toString().toLowerCase();
        final gstin = (s['gstin'] ?? '').toString().toLowerCase();
        return name.contains(q) || comp.contains(q) || phone.contains(q) || gstin.contains(q);
      }).toList();
    }
    return suppliers;
  }

  Map<String, dynamic>? getById(int id) {
    final suppliers = _store.getCollection('suppliers');
    final supplier = suppliers.firstWhere((s) => s['id'] == id, orElse: () => {});
    if (supplier.isEmpty) return null;

    final purchases = _store.getCollection('purchases')
        .where((p) => p['supplier_id'] == id)
        .toList();
    final ledgerEntries = _store.getCollection('ledger_entries')
        .where((le) => le['supplier_id'] == id)
        .toList();

    return {
      ...supplier,
      'recent_purchases': purchases,
      'ledger_entries': ledgerEntries,
    };
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final suppliers = _store.getCollection('suppliers');
    final id = _store.generateId('suppliers');

    final openingBalance = (data['opening_balance'] as num? ?? 0.0).toDouble();
    final currentPayable = (data['current_payable'] as num? ?? openingBalance).toDouble();

    final newSup = {
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
      'opening_balance': openingBalance,
      'current_payable': currentPayable,
    };

    suppliers.add(newSup);
    _store.setCollection('suppliers', suppliers);

    if (openingBalance > 0) {
      final ledgers = _store.getCollection('ledger_entries');
      ledgers.add({
        'id': _store.generateId('ledger_entries'),
        'business_id': 1,
        'supplier_id': id,
        'entry_date': DateTime.now().toIso8601String().substring(0, 10),
        'voucher_type': 'OPENING',
        'voucher_number': 'OP-SUP-$id',
        'debit_amount': 0.0,
        'credit_amount': openingBalance,
        'narration': 'Supplier Opening Payable Balance',
        'voucher_id': 0,
      });
      _store.setCollection('ledger_entries', ledgers);
    }

    await _store.save();
    return newSup;
  }

  Future<Map<String, dynamic>?> update(int id, Map<String, dynamic> data) async {
    final suppliers = _store.getCollection('suppliers');
    final index = suppliers.indexWhere((s) => s['id'] == id);
    if (index == -1) return null;

    final existing = suppliers[index];
    final updated = {
      ...existing,
      ...data,
      'id': id,
    };

    suppliers[index] = updated;
    _store.setCollection('suppliers', suppliers);
    await _store.save();
    return updated;
  }

  Future<bool> delete(int id) async {
    final suppliers = _store.getCollection('suppliers');
    final initialLen = suppliers.length;
    suppliers.removeWhere((s) => s['id'] == id);
    if (suppliers.length != initialLen) {
      _store.setCollection('suppliers', suppliers);
      await _store.save();
      return true;
    }
    return false;
  }

  Future<void> adjustPayable(int supplierId, double delta) async {
    final suppliers = _store.getCollection('suppliers');
    final index = suppliers.indexWhere((s) => s['id'] == supplierId);
    if (index != -1) {
      final curr = (suppliers[index]['current_payable'] as num? ?? 0.0).toDouble();
      suppliers[index]['current_payable'] = (curr + delta) > 0 ? (curr + delta) : 0.0;
      _store.setCollection('suppliers', suppliers);
      await _store.save();
    }
  }
}
