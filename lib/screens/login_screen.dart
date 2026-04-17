import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/github_auth_service.dart';

/// Login screen — required before accessing the app.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<GitHubAuthService>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // — Logo ——————————————————————————————————————
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF39D353), Color(0xFF26A641)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF39D353).withValues(alpha: 0.3),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'M',
                    style: TextStyle(
                      color: Color(0xFFE6EDF3),
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // — Title ————————————————————————————————————
              const Text(
                'Monday',
                style: TextStyle(
                  color: Color(0xFFE6EDF3),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'AI-powered GitHub assistant',
                style: TextStyle(
                  color: const Color(0xFF8B949E),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 48),

              // — GitHub sign-in button —————————————————————
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: auth.isLoading ? null : () => auth.login(),
                  icon: auth.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFFE6EDF3)),
                        )
                      : const Icon(Icons.code_rounded, size: 22),
                  label: Text(
                    auth.isLoading ? 'Connecting…' : 'Sign in with GitHub',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF24292F),
                    foregroundColor: const Color(0xFFE6EDF3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),

              // — Error ————————————————————————————————————
              if (auth.error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color:
                            const Color(0xFFEF4444).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Color(0xFFEF4444), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          auth.error!,
                          style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 40),

              // — Footer ———————————————————————————————————
              Text(
                'Your code stays on GitHub.\nWe only request repo & read:user scopes.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF8B949E),
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
