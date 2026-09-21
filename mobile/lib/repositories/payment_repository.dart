import '../core/storage/local_store.dart';

class PaymentRepository {
  final LocalStore _store = LocalStore();

  List<Map<String, dynamic>> getAll() {
    return _store.getCollection('payments').reversed.toList();
  }

  Future<Map<String, dynamic>> createPayment(Map<String, dynamic> data) async {
    final payments = _store.getCollection('payments');
    final id = _store.generateId('payments');

    final pay = {
      'id': id,
      'business_id': 1,
      'reference_type': data['reference_type'] ?? 'GENERAL',
      'reference_id': data['reference_id'] ?? 0,
      'party_type': data['party_type'] ?? 'CUSTOMER',
      'party_id': data['party_id'] ?? 0,
      'party_name': data['party_name'] ?? 'Party',
      'amount': (data['amount'] as num? ?? 0.0).toDouble(),
      'payment_method': data['payment_method'] ?? 'CASH',
      'payment_date': data['payment_date'] ?? DateTime.now().toIso8601String().substring(0, 10),
      'status': data['status'] ?? 'SUCCESSFUL',
      'invoice_number': data['invoice_number'] ?? '',
      'notes': data['notes'] ?? '',
    };

    payments.add(pay);
    _store.setCollection('payments', payments);
    await _store.save();
    return pay;
  }
}
