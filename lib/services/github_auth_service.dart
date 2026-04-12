import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../models/github_user.dart';
import 'github_api_service.dart';
import 'secure_storage_service.dart';

/// Manages the GitHub OAuth login flow.
///
/// Flow:
/// 1. [login] opens GitHub authorize URL in browser
/// 2. User approves → GitHub redirects to custom scheme with `?code=...`
/// 3. App catches the deep link and calls [exchangeCode]
/// 4. Backend exchanges code for access token
/// 5. Token stored in secure storage, user profile fetched
class GitHubAuthService extends ChangeNotifier {
  GitHubAuthService({
    required this.storageService,
    required this.apiService,
  });

  final SecureStorageService storageService;
  final GitHubApiService apiService;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  GitHubUser? _user;
  GitHubUser? get user => _user;

  String? _error;
  String? get error => _error;

  /// Call once at app startup to check for an existing session.
  Future<void> init() async {
    final token = await storageService.getGitHubToken();
    if (token != null) {
      _user = await apiService.getUser();
      _isLoggedIn = _user != null;

      // Token exists but profile fetch failed → token may be revoked
      if (!_isLoggedIn) {
        await storageService.deleteGitHubToken();
      }
    }
    notifyListeners();
  }

  /// Open GitHub OAuth in the browser.
  /// The app must handle the redirect via deep link and call [exchangeCode].
  Future<void> login() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final uri = Uri.parse(AppConfig.githubAuthUrl).replace(queryParameters: {
      'client_id': AppConfig.clientId,
      'redirect_uri': AppConfig.redirectUri,
      'scope': AppConfig.scopes.join(' '),
    });

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      _error = 'Could not open browser for login.';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Called when the app receives the OAuth redirect with an authorization code.
  Future<void> exchangeCode(String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await http.post(
        Uri.parse('${AppConfig.backendUrl}/api/auth/token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'code': code}),
      );

      if (res.statusCode != 200) {
        final body = jsonDecode(res.body);
        _error = body['error_description'] ?? body['error'] ?? 'Token exchange failed';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final data = jsonDecode(res.body);
      final token = data['access_token'] as String?;

      if (token == null || token.isEmpty) {
        _error = 'No access token received.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      await storageService.setGitHubToken(token);
      _user = await apiService.getUser();
      _isLoggedIn = _user != null;

      if (!_isLoggedIn) {
        _error = 'Failed to fetch user profile.';
        await storageService.deleteGitHubToken();
      }
    } catch (e) {
      _error = 'Network error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign out — revoke token on GitHub and wipe local storage.
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    final token = await storageService.getGitHubToken();
    if (token != null) {
      try {
        await http.post(
          Uri.parse('${AppConfig.backendUrl}/api/auth/revoke'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'token': token}),
        );
      } catch (_) {
        // Best-effort revocation — wipe locally regardless
      }
    }

    await storageService.deleteGitHubToken();
    _user = null;
    _isLoggedIn = false;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
