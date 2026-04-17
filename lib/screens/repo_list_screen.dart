import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/repo_provider.dart';
import '../widgets/repo_card.dart';
import 'repo_detail_screen.dart';

/// Lists the authenticated user's GitHub repositories with search and pagination.
class RepoListScreen extends StatefulWidget {
  const RepoListScreen({super.key});

  @override
  State<RepoListScreen> createState() => _RepoListScreenState();
}

class _RepoListScreenState extends State<RepoListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<RepoProvider>();
    if (provider.repos.isEmpty) {
      provider.loadRepos();
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<RepoProvider>().loadMoreRepos();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RepoProvider>();
    final repos = provider.filteredRepos;

    return Column(
      children: [
        // — Search bar ————————————————————————————————————
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF30363D),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF30363D),
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: provider.setSearchQuery,
              style: const TextStyle(color: Color(0xFFE6EDF3), fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Search repositories…',
                hintStyle:
                    TextStyle(color: const Color(0xFF8B949E)),
                prefixIcon: Icon(Icons.search_rounded,
                    size: 18, color: const Color(0xFF8B949E)),
                suffixIcon: provider.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded,
                            size: 16,
                            color: const Color(0xFF8B949E)),
                        onPressed: () {
                          _searchController.clear();
                          provider.setSearchQuery('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),

        // — Repo count ———————————————————————————————————
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              provider.searchQuery.isNotEmpty
                  ? '${repos.length} result${repos.length == 1 ? '' : 's'}'
                  : '${provider.repos.length} repositories',
              style: TextStyle(
                color: const Color(0xFF8B949E),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),

        // — List / states ——————————————————————————————————
        Expanded(
          child: _buildBody(provider, repos),
        ),
      ],
    );
  }

  Widget _buildBody(RepoProvider provider, List repos) {
    // Error
    if (provider.repoError != null && repos.isEmpty) {
      return _ErrorState(
        message: provider.repoError!,
        onRetry: provider.loadRepos,
      );
    }

    // Initial loading
    if (provider.isLoadingRepos && repos.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF39D353)),
      );
    }

    // Empty
    if (repos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded,
                size: 48, color: const Color(0xFF30363D)),
            const SizedBox(height: 12),
            Text(
              provider.searchQuery.isNotEmpty
                  ? 'No repos match your search'
                  : 'No repositories found',
              style: TextStyle(
                color: const Color(0xFF8B949E),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.loadRepos,
      color: const Color(0xFF39D353),
      backgroundColor: const Color(0xFF161B22),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 4, bottom: 16),
        itemCount: repos.length + (provider.hasMoreRepos ? 1 : 0),
        itemBuilder: (_, i) {
          if (i >= repos.length) {
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

          final repo = repos[i];
          return RepoCard(
            repo: repo,
            onTap: () {
              provider.selectRepo(repo);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const RepoDetailScreen(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// — Error state widget ———————————————————————————————————

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 40, color: const Color(0xFF30363D)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF8B949E),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF39D353),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
