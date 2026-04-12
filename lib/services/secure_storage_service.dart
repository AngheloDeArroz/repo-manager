import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Single point of access for secure key/value storage.
///
/// All sensitive data (API keys, tokens) flows through this service —
/// no other file should import [FlutterSecureStorage] directly.
class SecureStorageService {
  SecureStorageService() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _groqApiKeyKey = 'groq_api_key';
  static const _githubTokenKey = 'github_access_token';

  // — Groq ————————————————————————————————————————————

  Future<String?> getApiKey() => _storage.read(key: _groqApiKeyKey);

  Future<void> setApiKey(String value) =>
      _storage.write(key: _groqApiKeyKey, value: value);

  Future<void> deleteApiKey() => _storage.delete(key: _groqApiKeyKey);

  Future<bool> hasApiKey() async => (await getApiKey()) != null;

  // — GitHub (placeholder for Feature 2) ——————————————

  Future<String?> getGitHubToken() => _storage.read(key: _githubTokenKey);

  Future<void> setGitHubToken(String value) =>
      _storage.write(key: _githubTokenKey, value: value);

  Future<void> deleteGitHubToken() => _storage.delete(key: _githubTokenKey);

  /// Wipe everything on logout.
  Future<void> clearAll() => _storage.deleteAll();
}
