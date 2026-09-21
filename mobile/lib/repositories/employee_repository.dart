import '../core/storage/local_store.dart';
import '../core/security/password_hasher.dart';

class EmployeeRepository {
  final LocalStore _store = LocalStore();

  List<Map<String, dynamic>> getAll({String? search, String? role}) {
    var users = _store.getCollection('users');

    if (role != null && role.isNotEmpty && role != 'ALL') {
      users = users.where((u) => (u['role'] ?? '').toString().toLowerCase() == role.toLowerCase()).toList();
    }

    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      users = users.where((u) {
        final name = (u['name'] ?? '').toString().toLowerCase();
        final email = (u['email'] ?? '').toString().toLowerCase();
        final phone = (u['phone'] ?? '').toString().toLowerCase();
        return name.contains(q) || email.contains(q) || phone.contains(q);
      }).toList();
    }

    // Return without password hash for safety
    return users.map((u) {
      final copy = Map<String, dynamic>.from(u);
      copy.remove('password_hash');
      return copy;
    }).toList();
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final users = _store.getCollection('users');
    final id = _store.generateId('users');

    final password = data['password'] ?? 'welcome123';
    final passwordHash = PasswordHasher.hashPassword(password);

    final perms = (data['permissions'] as List?)?.map((e) => e.toString()).toList() ?? [];

    final newUser = {
      'id': id,
      'business_id': 1,
      'branch_id': data['branch_id'] ?? 1,
      'name': data['name'] ?? '',
      'email': data['email'] ?? '',
      'phone': data['phone'] ?? '',
      'password_hash': passwordHash,
      'role': data['role'] ?? 'Staff',
      'is_active': data['is_active'] ?? true,
      'permissions': perms,
    };

    users.add(newUser);
    _store.setCollection('users', users);
    await _store.save();

    final copy = Map<String, dynamic>.from(newUser);
    copy.remove('password_hash');
    return copy;
  }

  Future<Map<String, dynamic>?> update(int id, Map<String, dynamic> data) async {
    final users = _store.getCollection('users');
    final index = users.indexWhere((u) => u['id'] == id);
    if (index == -1) return null;

    final existing = users[index];

    String? passwordHash = existing['password_hash'];
    if (data.containsKey('password') && data['password'] != null && data['password'].toString().isNotEmpty) {
      passwordHash = PasswordHasher.hashPassword(data['password']);
    }

    final updated = {
      ...existing,
      ...data,
      'id': id,
      'password_hash': passwordHash,
    };

    users[index] = updated;
    _store.setCollection('users', users);
    await _store.save();

    final copy = Map<String, dynamic>.from(updated);
    copy.remove('password_hash');
    return copy;
  }

  Future<bool> toggleStatus(int id) async {
    final users = _store.getCollection('users');
    final index = users.indexWhere((u) => u['id'] == id);
    if (index == -1) return false;

    final current = users[index]['is_active'] ?? true;
    users[index]['is_active'] = !current;
    _store.setCollection('users', users);
    await _store.save();
    return true;
  }

  Future<bool> delete(int id) async {
    final users = _store.getCollection('users');
    final initialLen = users.length;
    users.removeWhere((u) => u['id'] == id);
    if (users.length != initialLen) {
      _store.setCollection('users', users);
      await _store.save();
      return true;
    }
    return false;
  }
}
