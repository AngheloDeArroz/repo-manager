import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/github_branch.dart';
import '../models/github_commit.dart';
import '../models/github_repo.dart';
import '../models/github_tree_entry.dart';
import '../models/github_user.dart';
import 'secure_storage_service.dart';

/// Thin wrapper for authenticated GitHub REST API calls.
class GitHubApiService {
  GitHubApiService({required this.storageService});

  final SecureStorageService storageService;

  // — Helpers ————————————————————————————————————————————

  /// Builds common auth + accept headers.
  Future<Map<String, String>?> _authHeaders() async {
    final token = await storageService.getGitHubToken();
    if (token == null) return null;
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/vnd.github+json',
    };
  }

  /// Authenticated GET. Returns `null` on auth failure or non-200.
  Future<http.Response?> _authGet(String url) async {
    final headers = await _authHeaders();
    if (headers == null) return null;

    try {
      final res = await http.get(Uri.parse(url), headers: headers);
      if (res.statusCode != 200) return null;
      return res;
    } catch (_) {
      return null;
    }
  }

  // — User ———————————————————————————————————————————————

  /// Fetch the authenticated user's profile.
  Future<GitHubUser?> getUser() async {
    final res = await _authGet('${AppConfig.githubApiUrl}/user');
    if (res == null) return null;
    return GitHubUser.fromJson(jsonDecode(res.body));
  }

  // — Repos ——————————————————————————————————————————————

  /// Fetch the authenticated user's repositories, paginated.
  ///
  /// Returns an empty list on failure (never `null`).
  Future<List<GitHubRepo>> getRepos({int page = 1, int perPage = 30}) async {
    final res = await _authGet(
      '${AppConfig.githubApiUrl}/user/repos'
      '?sort=updated&per_page=$perPage&page=$page&affiliation=owner,collaborator',
    );
    if (res == null) return [];

    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((j) => GitHubRepo.fromJson(j as Map<String, dynamic>)).toList();
  }

  // — Branches ——————————————————————————————————————————

  /// List branches for a repository.
  Future<List<GitHubBranch>> getBranches(String owner, String repo) async {
    final res = await _authGet(
      '${AppConfig.githubApiUrl}/repos/$owner/$repo/branches?per_page=100',
    );
    if (res == null) return [];

    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((j) => GitHubBranch.fromJson(j as Map<String, dynamic>)).toList();
  }

  // — Tree ——————————————————————————————————————————————

  /// Fetch the Git tree at a given SHA (non-recursive — one level).
  Future<List<GitHubTreeEntry>> getTree(String owner, String repo, String sha) async {
    final res = await _authGet(
      '${AppConfig.githubApiUrl}/repos/$owner/$repo/git/trees/$sha',
    );
    if (res == null) return [];

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final tree = body['tree'] as List<dynamic>? ?? [];
    final entries = tree
        .map((j) => GitHubTreeEntry.fromJson(j as Map<String, dynamic>))
        .toList()
      ..sort();
    return entries;
  }

  // — File content ——————————————————————————————————————

  /// Fetch a single file's content (base64-decoded) from the Contents API.
  ///
  /// [path] is repo-relative, e.g. `lib/main.dart`.
  /// [ref] is an optional branch/tag/sha.
  Future<String?> getFileContent(
    String owner,
    String repo,
    String path, {
    String? ref,
  }) async {
    var url = '${AppConfig.githubApiUrl}/repos/$owner/$repo/contents/$path';
    if (ref != null && ref.isNotEmpty) url += '?ref=$ref';

    final res = await _authGet(url);
    if (res == null) return null;

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final content = body['content'] as String?;
    if (content == null) return null;

    // GitHub returns base64 with newlines — strip them before decoding.
    return utf8.decode(base64Decode(content.replaceAll('\n', '')));
  }

  // — Commits ———————————————————————————————————————————

  /// List commits for a repo on a given branch, paginated.
  Future<List<GitHubCommit>> getCommits(
    String owner,
    String repo, {
    String? sha,
    int page = 1,
    int perPage = 20,
  }) async {
    var url = '${AppConfig.githubApiUrl}/repos/$owner/$repo/commits'
        '?per_page=$perPage&page=$page';
    if (sha != null && sha.isNotEmpty) url += '&sha=$sha';

    final res = await _authGet(url);
    if (res == null) return [];

    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((j) => GitHubCommit.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a single commit with full diff and stats.
  Future<GitHubCommit?> getCommitDetail(
    String owner,
    String repo,
    String sha,
  ) async {
    final res = await _authGet(
      '${AppConfig.githubApiUrl}/repos/$owner/$repo/commits/$sha',
    );
    if (res == null) return null;
    return GitHubCommit.fromJson(jsonDecode(res.body));
  }

  // — Write helpers ——————————————————————————————————————

  /// Authenticated POST. Returns the response or `null` on auth failure.
  Future<http.Response?> _authPost(String url, Map<String, dynamic> body) async {
    final headers = await _authHeaders();
    if (headers == null) return null;

    try {
      return await http.post(
        Uri.parse(url),
        headers: {...headers, 'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
    } catch (_) {
      return null;
    }
  }

  // — Branch creation ———————————————————————————————————

  /// Create a new branch from an existing ref SHA.
  ///
  /// Returns `true` on success, `false` on failure.
  Future<bool> createBranch(
    String owner,
    String repo,
    String branchName,
    String fromSha,
  ) async {
    final res = await _authPost(
      '${AppConfig.githubApiUrl}/repos/$owner/$repo/git/refs',
      {'ref': 'refs/heads/$branchName', 'sha': fromSha},
    );
    return res != null && (res.statusCode == 201 || res.statusCode == 200);
  }

  // — File commit (single file via Contents API) ————————

  /// Create or update a single file on a branch.
  ///
  /// [sha] is the blob SHA of the existing file (required for updates,
  /// null for creates).
  Future<bool> createOrUpdateFile(
    String owner,
    String repo,
    String path, {
    required String content,
    required String message,
    required String branch,
    String? sha,
  }) async {
    final headers = await _authHeaders();
    if (headers == null) return false;

    final body = <String, dynamic>{
      'message': message,
      'content': base64Encode(utf8.encode(content)),
      'branch': branch,
    };
    if (sha != null) body['sha'] = sha;

    try {
      final res = await http.put(
        Uri.parse(
            '${AppConfig.githubApiUrl}/repos/$owner/$repo/contents/$path'),
        headers: {...headers, 'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  // — Multi-file commit (Git Data API) ——————————————————

  /// Push multiple file changes as a single commit on [branch].
  ///
  /// Uses the low-level Git Data API:
  /// 1. Create blobs for each file
  /// 2. Create a tree referencing those blobs
  /// 3. Create a commit pointing to the tree
  /// 4. Update the branch ref
  Future<bool> pushChanges(
    String owner,
    String repo, {
    required String branch,
    required String commitMessage,
    required Map<String, String> files, // path → content
    required String baseSha,
  }) async {
    try {
      // 1. Get base tree SHA
      final refRes = await _authGet(
        '${AppConfig.githubApiUrl}/repos/$owner/$repo/git/commits/$baseSha',
      );
      if (refRes == null) return false;
      final baseTreeSha =
          (jsonDecode(refRes.body) as Map<String, dynamic>)['tree']['sha'] as String;

      // 2. Create blobs
      final treeItems = <Map<String, dynamic>>[];
      for (final entry in files.entries) {
        final blobRes = await _authPost(
          '${AppConfig.githubApiUrl}/repos/$owner/$repo/git/blobs',
          {'content': entry.value, 'encoding': 'utf-8'},
        );
        if (blobRes == null || blobRes.statusCode != 201) return false;
        final blobSha = (jsonDecode(blobRes.body))['sha'] as String;
        treeItems.add({
          'path': entry.key,
          'mode': '100644',
          'type': 'blob',
          'sha': blobSha,
        });
      }

      // 3. Create tree
      final treeRes = await _authPost(
        '${AppConfig.githubApiUrl}/repos/$owner/$repo/git/trees',
        {'base_tree': baseTreeSha, 'tree': treeItems},
      );
      if (treeRes == null || treeRes.statusCode != 201) return false;
      final newTreeSha = (jsonDecode(treeRes.body))['sha'] as String;

      // 4. Create commit
      final commitRes = await _authPost(
        '${AppConfig.githubApiUrl}/repos/$owner/$repo/git/commits',
        {
          'message': commitMessage,
          'tree': newTreeSha,
          'parents': [baseSha],
        },
      );
      if (commitRes == null || commitRes.statusCode != 201) return false;
      final newCommitSha = (jsonDecode(commitRes.body))['sha'] as String;

      // 5. Update branch ref
      final headers = await _authHeaders();
      if (headers == null) return false;
      final updateRes = await http.patch(
        Uri.parse(
            '${AppConfig.githubApiUrl}/repos/$owner/$repo/git/refs/heads/$branch'),
        headers: {...headers, 'Content-Type': 'application/json'},
        body: jsonEncode({'sha': newCommitSha}),
      );
      return updateRes.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
