import '../core/storage/local_store.dart';

class ProductRepository {
  final LocalStore _store = LocalStore();

  List<Map<String, dynamic>> getAll({String? search, int? categoryId, bool? lowStock}) {
    var products = _store.getCollection('products');

    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      products = products.where((p) {
        final name = (p['name'] ?? '').toString().toLowerCase();
        final sku = (p['sku'] ?? '').toString().toLowerCase();
        final barcode = (p['barcode'] ?? '').toString().toLowerCase();
        final category = (p['category_name'] ?? '').toString().toLowerCase();
        return name.contains(q) || sku.contains(q) || barcode.contains(q) || category.contains(q);
      }).toList();
    }

    if (categoryId != null && categoryId > 0) {
      products = products.where((p) => p['category_id'] == categoryId).toList();
    }

    if (lowStock != null && lowStock) {
      products = products.where((p) {
        final current = (p['current_stock'] as num? ?? 0.0).toDouble();
        final min = (p['min_stock'] as num? ?? 10.0).toDouble();
        return current <= min;
      }).toList();
    }

    return products;
  }

  Map<String, dynamic>? getById(int id) {
    final products = _store.getCollection('products');
    for (final p in products) {
      if (p['id'] == id) return p;
    }
    return null;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final products = _store.getCollection('products');
    final id = _store.generateId('products');

    final categoryId = (data['category_id'] as num?)?.toInt();
    String categoryName = data['category_name'] ?? 'General';
    if (categoryId != null) {
      final categories = _store.getCollection('categories');
      final matchedCat = categories.firstWhere((c) => c['id'] == categoryId, orElse: () => {});
      if (matchedCat.isNotEmpty && matchedCat['name'] != null) {
        categoryName = matchedCat['name'];
      }
    }

    final currentStock = (data['current_stock'] as num? ?? data['initial_stock'] as num? ?? 0.0).toDouble();
    final minStock = (data['min_stock'] as num? ?? 10.0).toDouble();

    final newProduct = {
      'id': id,
      'business_id': data['business_id'] ?? 1,
      'category_id': categoryId,
      'category_name': categoryName,
      'name': data['name'] ?? '',
      'sku': data['sku'] ?? 'SKU-$id',
      'barcode': data['barcode'] ?? '',
      'unit': data['unit'] ?? 'PCS',
      'purchase_price': (data['purchase_price'] as num? ?? 0.0).toDouble(),
      'selling_price': (data['selling_price'] as num? ?? 0.0).toDouble(),
      'mrp': (data['mrp'] as num? ?? 0.0).toDouble(),
      'gst_rate': (data['gst_rate'] as num? ?? 18.0).toDouble(),
      'hsn_sac': data['hsn_sac'] ?? '8481',
      'min_stock': minStock,
      'current_stock': currentStock,
      'is_low_stock': currentStock <= minStock,
    };

    products.add(newProduct);
    _store.setCollection('products', products);
    await _store.save();
    return newProduct;
  }

  Future<Map<String, dynamic>?> update(int id, Map<String, dynamic> data) async {
    final products = _store.getCollection('products');
    final index = products.indexWhere((p) => p['id'] == id);
    if (index == -1) return null;

    final existing = products[index];

    final categoryId = data.containsKey('category_id') ? (data['category_id'] as num?)?.toInt() : existing['category_id'];
    String categoryName = existing['category_name'] ?? 'General';
    if (categoryId != null) {
      final categories = _store.getCollection('categories');
      final matchedCat = categories.firstWhere((c) => c['id'] == categoryId, orElse: () => {});
      if (matchedCat.isNotEmpty && matchedCat['name'] != null) {
        categoryName = matchedCat['name'];
      }
    }

    final currentStock = data.containsKey('current_stock')
        ? (data['current_stock'] as num? ?? 0.0).toDouble()
        : (existing['current_stock'] as num? ?? 0.0).toDouble();
    final minStock = data.containsKey('min_stock')
        ? (data['min_stock'] as num? ?? 10.0).toDouble()
        : (existing['min_stock'] as num? ?? 10.0).toDouble();

    final updated = {
      ...existing,
      ...data,
      'id': id,
      'category_id': categoryId,
      'category_name': categoryName,
      'current_stock': currentStock,
      'min_stock': minStock,
      'is_low_stock': currentStock <= minStock,
    };

    products[index] = updated;
    _store.setCollection('products', products);
    await _store.save();
    return updated;
  }

  Future<bool> delete(int id) async {
    final products = _store.getCollection('products');
    final initialLen = products.length;
    products.removeWhere((p) => p['id'] == id);
    if (products.length != initialLen) {
      _store.setCollection('products', products);
      await _store.save();
      return true;
    }
    return false;
  }

  List<Map<String, dynamic>> getCategories() {
    return _store.getCollection('categories');
  }

  Future<Map<String, dynamic>> createCategory(String name, String description) async {
    final categories = _store.getCollection('categories');
    final id = _store.generateId('categories');
    final newCat = {
      'id': id,
      'business_id': 1,
      'name': name,
      'description': description,
    };
    categories.add(newCat);
    _store.setCollection('categories', categories);
    await _store.save();
    return newCat;
  }
}
