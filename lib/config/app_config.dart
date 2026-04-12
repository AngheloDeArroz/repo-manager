/// App-wide configuration constants.
///
/// [clientId] is the GitHub OAuth App's public client ID — safe in source.
/// [clientSecret] is NEVER stored here — it lives in the Vercel backend only.
class AppConfig {
  AppConfig._();

  /// GitHub OAuth App client ID (public).
  static const clientId = 'Ov23liJ1PFcqYRKaq8c8';

  /// Custom URI scheme registered in Android/iOS for OAuth redirect.
  static const redirectUri = 'com.monday.app://callback';

  /// Vercel backend base URL — update after deployment.
  /// Example: https://monday-backend.vercel.app
  static const backendUrl = 'https://backend-ten-orcin-76.vercel.app';

  /// GitHub OAuth scopes.
  static const scopes = ['repo', 'read:user'];

  /// GitHub API base.
  static const githubApiUrl = 'https://api.github.com';

  /// GitHub OAuth authorize URL.
  static const githubAuthUrl = 'https://github.com/login/oauth/authorize';
}
