import 'package:flutter_dotenv/flutter_dotenv.dart';

/// App-wide configuration constants.
///
/// [clientId] and [clientSecret] are read from the `.env` file at runtime
/// so they never appear in source control.
class AppConfig {
  AppConfig._();

  /// GitHub OAuth App client ID — loaded from `.env`.
  static String get clientId => dotenv.env['GITHUB_CLIENT_ID'] ?? '';

  /// GitHub OAuth App client secret — loaded from `.env`.
  static String get clientSecret => dotenv.env['GITHUB_CLIENT_SECRET'] ?? '';

  /// Custom URI scheme registered in Android/iOS for OAuth redirect.
  static const redirectUri = 'com.monday.app://callback';

  /// Vercel backend base URL — used as fallback for token revocation etc.
  static const backendUrl = 'https://backend-ten-orcin-76.vercel.app';

  /// GitHub OAuth token exchange endpoint (POST).
  static const tokenUrl = 'https://github.com/login/oauth/access_token';

  /// GitHub OAuth scopes.
  static const scopes = ['repo', 'read:user'];

  /// GitHub API base.
  static const githubApiUrl = 'https://api.github.com';

  /// GitHub OAuth authorize URL.
  static const githubAuthUrl = 'https://github.com/login/oauth/authorize';
}
