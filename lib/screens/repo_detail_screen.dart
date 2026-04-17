import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/github_branch.dart';
import '../models/github_tree_entry.dart';
import '../services/repo_provider.dart';
import '../widgets/file_tree_tile.dart';
import 'branch_workflow_screen.dart';
import 'commit_list_screen.dart';
import 'file_viewer_screen.dart';

/// Detail screen for a selected repo — branch picker + file tree navigation.
class RepoDetailScreen extends StatelessWidget {
  const RepoDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RepoProvider>();
    final repo = provider.selectedRepo;

    if (repo == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D1117),
        body: Center(child: Text('No repo selected')),
      );
    }

    return PopScope(
      canPop: !provider.canNavigateUp,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          provider.navigateUp();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        body: SafeArea(
          child: Column(
            children: [
              // — App bar ———————————————————————————————————
              _buildAppBar(context, provider),

              // — Branch selector ——————————————————————————
              _BranchSelector(provider: provider),

              if (provider.branchError != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.18),
                      ),
                    ),
                    child: Text(
                      provider.branchError!,
                      style: TextStyle(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.95),
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),

              // — Breadcrumbs ——————————————————————————————
              if (provider.breadcrumbs.isNotEmpty)
                _Breadcrumbs(provider: provider),

              // — Divider —————————————————————————————————
              Divider(height: 1, color: const Color(0xFF30363D)),

              // — Tree ————————————————————————————————————
              Expanded(child: _buildTree(provider)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, RepoProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (provider.canNavigateUp) {
                provider.navigateUp();
              } else {
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFFE6EDF3),
              size: 22,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.selectedRepo!.name,
                  style: const TextStyle(
                    color: Color(0xFFE6EDF3),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  provider.selectedRepo!.owner,
                  style: TextStyle(
                    color: const Color(0xFF8B949E),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Commits button
          IconButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CommitListScreen())),
            icon: Icon(
              Icons.history_rounded,
              color: const Color(0xFF8B949E),
              size: 20,
            ),
            tooltip: 'Commits',
          ),
          // Workflow button
          IconButton(
            onPressed:
                provider.hasSelectedBranchSha && provider.branchError == null
                ? () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const BranchWorkflowScreen(),
                    ),
                  )
                : null,
            icon: Icon(
              Icons.rocket_launch_rounded,
              color: const Color(0xFF8B949E),
              size: 20,
            ),
            tooltip: provider.branchError ?? 'Branch Workflow',
          ),
          if (provider.selectedRepo!.isPrivate)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFBBF24).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_rounded, size: 11, color: Color(0xFFFBBF24)),
                  SizedBox(width: 3),
                  Text(
                    'Private',
                    style: TextStyle(
                      color: Color(0xFFFBBF24),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTree(RepoProvider provider) {
    if (provider.isLoadingTree) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF39D353)),
      );
    }

    if (provider.treeError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 36,
              color: const Color(0xFF30363D),
            ),
            const SizedBox(height: 10),
            Text(
              provider.treeError!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF8B949E),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: provider.refreshTree,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF39D353),
              ),
            ),
          ],
        ),
      );
    }

    final tree = provider.currentTree;
    if (tree.isEmpty) {
      return Center(
        child: Text(
          'Empty directory',
          style: TextStyle(
            color: const Color(0xFF8B949E),
            fontSize: 14,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      itemCount: tree.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        indent: 56,
        color: const Color(0xFF30363D),
      ),
      itemBuilder: (ctx, i) {
        final entry = tree[i];
        return FileTreeTile(
          entry: entry,
          onTap: () => _onEntryTap(ctx, entry, provider),
        );
      },
    );
  }

  void _onEntryTap(
    BuildContext context,
    GitHubTreeEntry entry,
    RepoProvider provider,
  ) {
    if (entry.isDirectory) {
      provider.navigateInto(entry);
    } else {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => FileViewerScreen(entry: entry)));
    }
  }
}

// — Branch selector pill ———————————————————————————————————

class _BranchSelector extends StatelessWidget {
  const _BranchSelector({required this.provider});
  final RepoProvider provider;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          InkWell(
            onTap: provider.isLoadingBranches
                ? null
                : () => _showBranchPicker(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF39D353).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF39D353).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.call_split_rounded,
                    size: 14,
                    color: Color(0xFF39D353),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    provider.selectedBranch?.name ?? '…',
                    style: const TextStyle(
                      color: Color(0xFF39D353),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: const Color(0xFF39D353).withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Text(
            '${provider.currentTree.length} items',
            style: TextStyle(
              color: const Color(0xFF8B949E),
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showBranchPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _BranchSheet(
        branches: provider.branches,
        selectedName: provider.selectedBranch?.name,
        onSelect: (branch) {
          Navigator.of(context).pop();
          provider.selectBranch(branch);
        },
      ),
    );
  }
}

// — Branch picker bottom sheet ————————————————————————————

class _BranchSheet extends StatelessWidget {
  const _BranchSheet({
    required this.branches,
    required this.selectedName,
    required this.onSelect,
  });

  final List<GitHubBranch> branches;
  final String? selectedName;
  final ValueChanged<GitHubBranch> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle bar
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFF30363D),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Switch branch',
              style: TextStyle(
                color: const Color(0xFF8B949E),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: branches.length,
            itemBuilder: (_, i) {
              final b = branches[i];
              final isSelected = b.name == selectedName;

              return ListTile(
                dense: true,
                leading: Icon(
                  Icons.call_split_rounded,
                  size: 16,
                  color: isSelected
                      ? const Color(0xFF39D353)
                      : const Color(0xFF8B949E),
                ),
                title: Text(
                  b.name,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF39D353)
                        : const Color(0xFF8B949E),
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Color(0xFF39D353),
                      )
                    : null,
                onTap: () => onSelect(b),
              );
            },
          ),
        ),
      ],
    );
  }
}

// — Breadcrumbs ——————————————————————————————————————————

class _Breadcrumbs extends StatelessWidget {
  const _Breadcrumbs({required this.provider});
  final RepoProvider provider;

  @override
  Widget build(BuildContext context) {
    final crumbs = provider.breadcrumbs;

    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: crumbs.length + 1, // +1 for root
        separatorBuilder: (_, _) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Icon(
            Icons.chevron_right_rounded,
            size: 14,
            color: const Color(0xFF30363D),
          ),
        ),
        itemBuilder: (_, i) {
          final isLast = i == crumbs.length;
          final label = i == 0 ? '/' : crumbs[i - 1];

          return GestureDetector(
            onTap: isLast
                ? null
                : () {
                    if (i == 0) {
                      // Navigate to root
                      while (provider.canNavigateUp) {
                        provider.navigateUp();
                      }
                    } else {
                      provider.navigateToBreadcrumb(i - 1);
                    }
                  },
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: isLast
                      ? const Color(0xFF8B949E)
                      : const Color(0xFF39D353).withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: isLast ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
