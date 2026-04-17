import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/api_key_entry.dart';

/// Single point of access for secure key/value storage.
///
/// All sensitive data (API keys, tokens) flows through this service —
/// no other file should import [FlutterSecureStorage] directly.
class SecureStorageService {
  SecureStorageService() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _groqApiKeysListKey = 'groq_api_keys_list';
  static const _githubTokenKey = 'github_access_token';

  // — Groq ————————————————————————————————————————————

  Future<List<ApiKeyEntry>> getApiKeys() async {
    final str = await _storage.read(key: _groqApiKeysListKey);
    if (str == null || str.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(str);
      return decoded.map((e) => ApiKeyEntry.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveApiKeys(List<ApiKeyEntry> keys) async {
    final str = jsonEncode(keys.map((e) => e.toJson()).toList());
    await _storage.write(key: _groqApiKeysListKey, value: str);
  }

  // Wipe the old single key if present (optional cleanup)
  Future<void> cleanUpOldKeys() => _storage.delete(key: 'groq_api_key');

  // — GitHub (placeholder for Feature 2) ——————————————

  Future<String?> getGitHubToken() => _storage.read(key: _githubTokenKey);

  Future<void> setGitHubToken(String value) =>
      _storage.write(key: _githubTokenKey, value: value);

  Future<void> deleteGitHubToken() => _storage.delete(key: _githubTokenKey);

  /// Wipe everything on logout.
  Future<void> clearAll() => _storage.deleteAll();
}
