import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/github_contribution_calendar.dart';
import '../services/activity_tracker.dart';
import '../services/github_auth_service.dart';
import '../widgets/contribution_graph_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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

  @override
  Widget build(BuildContext context) {
    final tracker = context.watch<ActivityTracker>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  if (_contributionFuture != null)
                    ContributionGraphCard(
                      future: _contributionFuture!,
                      onRetry: _refreshContributionCalendar,
                    ),
                  const SizedBox(height: 16),
                  _buildStatsCard(tracker.pushCount),
                  const SizedBox(height: 24),
                  const Text(
                    'Recent Pushes',
                    style: TextStyle(
                      color: Color(0xFFE6EDF3),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (tracker.pushedBranches.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No pushes recorded yet.',
                          style: TextStyle(color: Color(0xFF8B949E)),
                        ),
                      ),
                    )
                  else
                    ...tracker.pushedBranches.map((p) => _buildPushTile(p)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(int totalPushes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF39D353).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_upload_rounded,
              color: Color(0xFF39D353),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Pushes',
                style: TextStyle(
                  color: Color(0xFF8B949E),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$totalPushes',
                style: const TextStyle(
                  color: Color(0xFFE6EDF3),
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPushTile(Map<String, String> pushData) {
    final repo = pushData['repo'] ?? 'Unknown Repo';
    final branch = pushData['branch'] ?? 'Unknown Branch';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.call_split_rounded,
            color: Color(0xFF8B949E),
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  branch,
                  style: const TextStyle(
                    color: Color(0xFFE6EDF3),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  repo,
                  style: const TextStyle(
                    color: Color(0xFF8B949E),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
