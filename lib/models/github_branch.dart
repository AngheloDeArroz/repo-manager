/// A branch reference returned by `GET /repos/:owner/:repo/branches`.
class GitHubBranch {
  const GitHubBranch({
    required this.name,
    required this.sha,
  });

  final String name;
  final String sha;

  factory GitHubBranch.fromJson(Map<String, dynamic> json) {
    return GitHubBranch(
      name: json['name'] as String,
      sha: (json['commit'] as Map<String, dynamic>)['sha'] as String,
    );
  }
}
