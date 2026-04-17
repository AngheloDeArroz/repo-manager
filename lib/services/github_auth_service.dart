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

  /// Surface an error from outside (e.g. deep-link handler).
  void setError(String message) {
    _error = message;
    _isLoading = false;
    notifyListeners();
  }

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

  String? _lastHandledCode;

  /// Called when the app receives the OAuth redirect with an authorization code.
  ///
  /// POSTs directly to GitHub's token endpoint with `client_id`,
  /// `client_secret`, `code`, and `redirect_uri`.  The `Accept` header must
  /// be `application/json` so GitHub returns JSON rather than form-encoded
  /// data.
  Future<void> exchangeCode(String code) async {
    if (_lastHandledCode == code) {
      debugPrint('[OAuth] Ignoring duplicate code exchange request.');
      return;
    }
    _lastHandledCode = code;

    _isLoading = true;
    _error = null;
    notifyListeners();

    debugPrint('[OAuth] Exchanging authorization code for access token…');

    try {
      final res = await http.post(
        Uri.parse(AppConfig.tokenUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'client_id': AppConfig.clientId,
          'client_secret': AppConfig.clientSecret,
          'code': code,
          'redirect_uri': AppConfig.redirectUri,
        }),
      );

      debugPrint('[OAuth] Token response status: ${res.statusCode}');
      debugPrint('[OAuth] Token response body:   ${res.body}');

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      // GitHub returns 200 even on errors — check the body for an error key.
      if (data.containsKey('error')) {
        _error = (data['error_description'] as String?) ??
            (data['error'] as String?) ??
            'Token exchange failed';
        debugPrint('[OAuth] Error from GitHub: $_error');
        _isLoading = false;
        notifyListeners();
        return;
      }

      final token = data['access_token'] as String?;

      if (token == null || token.isEmpty) {
        _error = 'No access token received.';
        debugPrint('[OAuth] $_error');
        _isLoading = false;
        notifyListeners();
        return;
      }

      debugPrint('[OAuth] Token received — fetching user profile…');
      await storageService.setGitHubToken(token);
      _user = await apiService.getUser();
      _isLoggedIn = _user != null;

      if (!_isLoggedIn) {
        _error = 'Failed to fetch user profile.';
        debugPrint('[OAuth] $_error');
        await storageService.deleteGitHubToken();
      } else {
        debugPrint('[OAuth] Login complete — welcome ${_user!.login}');
      }
    } catch (e, st) {
      _error = 'Network error: $e';
      debugPrint('[OAuth] Exception during token exchange: $e\n$st');
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
