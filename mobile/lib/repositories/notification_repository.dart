import '../core/storage/local_store.dart';

class NotificationRepository {
  final LocalStore _store = LocalStore();

  Map<String, dynamic> getAll() {
    final list = _store.getCollection('notifications').reversed.toList();
    final unread = list.where((n) => n['is_read'] != true).length;
    return {
      'notifications': list,
      'unread_count': unread,
    };
  }

  Future<bool> markAsRead(int id) async {
    final notifications = _store.getCollection('notifications');
    final index = notifications.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      notifications[index]['is_read'] = true;
      _store.setCollection('notifications', notifications);
      await _store.save();
      return true;
    }
    return false;
  }

  Future<bool> markAllAsRead() async {
    final notifications = _store.getCollection('notifications');
    for (var n in notifications) {
      n['is_read'] = true;
    }
    _store.setCollection('notifications', notifications);
    await _store.save();
    return true;
  }

  Future<void> addNotification({
    required String type,
    required String title,
    required String message,
    String? referenceType,
    int? referenceId,
  }) async {
    final notifications = _store.getCollection('notifications');
    final id = _store.generateId('notifications');
    notifications.add({
      'id': id,
      'business_id': 1,
      'type': type,
      'title': title,
      'message': message,
      'reference_type': referenceType ?? 'GENERAL',
      'reference_id': referenceId ?? 0,
      'created_at': DateTime.now().toIso8601String(),
      'is_read': false,
    });
    _store.setCollection('notifications', notifications);
    await _store.save();
  }
}
