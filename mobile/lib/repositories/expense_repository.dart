import '../core/storage/local_store.dart';

class ExpenseRepository {
  final LocalStore _store = LocalStore();

  List<Map<String, dynamic>> getAll() {
    return _store.getCollection('expenses').reversed.toList();
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final expenses = _store.getCollection('expenses');
    final id = _store.generateId('expenses');

    final newExp = {
      'id': id,
      'business_id': 1,
      'branch_id': 1,
      'title': data['title'] ?? '',
      'amount': (data['amount'] as num? ?? 0.0).toDouble(),
      'category': data['category'] ?? 'Operational',
      'vendor': data['vendor'] ?? '',
      'payment_method': data['payment_method'] ?? 'CASH',
      'expense_date': data['expense_date'] ?? DateTime.now().toIso8601String().substring(0, 10),
      'notes': data['notes'] ?? '',
      'created_at': DateTime.now().toIso8601String(),
    };

    expenses.add(newExp);
    _store.setCollection('expenses', expenses);
    await _store.save();
    return newExp;
  }

  List<String> getCategories() {
    return [
      'Operational',
      'Utilities & Electricity',
      'Rent & Maintenance',
      'Logistics & Freight',
      'Salaries & Wages',
      'Office Supplies',
      'Marketing & Ads',
      'Repairs & Machinery',
      'Other'
    ];
  }
}
