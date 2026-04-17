import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/github_contribution_calendar.dart';
import '../models/github_user.dart';
import '../services/github_auth_service.dart';
import '../widgets/contribution_graph_card.dart';
import 'settings/api_keys_screen.dart';
import 'usage_screen.dart';

/// Settings screen — shows profile, contribution activity, and app controls.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<GitHubContributionCalendar?>? _contributionFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _contributionFuture ??= _loadContributionCalendar();
  }

  Future<GitHubContributionCalendar?> _loadContributionCalendar() {
    final auth = context.read<GitHubAuthService>();
    return auth.apiService.getContributionCalendar();
  }

  void _refreshContributionCalendar() {
    setState(() {
      _contributionFuture = _loadContributionCalendar();
    });
  }

  Future<void> _signOut() async {
    final auth = context.read<GitHubAuthService>();
    await auth.logout();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<GitHubAuthService>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFFE6EDF3),
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFFE6EDF3)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          const _BackgroundGlow(
            alignment: Alignment.topRight,
            color: Color(0xFF39D353),
          ),
          const _BackgroundGlow(
            alignment: Alignment.centerLeft,
            color: Color(0xFF58A6FF),
            size: 180,
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                _HeroCard(user: user),
                const SizedBox(height: 14),
                if (_contributionFuture != null)
                  ContributionGraphCard(
                    future: _contributionFuture!,
                    onRetry: _refreshContributionCalendar,
                  ),
                const SizedBox(height: 16),
                const _SectionLabel(
                  title: 'Preferences',
                  subtitle: 'Tune the app to your workflow',
                ),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.key_rounded,
                  accent: const Color(0xFF39D353),
                  title: 'API Keys',
                  subtitle: 'Manage stored Groq keys',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ApiKeysScreen()),
                  ),
                ),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.bar_chart_rounded,
                  accent: const Color(0xFFF59E0B),
                  title: 'API Usage & Limits',
                  subtitle: 'Review request and token usage',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const UsageScreen()),
                  ),
                ),
                const SizedBox(height: 18),
                const _SectionLabel(
                  title: 'Security',
                  subtitle: 'End this local session when you are done',
                ),
                const SizedBox(height: 10),
                _SignOutCard(isLoading: auth.isLoading, onPressed: _signOut),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.user});

  final GitHubUser? user;

  @override
  Widget build(BuildContext context) {
    final displayName = user?.name?.trim().isNotEmpty == true
        ? user!.name!.trim()
        : (user?.login ?? 'unknown');
    final login = user?.login ?? 'unknown';
    final email = user?.email?.trim();

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF161B22), Color(0xFF0F1520)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF30363D)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(user: user),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Color(0xFFE6EDF3),
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@$login',
                      style: const TextStyle(
                        color: Color(0xFF8B949E),
                        fontSize: 11,
                      ),
                    ),
                    if (email != null && email.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(
                          color: Color(0xFF8B949E),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user});

  final GitHubUser? user;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF0F1720),
            border: Border.all(
              color: const Color(0xFF39D353).withValues(alpha: 0.28),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF39D353).withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipOval(
            child: user == null
                ? const Icon(
                    Icons.person_rounded,
                    color: Color(0xFF8B949E),
                    size: 28,
                  )
                : Image.network(
                    user!.avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person_rounded,
                      color: Color(0xFF8B949E),
                      size: 28,
                    ),
                  ),
          ),
        ),
        Positioned(
          right: 2,
          bottom: 2,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFF39D353),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF0B0F14), width: 3),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFE6EDF3),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF8B949E), fontSize: 11),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF161B22),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF30363D)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFFE6EDF3),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF8B949E),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF8B949E),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignOutCard extends StatelessWidget {
  const _SignOutCard({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1111),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This only signs out of the app on this device.',
            style: TextStyle(color: Color(0xFF8B949E), fontSize: 11),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
              onPressed: isLoading
                  ? null
                  : () async {
                      await onPressed();
                    },
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFFCA5A5),
                      ),
                    )
                  : const Icon(Icons.logout_rounded, size: 16),
              label: Text(isLoading ? 'Signing out…' : 'Sign out'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2B1A1A),
                foregroundColor: const Color(0xFFFCA5A5),
                disabledBackgroundColor: const Color(0xFF2B1A1A),
                disabledForegroundColor: const Color(0xFF8B949E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundGlow extends StatelessWidget {
  const _BackgroundGlow({
    required this.alignment,
    required this.color,
    this.size = 220,
  });

  final Alignment alignment;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: 0.18),
                color.withValues(alpha: 0.02),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}
