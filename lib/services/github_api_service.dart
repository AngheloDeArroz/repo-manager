import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/github_user.dart';
import 'secure_storage_service.dart';

/// Thin wrapper for authenticated GitHub REST API calls.
class GitHubApiService {
  GitHubApiService({required this.storageService});

  final SecureStorageService storageService;

  /// Fetch the authenticated user's profile.
  Future<GitHubUser?> getUser() async {
    final token = await storageService.getGitHubToken();
    if (token == null) return null;

    try {
      final res = await http.get(
        Uri.parse('${AppConfig.githubApiUrl}/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.github+json',
        },
      );

      if (res.statusCode != 200) return null;
      return GitHubUser.fromJson(jsonDecode(res.body));
    } catch (_) {
      return null;
    }
  }
}
