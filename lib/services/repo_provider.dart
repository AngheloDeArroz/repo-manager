import 'package:flutter/foundation.dart';

import '../models/github_branch.dart';
import '../models/github_repo.dart';
import '../models/github_tree_entry.dart';
import 'github_api_service.dart';

/// State manager for the GitHub repo browser.
///
/// Holds repos, branches, and a stack of tree levels for directory navigation.
class RepoProvider extends ChangeNotifier {
  RepoProvider({required this.apiService});

  final GitHubApiService apiService;

  // — Repos ——————————————————————————————————————————————

  List<GitHubRepo> _repos = [];
  List<GitHubRepo> get repos => _repos;

  bool _isLoadingRepos = false;
  bool get isLoadingRepos => _isLoadingRepos;

  bool _hasMoreRepos = true;
  bool get hasMoreRepos => _hasMoreRepos;

  int _repoPage = 1;

  String? _repoError;
  String? get repoError => _repoError;

  /// Filter query applied client-side.
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  List<GitHubRepo> get filteredRepos {
    if (_searchQuery.isEmpty) return _repos;
    final q = _searchQuery.toLowerCase();
    return _repos
        .where((r) =>
            r.name.toLowerCase().contains(q) ||
            (r.description?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Load the first page (also used for pull-to-refresh).
  Future<void> loadRepos() async {
    _repoPage = 1;
    _hasMoreRepos = true;
    _isLoadingRepos = true;
    _repoError = null;
    notifyListeners();

    try {
      final result = await apiService.getRepos(page: 1);
      _repos = result;
      _hasMoreRepos = result.length >= 30;
      _repoPage = 2;
    } catch (e) {
      _repoError = 'Failed to load repos: $e';
    } finally {
      _isLoadingRepos = false;
      notifyListeners();
    }
  }

  /// Append the next page.
  Future<void> loadMoreRepos() async {
    if (_isLoadingRepos || !_hasMoreRepos) return;
    _isLoadingRepos = true;
    notifyListeners();

    try {
      final result = await apiService.getRepos(page: _repoPage);
      _repos.addAll(result);
      _hasMoreRepos = result.length >= 30;
      _repoPage++;
    } catch (e) {
      _repoError = 'Failed to load more repos: $e';
    } finally {
      _isLoadingRepos = false;
      notifyListeners();
    }
  }

  // — Selected repo ——————————————————————————————————————

  GitHubRepo? _selectedRepo;
  GitHubRepo? get selectedRepo => _selectedRepo;

  // — Branches ——————————————————————————————————————————

  List<GitHubBranch> _branches = [];
  List<GitHubBranch> get branches => _branches;

  GitHubBranch? _selectedBranch;
  GitHubBranch? get selectedBranch => _selectedBranch;

  bool _isLoadingBranches = false;
  bool get isLoadingBranches => _isLoadingBranches;

  // — Tree ——————————————————————————————————————————————

  /// Stack of directory levels — each entry is the tree at that depth.
  final List<_TreeLevel> _treeStack = [];

  List<GitHubTreeEntry> get currentTree =>
      _treeStack.isNotEmpty ? _treeStack.last.entries : [];

  /// Breadcrumb path segments (e.g. ["lib", "services"]).
  List<String> get breadcrumbs =>
      _treeStack.map((l) => l.name).skip(1).toList();

  bool get canNavigateUp => _treeStack.length > 1;

  bool _isLoadingTree = false;
  bool get isLoadingTree => _isLoadingTree;

  String? _treeError;
  String? get treeError => _treeError;

  // — Actions ———————————————————————————————————————————

  /// Select a repo → load its branches → load the default branch tree.
  Future<void> selectRepo(GitHubRepo repo) async {
    _selectedRepo = repo;
    _branches = [];
    _selectedBranch = null;
    _treeStack.clear();
    _treeError = null;
    notifyListeners();

    // Load branches
    _isLoadingBranches = true;
    notifyListeners();

    _branches = await apiService.getBranches(repo.owner, repo.name);
    _isLoadingBranches = false;

    // Pre-select default branch
    _selectedBranch = _branches.firstWhere(
      (b) => b.name == repo.defaultBranch,
      orElse: () => _branches.isNotEmpty
          ? _branches.first
          : GitHubBranch(name: repo.defaultBranch, sha: ''),
    );
    notifyListeners();

    // Load root tree
    if (_selectedBranch != null && _selectedBranch!.sha.isNotEmpty) {
      await _loadTree(_selectedBranch!.sha, '/');
    }
  }

  /// Switch to a different branch → reload root tree.
  Future<void> selectBranch(GitHubBranch branch) async {
    _selectedBranch = branch;
    _treeStack.clear();
    _treeError = null;
    notifyListeners();

    if (branch.sha.isNotEmpty) {
      await _loadTree(branch.sha, '/');
    }
  }

  /// Navigate into a directory entry.
  Future<void> navigateInto(GitHubTreeEntry entry) async {
    if (!entry.isDirectory) return;
    await _loadTree(entry.sha, entry.path);
  }

  /// Go up one level in the tree.
  void navigateUp() {
    if (!canNavigateUp) return;
    _treeStack.removeLast();
    notifyListeners();
  }

  /// Navigate to a specific breadcrumb depth (0 = root).
  void navigateToBreadcrumb(int index) {
    // index is relative to breadcrumbs (which skips root),
    // so actual stack index is index + 1.
    final stackIndex = index + 1;
    while (_treeStack.length > stackIndex + 1) {
      _treeStack.removeLast();
    }
    notifyListeners();
  }

  /// Re-fetch the current tree level.
  Future<void> refreshTree() async {
    if (_treeStack.isEmpty) return;
    final current = _treeStack.last;
    _treeStack.removeLast();
    await _loadTree(current.sha, current.name);
  }

  // — Internal ——————————————————————————————————————————

  Future<void> _loadTree(String sha, String name) async {
    final repo = _selectedRepo;
    if (repo == null) return;

    _isLoadingTree = true;
    _treeError = null;
    notifyListeners();

    try {
      final entries = await apiService.getTree(repo.owner, repo.name, sha);
      _treeStack.add(_TreeLevel(name: name, sha: sha, entries: entries));
    } catch (e) {
      _treeError = 'Failed to load tree: $e';
    } finally {
      _isLoadingTree = false;
      notifyListeners();
    }
  }
}

class _TreeLevel {
  _TreeLevel({required this.name, required this.sha, required this.entries});
  final String name;
  final String sha;
  final List<GitHubTreeEntry> entries;
}
