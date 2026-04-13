/// A GitHub repository summary returned by `GET /user/repos`.
class GitHubRepo {
  const GitHubRepo({
    required this.name,
    required this.fullName,
    required this.owner,
    required this.defaultBranch,
    required this.isPrivate,
    required this.starCount,
    required this.updatedAt,
    this.description,
    this.language,
  });

  final String name;
  final String fullName;
  final String owner;
  final String defaultBranch;
  final bool isPrivate;
  final int starCount;
  final DateTime updatedAt;
  final String? description;
  final String? language;

  factory GitHubRepo.fromJson(Map<String, dynamic> json) {
    return GitHubRepo(
      name: json['name'] as String,
      fullName: json['full_name'] as String,
      owner: (json['owner'] as Map<String, dynamic>)['login'] as String,
      defaultBranch: json['default_branch'] as String? ?? 'main',
      isPrivate: json['private'] as bool? ?? false,
      starCount: json['stargazers_count'] as int? ?? 0,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      description: json['description'] as String?,
      language: json['language'] as String?,
    );
  }
}
