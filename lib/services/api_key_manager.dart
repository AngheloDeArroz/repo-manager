import 'package:flutter/foundation.dart';
import '../models/api_key_entry.dart';
import 'secure_storage_service.dart';

class ApiKeyManager extends ChangeNotifier {
  ApiKeyManager({required this.storageService});

  final SecureStorageService storageService;

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  List<ApiKeyEntry> _keys = [];
  List<ApiKeyEntry> get keys => List.unmodifiable(_keys);

  Future<void> init() async {
    await storageService.cleanUpOldKeys();
    _keys = await storageService.getApiKeys();
    _isLoaded = true;
    notifyListeners();
  }

  ApiKeyEntry? getActiveKey() {
    if (_keys.isEmpty) return null;
    
    try {
      return _keys.firstWhere((k) => k.isDefault);
    } catch (_) {
      // If no default, the most recently added is the active one
      final sorted = List<ApiKeyEntry>.from(_keys)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return sorted.first;
    }
  }

  Future<void> addKey(String label, String value) async {
    final isFirst = _keys.isEmpty;
    final newKey = ApiKeyEntry(
      label: label,
      value: value,
      createdAt: DateTime.now(),
      isDefault: isFirst, // First key is default
    );
    _keys.add(newKey);
    await storageService.saveApiKeys(_keys);
    notifyListeners();
  }

  Future<void> deleteKey(String id) async {
    _keys.removeWhere((k) => k.id == id);
    // If we deleted the default, set the most recent as default
    if (_keys.isNotEmpty && !_keys.any((k) => k.isDefault)) {
      final sorted = List<ApiKeyEntry>.from(_keys)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      setDefaultKey(sorted.first.id);
    } else {
      await storageService.saveApiKeys(_keys);
      notifyListeners();
    }
  }

  Future<void> setDefaultKey(String id) async {
    _keys = _keys.map((k) => k.copyWith(isDefault: k.id == id)).toList();
    await storageService.saveApiKeys(_keys);
    notifyListeners();
  }
}
