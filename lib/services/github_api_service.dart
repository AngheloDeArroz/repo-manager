import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/github_branch.dart';
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
}
