import '../core/storage/local_store.dart';

class InventoryRepository {
  final LocalStore _store = LocalStore();

  Future<bool> adjustStock({
    required int productId,
    required double quantity,
    required String movementType, // IN, OUT, ADJUSTMENT, DAMAGE, RETURN
    String? notes,
  }) async {
    final products = _store.getCollection('products');
    final index = products.indexWhere((p) => p['id'] == productId);
    if (index == -1) return false;

    final product = products[index];
    final currentStock = (product['current_stock'] as num? ?? 0.0).toDouble();
    final minStock = (product['min_stock'] as num? ?? 10.0).toDouble();

    double newStock;
    if (movementType == 'IN' || movementType == 'RETURN') {
      newStock = currentStock + quantity;
    } else if (movementType == 'OUT' || movementType == 'DAMAGE') {
      newStock = currentStock - quantity;
    } else {
      // ADJUSTMENT sets or adjusts
      newStock = quantity;
    }

    product['current_stock'] = newStock;
    product['is_low_stock'] = newStock <= minStock;
    products[index] = product;
    _store.setCollection('products', products);

    final stockMovements = _store.getCollection('stock_movements');
    final movId = _store.generateId('stock_movements');
    stockMovements.add({
      'id': movId,
      'product_id': productId,
      'product_name': product['name'],
      'movement_type': movementType,
      'quantity': quantity,
      'balance_after': newStock,
      'reference_type': 'MANUAL',
      'reference_id': 0,
      'notes': notes ?? 'Manual Stock Adjustment ($movementType)',
      'timestamp': DateTime.now().toIso8601String(),
    });
    _store.setCollection('stock_movements', stockMovements);

    await _store.save();
    return true;
  }

  List<Map<String, dynamic>> getStockHistory({int? productId}) {
    var history = _store.getCollection('stock_movements');
    if (productId != null && productId > 0) {
      history = history.where((m) => m['product_id'] == productId).toList();
    }
    return history.reversed.toList();
  }
}
