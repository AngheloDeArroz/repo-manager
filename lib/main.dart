import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/api_key_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/github_api_service.dart';
import 'services/github_auth_service.dart';
import 'services/groq_service.dart';
import 'services/model_provider.dart';
import 'services/rate_limiter.dart';
import 'services/secure_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = SecureStorageService();
  final rateLimiter = RateLimiter();
  final modelProvider = ModelProvider();
  final apiService = GitHubApiService(storageService: storageService);
  final authService = GitHubAuthService(
    storageService: storageService,
    apiService: apiService,
  );

  await Future.wait([
    rateLimiter.init(),
    modelProvider.init(),
    authService.init(),
  ]);

  runApp(MondayApp(
    storageService: storageService,
    rateLimiter: rateLimiter,
    modelProvider: modelProvider,
    authService: authService,
    apiService: apiService,
  ));
}

class MondayApp extends StatelessWidget {
  const MondayApp({
    super.key,
    required this.storageService,
    required this.rateLimiter,
    required this.modelProvider,
    required this.authService,
    required this.apiService,
  });

  final SecureStorageService storageService;
  final RateLimiter rateLimiter;
  final ModelProvider modelProvider;
  final GitHubAuthService authService;
  final GitHubApiService apiService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: modelProvider),
        ChangeNotifierProvider.value(value: rateLimiter),
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider(
          create: (_) => GroqService(
            storageService: storageService,
            rateLimiter: rateLimiter,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Monday',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0F0F1A),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF7C3AED),
            secondary: Color(0xFF2563EB),
            surface: Color(0xFF1E1E2E),
          ),
          fontFamily: 'Roboto',
          useMaterial3: true,
        ),
        home: _RootGate(storageService: storageService),
      ),
    );
  }
}

/// Gate flow: API key → GitHub login → Home.
///
/// Also listens for incoming deep links (`com.monday.app://callback?code=...`)
/// to complete the OAuth code exchange automatically.
class _RootGate extends StatefulWidget {
  const _RootGate({required this.storageService});
  final SecureStorageService storageService;

  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> {
  bool _loading = true;
  bool _hasApiKey = false;

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _checkKey();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  Future<void> _checkKey() async {
    final has = await widget.storageService.hasApiKey();
    if (mounted) {
      setState(() {
        _loading = false;
        _hasApiKey = has;
      });
    }
  }

  /// Set up deep-link handling for the OAuth callback.
  void _initDeepLinks() {
    _appLinks = AppLinks();

    // Cold start — app was not running when the link arrived
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleDeepLink(uri);
    });

    // Warm start — app is already running in the background
    _linkSub = _appLinks.uriLinkStream.listen(_handleDeepLink);
  }

  /// Extract the `code` query parameter and hand it to [GitHubAuthService].
  void _handleDeepLink(Uri uri) {
    // Only handle our OAuth callback scheme
    if (uri.scheme != 'com.monday.app') return;

    final code = uri.queryParameters['code'];
    if (code != null && code.isNotEmpty) {
      final auth = context.read<GitHubAuthService>();
      auth.exchangeCode(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F1A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
        ),
      );
    }

    // Step 1: Need Groq API key
    if (!_hasApiKey) {
      return ApiKeyScreen(
        onKeySaved: () => setState(() => _hasApiKey = true),
      );
    }

    // Step 2: Need GitHub login
    final auth = context.watch<GitHubAuthService>();
    if (!auth.isLoggedIn) {
      return const LoginScreen();
    }

    // Step 3: All set
    return const HomeScreen();
  }
}

