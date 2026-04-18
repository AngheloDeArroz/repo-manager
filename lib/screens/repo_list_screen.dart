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

    return RefreshIndicator(
      onRefresh: provider.loadRepos,
      color: const Color(0xFF39D353),
      backgroundColor: const Color(0xFF161B22),
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Repositories',
                    style: TextStyle(
                      color: Color(0xFFE6EDF3),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B22),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF30363D)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: provider.setSearchQuery,
                      style: const TextStyle(
                        color: Color(0xFFE6EDF3),
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search repositories…',
                        hintStyle: const TextStyle(color: Color(0xFF8B949E)),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: Color(0xFF8B949E),
                        ),
                        suffixIcon: provider.searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: Color(0xFF8B949E),
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  provider.setSearchQuery('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // — Repo count ———————————————————————————————————
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Text(
                provider.searchQuery.isNotEmpty
                    ? '${repos.length} result${repos.length == 1 ? '' : 's'}'
                    : '${provider.repos.length} repositories',
                style: const TextStyle(
                  color: Color(0xFF8B949E),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),

          // — List / states ——————————————————————————————————
          _buildSliverBody(provider, repos),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildSliverBody(RepoProvider provider, List repos) {
    if (provider.repoError != null && repos.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _ErrorState(
          message: provider.repoError!,
          onRetry: provider.loadRepos,
        ),
      );
    }

    if (provider.isLoadingRepos && repos.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF39D353)),
        ),
      );
    }

    if (repos.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF30363D)),
                ),
                child: const Icon(
                  Icons.folder_off_rounded,
                  size: 40,
                  color: Color(0xFF39D353),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                provider.searchQuery.isNotEmpty
                    ? 'No repos match your search'
                    : 'No repositories found',
                style: const TextStyle(
                  color: Color(0xFF8B949E),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, i) {
        if (i >= repos.length) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF39D353),
                ),
              ),
            ),
          );
        }

        final repo = repos[i];
        return RepoCard(
          repo: repo,
          onTap: () {
            provider.selectRepo(repo);
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const RepoDetailScreen()));
          },
        );
      }, childCount: repos.length + (provider.hasMoreRepos ? 1 : 0)),
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                ),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFE6EDF3),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text(
                'Try Again',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39D353),
                foregroundColor: const Color(0xFF0D1117),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
