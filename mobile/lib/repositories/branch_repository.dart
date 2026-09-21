import '../core/storage/local_store.dart';

class BranchRepository {
  final LocalStore _store = LocalStore();

  List<Map<String, dynamic>> getAll({String? search}) {
    var branches = _store.getCollection('branches');
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      branches = branches.where((b) {
        final name = (b['name'] ?? '').toString().toLowerCase();
        final code = (b['code'] ?? '').toString().toLowerCase();
        final city = (b['city'] ?? '').toString().toLowerCase();
        return name.contains(q) || code.contains(q) || city.contains(q);
      }).toList();
    }
    return branches;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final branches = _store.getCollection('branches');
    final id = _store.generateId('branches');

    final newBranch = {
      'id': id,
      'business_id': 1,
      'name': data['name'] ?? 'Branch $id',
      'code': data['code'] ?? 'BR-0$id',
      'phone': data['phone'] ?? '',
      'email': data['email'] ?? '',
      'address': data['address'] ?? '',
      'city': data['city'] ?? '',
      'state': data['state'] ?? 'Maharashtra',
      'gstin': data['gstin'] ?? '',
      'is_head_office': data['is_head_office'] ?? false,
    };

    if (newBranch['is_head_office'] == true) {
      for (var b in branches) {
        b['is_head_office'] = false;
      }
    }

    branches.add(newBranch);
    _store.setCollection('branches', branches);
    await _store.save();
    return newBranch;
  }

  Future<Map<String, dynamic>?> update(int id, Map<String, dynamic> data) async {
    final branches = _store.getCollection('branches');
    final index = branches.indexWhere((b) => b['id'] == id);
    if (index == -1) return null;

    final existing = branches[index];
    final updated = {
      ...existing,
      ...data,
      'id': id,
    };

    if (updated['is_head_office'] == true) {
      for (var b in branches) {
        b['is_head_office'] = false;
      }
    }

    branches[index] = updated;
    _store.setCollection('branches', branches);
    await _store.save();
    return updated;
  }

  Future<bool> delete(int id) async {
    final branches = _store.getCollection('branches');
    if (branches.length <= 1) {
      throw Exception("Cannot delete the only branch");
    }
    final initialLen = branches.length;
    branches.removeWhere((b) => b['id'] == id);
    if (branches.length != initialLen) {
      _store.setCollection('branches', branches);
      await _store.save();
      return true;
    }
    return false;
  }
}
