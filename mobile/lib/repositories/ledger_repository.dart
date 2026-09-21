import '../core/storage/local_store.dart';

class LedgerRepository {
  final LocalStore _store = LocalStore();

  List<Map<String, dynamic>> getCustomerLedger(int customerId) {
    final entries = _store.getCollection('ledger_entries');
    return entries.where((e) => e['customer_id'] == customerId).toList();
  }

  List<Map<String, dynamic>> getSupplierLedger(int supplierId) {
    final entries = _store.getCollection('ledger_entries');
    return entries.where((e) => e['supplier_id'] == supplierId).toList();
  }

  Future<Map<String, dynamic>> recordEntry({
    int? customerId,
    int? supplierId,
    required String voucherType,
    required String voucherNumber,
    required double debitAmount,
    required double creditAmount,
    required String narration,
    int? voucherId,
  }) async {
    final entries = _store.getCollection('ledger_entries');
    final id = _store.generateId('ledger_entries');

    final entry = {
      'id': id,
      'business_id': 1,
      if (customerId != null) 'customer_id': customerId,
      if (supplierId != null) 'supplier_id': supplierId,
      'entry_date': DateTime.now().toIso8601String().substring(0, 10),
      'voucher_type': voucherType,
      'voucher_number': voucherNumber,
      'debit_amount': debitAmount,
      'credit_amount': creditAmount,
      'narration': narration,
      'voucher_id': voucherId ?? 0,
    };

    entries.add(entry);
    _store.setCollection('ledger_entries', entries);
    await _store.save();
    return entry;
  }
}
