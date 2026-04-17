import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/github_commit.dart';
import '../services/repo_provider.dart';
import 'commit_detail_screen.dart';

/// Shows the commit history for the currently selected repo + branch.
class CommitListScreen extends StatefulWidget {
  const CommitListScreen({super.key});

  @override
  State<CommitListScreen> createState() => _CommitListScreenState();
}

class _CommitListScreenState extends State<CommitListScreen> {
  final _scrollController = ScrollController();
  final List<GitHubCommit> _commits = [];

  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCommits();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadCommits() async {
    final provider = context.read<RepoProvider>();
    final repo = provider.selectedRepo;
    if (repo == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _commits.clear();
      _page = 1;
      _hasMore = true;
    });

    try {
      final api = provider.apiService;
      final result = await api.getCommits(
        repo.owner,
        repo.name,
        sha: provider.selectedBranch?.name,
        page: 1,
      );
      if (!mounted) return;
      setState(() {
        _commits.addAll(result);
        _hasMore = result.length >= 20;
        _page = 2;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load commits: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    final provider = context.read<RepoProvider>();
    final repo = provider.selectedRepo;
    if (repo == null) return;

    setState(() => _isLoading = true);

    try {
      final api = provider.apiService;
      final result = await api.getCommits(
        repo.owner,
        repo.name,
        sha: provider.selectedBranch?.name,
        page: _page,
      );
      if (!mounted) return;
      setState(() {
        _commits.addAll(result);
        _hasMore = result.length >= 20;
        _page++;
      });
    } catch (_) {
      // Silently fail pagination
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RepoProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context, provider),
            Divider(height: 1, color: const Color(0xFF30363D)),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, RepoProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded,
                color: Color(0xFFE6EDF3), size: 22),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Commits',
                  style: TextStyle(
                    color: Color(0xFFE6EDF3),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                if (provider.selectedBranch != null)
                  Row(
                    children: [
                      Icon(Icons.call_split_rounded,
                          size: 11,
                          color: const Color(0xFF39D353).withValues(alpha: 0.7)),
                      const SizedBox(width: 4),
                      Text(
                        provider.selectedBranch!.name,
                        style: TextStyle(
                          color: const Color(0xFF8B949E),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Text(
            '${_commits.length} commits',
            style: TextStyle(
              color: const Color(0xFF8B949E),
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null && _commits.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 40, color: const Color(0xFF30363D)),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: const Color(0xFF8B949E), fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _loadCommits,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF39D353)),
            ),
          ],
        ),
      );
    }

    if (_isLoading && _commits.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF39D353)),
      );
    }

    if (_commits.isEmpty) {
      return Center(
        child: Text(
          'No commits found',
          style: TextStyle(
              color: const Color(0xFF8B949E), fontSize: 14),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCommits,
      color: const Color(0xFF39D353),
      backgroundColor: const Color(0xFF161B22),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 4, bottom: 24),
        itemCount: _commits.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, _) => Divider(
          height: 1,
          indent: 60,
          color: const Color(0xFF30363D),
        ),
        itemBuilder: (_, i) {
          if (i >= _commits.length) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF39D353)),
                ),
              ),
            );
          }
          return _CommitTile(
            commit: _commits[i],
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CommitDetailScreen(commit: _commits[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}

// — Commit tile ——————————————————————————————————————————

class _CommitTile extends StatelessWidget {
  const _CommitTile({required this.commit, required this.onTap});
  final GitHubCommit commit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: const Color(0xFF39D353).withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF30363D),
              backgroundImage: commit.authorAvatarUrl != null
                  ? NetworkImage(commit.authorAvatarUrl!)
                  : null,
              child: commit.authorAvatarUrl == null
                  ? Icon(Icons.person_rounded,
                      size: 16,
                      color: const Color(0xFF8B949E))
                  : null,
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    commit.title,
                    style: const TextStyle(
                      color: Color(0xFFE6EDF3),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // SHA badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF30363D),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          commit.shortSha,
                          style: TextStyle(
                            color: const Color(0xFF8B949E),
                            fontSize: 11,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        commit.authorLogin ?? commit.authorName,
                        style: TextStyle(
                          color: const Color(0xFF8B949E),
                          fontSize: 11.5,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _relativeTime(commit.date),
                        style: TextStyle(
                          color: const Color(0xFF8B949E),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Chevron
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Icon(Icons.chevron_right_rounded,
                  size: 18, color: const Color(0xFF30363D)),
            ),
          ],
        ),
      ),
    );
  }

  static String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 365) return '${diff.inDays ~/ 365}y ago';
    if (diff.inDays > 30) return '${diff.inDays ~/ 30}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}
