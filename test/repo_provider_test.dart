import 'package:flutter_test/flutter_test.dart';

import 'package:monday/models/github_branch.dart';
import 'package:monday/models/github_repo.dart';
import 'package:monday/models/github_tree_entry.dart';
import 'package:monday/services/github_api_service.dart';
import 'package:monday/services/repo_provider.dart';

class _FakeGitHubApiService extends GitHubApiService {
  _FakeGitHubApiService({required this.branches})
    : treeEntries = const [], super(getGitHubToken: () async => 'token');

  final List<GitHubBranch> branches;
  final List<GitHubTreeEntry> treeEntries;

  @override
  Future<List<GitHubBranch>> getBranches(String owner, String repo) async {
    return branches;
  }

  @override
  Future<List<GitHubTreeEntry>> getTree(
    String owner,
    String repo,
    String sha,
  ) async {
    return treeEntries;
  }
}

void main() {
  test('selectRepo leaves branch null when loading fails', () async {
    final provider = RepoProvider(
      apiService: _FakeGitHubApiService(branches: const []),
    );

    final repo = GitHubRepo(
      name: 'demo',
      fullName: 'octo/demo',
      owner: 'octo',
      defaultBranch: 'main',
      isPrivate: false,
      starCount: 0,
      updatedAt: DateTime(2026, 1, 1),
    );

    await provider.selectRepo(repo);

    expect(provider.selectedRepo?.fullName, repo.fullName);
    expect(provider.selectedBranch, isNull);
    expect(provider.branchError, contains('Could not load branches'));
    expect(provider.hasSelectedBranchSha, isFalse);
  });

  test(
    'selectRepo chooses the default branch when branches are loaded',
    () async {
      final provider = RepoProvider(
        apiService: _FakeGitHubApiService(
          branches: const [
            GitHubBranch(name: 'main', sha: 'abc123'),
            GitHubBranch(name: 'develop', sha: 'def456'),
          ],
        ),
      );

      final repo = GitHubRepo(
        name: 'demo',
        fullName: 'octo/demo',
        owner: 'octo',
        defaultBranch: 'main',
        isPrivate: false,
        starCount: 0,
        updatedAt: DateTime(2026, 1, 1),
      );

      await provider.selectRepo(repo);

      expect(provider.selectedBranch?.name, 'main');
      expect(provider.selectedBranch?.sha, 'abc123');
      expect(provider.branchError, isNull);
      expect(provider.hasSelectedBranchSha, isTrue);
    },
  );
}
