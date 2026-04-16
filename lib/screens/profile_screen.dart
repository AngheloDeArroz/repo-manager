import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/github_auth_service.dart';
import '../services/model_provider.dart';
import 'model_switcher_screen.dart';
import 'settings/api_keys_screen.dart';

/// Profile screen — shows avatar, username, and sign-out button.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<GitHubAuthService>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // — Avatar ——————————————————————————————————
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  backgroundImage:
                      user != null ? NetworkImage(user.avatarUrl) : null,
                  child: user == null
                      ? Icon(Icons.person_rounded,
                          size: 40,
                          color: Colors.white.withValues(alpha: 0.3))
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              // — Name ————————————————————————————————————
              if (user?.name != null)
                Text(
                  user!.name!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              const SizedBox(height: 4),

              // — Username ————————————————————————————————
              Text(
                '@${user?.login ?? '—'}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 15,
                ),
              ),

              if (user?.email != null) ...[
                const SizedBox(height: 4),
                Text(
                  user!.email!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 13,
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // — API Keys tile ——————————————————————————————
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const ApiKeysScreen()),
                  ),
                  icon: Icon(Icons.key_rounded,
                      size: 18,
                      color: const Color(0xFF2563EB).withValues(alpha: 0.8)),
                  label: Row(
                    children: [
                      const Text(
                        'API Keys',
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right_rounded,
                          size: 18,
                          color: Colors.white.withValues(alpha: 0.2)),
                    ],
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // — Model switcher tile ——————————————————————
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const ModelSwitcherScreen()),
                  ),
                  icon: Icon(Icons.psychology_rounded,
                      size: 18,
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.8)),
                  label: Row(
                    children: [
                      const Text(
                        'AI Model',
                        style: TextStyle(
                          color: Color(0xFF7C3AED),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        context.watch<ModelProvider>().currentModel.label,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded,
                          size: 18,
                          color: Colors.white.withValues(alpha: 0.2)),
                    ],
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // — Sign out button ——————————————————————————
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: auth.isLoading
                      ? null
                      : () async {
                          await auth.logout();
                          if (context.mounted) {
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                          }
                        },
                  icon: auth.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFFEF4444)),
                        )
                      : const Icon(Icons.logout_rounded,
                          size: 18, color: Color(0xFFEF4444)),
                  label: Text(
                    auth.isLoading ? 'Signing out…' : 'Sign out',
                    style: const TextStyle(
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color:
                            const Color(0xFFEF4444).withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
