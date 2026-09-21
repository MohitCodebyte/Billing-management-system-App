import '../core/storage/local_store.dart';
import '../core/constants/api_constants.dart';

class SettingsRepository {
  final LocalStore _store = LocalStore();

  Map<String, dynamic> getBusinessSettings() {
    return {
      'business': _store.getDocument('business'),
      'settings': _store.getDocument('settings'),
      'attribution': ApiConstants.copyrightAttribution,
    };
  }

  Future<bool> updateBusinessSettings(Map<String, dynamic> data) async {
    if (data.containsKey('business') && data['business'] is Map) {
      final curBiz = _store.getDocument('business');
      final updatedBiz = {
        ...curBiz,
        ...Map<String, dynamic>.from(data['business']),
      };
      _store.setDocument('business', updatedBiz);
    }

    if (data.containsKey('settings') && data['settings'] is Map) {
      final curSet = _store.getDocument('settings');
      final updatedSet = {
        ...curSet,
        ...Map<String, dynamic>.from(data['settings']),
      };
      _store.setDocument('settings', updatedSet);
    }

    await _store.save();
    return true;
  }

  Map<String, dynamic> getPrinterSettings() {
    return _store.getDocument('printer_settings');
  }

  Future<bool> updatePrinterSettings(Map<String, dynamic> data) async {
    final current = _store.getDocument('printer_settings');
    final updated = {
      ...current,
      ...data,
    };
    _store.setDocument('printer_settings', updated);
    await _store.save();
    return true;
  }
}
